#' Random selection policy
#'
#' Selects an arm uniformly at random at every step. Useful as a floor
#' baseline and for generating uniformly randomised logs.
#'
#' @return A `bandit_policy` object.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' result <- run_experiment(env, policy_random(), horizon = 100, seed = 1)
#' summary(result)
#'
#' @seealso [run_experiment()], [policy_interface]
#' @export
policy_random <- function() {
  structure(list(), class = c("random_policy", "bandit_policy"))
}

#' @export
policy_state.random_policy <- function(policy, arms, ...) {
  policy$arms <- check_arm_names(arms)
  policy
}

#' @export
select_arm.random_policy <- function(policy, t, ...) {
  k <- length(policy$arms)
  list(
    arm = policy$arms[[sample.int(k, 1L)]],
    propensity = 1 / k,
    reason = "uniform"
  )
}

#' @export
update_state.random_policy <- function(policy, arm, reward, t, ...) {
  policy
}

#' Greedy policy with optional optimistic initial values
#'
#' Always selects the arm with the highest estimated mean reward, with
#' uniform random tie-breaking. Estimates are sample averages.
#'
#' By default (`initial_value = NULL`) each arm is tried once, in random
#' order, before greedy selection begins. Supplying a numeric
#' `initial_value` disables that forced initialisation: untried arms are
#' treated as having that estimated value, which implements optimistic
#' initial values when the value is set above the plausible reward range.
#' With sample-average estimates the optimism washes out after each arm's
#' first pull; its effect is to force early exploration.
#'
#' @param initial_value `NULL` (default) or a single finite number used
#'   as the value estimate of untried arms.
#'
#' @return A `bandit_policy` object.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' run_experiment(env, policy_greedy(), horizon = 200, seed = 1)
#'
#' # Optimistic initialisation: untried arms look better than any
#' # possible Bernoulli reward until sampled.
#' run_experiment(env, policy_greedy(initial_value = 1), horizon = 200, seed = 1)
#'
#' @seealso [policy_epsilon_greedy()], [run_experiment()]
#' @export
policy_greedy <- function(initial_value = NULL) {
  if (!is.null(initial_value)) {
    check_scalar_number(initial_value, "initial_value")
  }
  structure(
    list(initial_value = initial_value),
    class = c("greedy_policy", "bandit_policy")
  )
}

#' Epsilon-greedy policy
#'
#' With probability `epsilon` selects an arm uniformly at random,
#' otherwise selects the arm with the highest sample-average estimate
#' (uniform tie-breaking). The logged propensity is always the marginal
#' selection probability of the chosen arm, combining both routes to
#' selection, which makes the resulting logs usable for
#' importance-weighted offline evaluation.
#'
#' @param epsilon Exploration probability in `[0, 1]`. Ignored at steps
#'   where `schedule` is supplied.
#' @param initial_value As in [policy_greedy()]: `NULL` forces one trial
#'   of each arm first; a number is used as the estimate of untried arms.
#' @param schedule Optional function of the time step `t` returning the
#'   exploration probability at that step, for decaying schedules.
#'
#' @return A `bandit_policy` object.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' run_experiment(env, policy_epsilon_greedy(0.1), horizon = 200, seed = 1)
#'
#' # A decaying schedule.
#' pol <- policy_epsilon_greedy(schedule = function(t) min(1, 5 / t))
#' run_experiment(env, pol, horizon = 200, seed = 1)
#'
#' @seealso [policy_greedy()], [policy_ucb1()], [policy_thompson()]
#' @export
policy_epsilon_greedy <- function(epsilon = 0.1, initial_value = NULL,
                                  schedule = NULL) {
  check_scalar_number(epsilon, "epsilon", min = 0, max = 1)
  if (!is.null(initial_value)) {
    check_scalar_number(initial_value, "initial_value")
  }
  if (!is.null(schedule) && !is.function(schedule)) {
    abort_bad("`schedule` must be NULL or a function of the time step.")
  }
  structure(
    list(
      epsilon = epsilon,
      initial_value = initial_value,
      schedule = schedule
    ),
    class = c("epsilon_greedy_policy", "bandit_policy")
  )
}

# Shared machinery for greedy and epsilon-greedy -----------------------------

value_policy_state <- function(policy, arms) {
  policy$arms <- check_arm_names(arms)
  policy$pulls <- setNames(rep(0L, length(arms)), arms)
  policy$reward_sum <- setNames(rep(0, length(arms)), arms)
  policy
}

#' @export
policy_state.greedy_policy <- function(policy, arms, ...) {
  value_policy_state(policy, arms)
}

#' @export
policy_state.epsilon_greedy_policy <- function(policy, arms, ...) {
  value_policy_state(policy, arms)
}

value_estimates <- function(policy) {
  estimates <- policy$reward_sum / policy$pulls
  if (!is.null(policy$initial_value)) {
    estimates[policy$pulls == 0L] <- policy$initial_value
  }
  estimates
}

# Selection shared by greedy (epsilon = 0) and epsilon-greedy.
# The returned propensity is the marginal probability of the selected
# arm: epsilon / k from the exploration route plus, for arms tied at the
# maximum estimate, (1 - epsilon) / |argmax| from the greedy route.
select_value_greedy <- function(policy, epsilon) {
  arms <- policy$arms
  k <- length(arms)

  if (is.null(policy$initial_value)) {
    untried <- arms[policy$pulls == 0L]
    if (length(untried) > 0) {
      arm <- untried[[sample.int(length(untried), 1L)]]
      return(list(
        arm = arm,
        propensity = 1 / length(untried),
        reason = "initialisation"
      ))
    }
  }

  estimates <- value_estimates(policy)
  best <- argmax_set(estimates)

  marginal <- function(index) {
    greedy_share <- if (index %in% best) (1 - epsilon) / length(best) else 0
    greedy_share + epsilon / k
  }

  if (epsilon > 0 && runif(1) < epsilon) {
    index <- sample.int(k, 1L)
    return(list(
      arm = arms[[index]],
      propensity = marginal(index),
      reason = "exploration"
    ))
  }

  index <- best[[if (length(best) == 1L) 1L else sample.int(length(best), 1L)]]
  list(
    arm = arms[[index]],
    propensity = marginal(index),
    reason = "exploitation"
  )
}

#' @export
select_arm.greedy_policy <- function(policy, t, ...) {
  select_value_greedy(policy, epsilon = 0)
}

#' @export
select_arm.epsilon_greedy_policy <- function(policy, t, ...) {
  epsilon <- policy$epsilon
  if (!is.null(policy$schedule)) {
    epsilon <- policy$schedule(t)
    if (!is.numeric(epsilon) || length(epsilon) != 1 ||
        !is.finite(epsilon) || epsilon < 0 || epsilon > 1) {
      abort_bad("`schedule(t)` must return a single probability in [0, 1].")
    }
  }
  select_value_greedy(policy, epsilon = epsilon)
}

update_value_policy <- function(policy, arm, reward) {
  if (!arm %in% policy$arms) {
    abort_bad("unknown arm: %s", arm)
  }
  if (!is.numeric(reward) || length(reward) != 1 || !is.finite(reward)) {
    abort_bad("reward must be one finite numeric value.")
  }
  policy$pulls[[arm]] <- policy$pulls[[arm]] + 1L
  policy$reward_sum[[arm]] <- policy$reward_sum[[arm]] + reward
  policy
}

#' @export
update_state.greedy_policy <- function(policy, arm, reward, t, ...) {
  update_value_policy(policy, arm, reward)
}

#' @export
update_state.epsilon_greedy_policy <- function(policy, arm, reward, t, ...) {
  update_value_policy(policy, arm, reward)
}
