#' Explore-then-commit policy
#'
#' Plays every arm `explore_steps` times in round-robin order, then
#' commits permanently to the arm with the highest sample-average reward
#' (uniform tie-breaking at the moment of commitment).
#'
#' If the horizon ends before exploration completes, the policy never
#' commits; this is visible in the `reason` column of trajectories.
#'
#' @param explore_steps Number of exploration pulls per arm, a positive
#'   whole number.
#'
#' @return A `bandit_policy` object.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' run_experiment(env, policy_etc(explore_steps = 20), horizon = 500, seed = 1)
#'
#' @seealso [policy_greedy()], [run_experiment()]
#' @export
policy_etc <- function(explore_steps) {
  explore_steps <- check_count(explore_steps, "explore_steps", min = 1)
  structure(
    list(explore_steps = explore_steps),
    class = c("etc_policy", "bandit_policy")
  )
}

#' @export
policy_state.etc_policy <- function(policy, arms, ...) {
  policy <- value_policy_state(policy, arms)
  policy$committed <- NA_character_
  policy
}

#' @export
select_arm.etc_policy <- function(policy, t, ...) {
  k <- length(policy$arms)
  exploration_end <- policy$explore_steps * k

  if (t <= exploration_end) {
    index <- ((t - 1L) %% k) + 1L
    return(list(
      arm = policy$arms[[index]],
      propensity = 1,
      reason = "explore"
    ))
  }

  list(
    arm = policy$committed,
    propensity = 1,
    reason = "commit"
  )
}

#' @export
update_state.etc_policy <- function(policy, arm, reward, t, ...) {
  policy <- update_value_policy(policy, arm, reward)
  if (t == policy$explore_steps * length(policy$arms)) {
    means <- policy$reward_sum / policy$pulls
    policy$committed <- policy$arms[[argmax_random(means)]]
  }
  policy
}

#' UCB1 policy
#'
#' The upper confidence bound policy of Auer, Cesa-Bianchi and Fischer
#' (2002). After one initial pull of each arm, it selects the arm
#' maximising
#' \deqn{\hat{\mu}_a + \sqrt{2 \log t / n_a},}
#' where \eqn{\hat{\mu}_a} is the sample-average reward of arm \eqn{a},
#' \eqn{n_a} its pull count and \eqn{t} the current step. Ties are broken
#' uniformly at random.
#'
#' The classical regret analysis assumes rewards bounded in `[0, 1]` and
#' a stationary environment; the implementation accepts any numeric
#' rewards but the theoretical guarantee does not transfer automatically.
#'
#' @return A `bandit_policy` object.
#'
#' @references
#' Auer, P., Cesa-Bianchi, N., Fischer, P. (2002). Finite-time analysis
#' of the multiarmed bandit problem. Machine Learning 47(2-3), 235-256.
#' \doi{10.1023/A:1013689704352}
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' run_experiment(env, policy_ucb1(), horizon = 500, seed = 1)
#'
#' @seealso [policy_thompson()], [policy_epsilon_greedy()]
#' @export
policy_ucb1 <- function() {
  structure(list(), class = c("ucb1_policy", "bandit_policy"))
}

#' @export
policy_state.ucb1_policy <- function(policy, arms, ...) {
  value_policy_state(policy, arms)
}

#' @export
select_arm.ucb1_policy <- function(policy, t, ...) {
  arms <- policy$arms

  untried <- arms[policy$pulls == 0L]
  if (length(untried) > 0) {
    arm <- untried[[sample.int(length(untried), 1L)]]
    return(list(
      arm = arm,
      propensity = 1 / length(untried),
      reason = "initialisation"
    ))
  }

  means <- policy$reward_sum / policy$pulls
  bonus <- sqrt(2 * log(t) / policy$pulls)
  index_values <- means + bonus
  best <- argmax_set(index_values)
  index <- best[[if (length(best) == 1L) 1L else sample.int(length(best), 1L)]]

  list(
    arm = arms[[index]],
    propensity = 1 / length(best),
    reason = "ucb"
  )
}

#' @export
update_state.ucb1_policy <- function(policy, arm, reward, t, ...) {
  update_value_policy(policy, arm, reward)
}

#' Beta-Bernoulli Thompson sampling policy
#'
#' Maintains an independent Beta posterior for each arm's success
#' probability, draws one sample from every posterior at each step and
#' selects the arm with the largest draw. Rewards must be 0 or 1; the
#' update adds the reward to the arm's `alpha` and `1 - reward` to its
#' `beta`.
#'
#' The logged propensity is `NA`: the marginal selection probability of
#' Thompson sampling is the posterior probability that the arm's draw is
#' the maximum, which has no simple closed form. Logging `NA` is honest;
#' estimating it by simulation is possible but consumes additional random
#' numbers and is not done here.
#'
#' @param alpha,beta Positive prior shape parameters, recycled across
#'   arms. The default `Beta(1, 1)` prior is uniform.
#'
#' @return A `bandit_policy` object.
#'
#' @references
#' Thompson, W. R. (1933). On the likelihood that one unknown probability
#' exceeds another in view of the evidence of two samples. Biometrika
#' 25(3-4), 285-294. \doi{10.2307/2332286}
#'
#' Russo, D. J., Van Roy, B., Kazerouni, A., Osband, I., Wen, Z. (2018).
#' A tutorial on Thompson sampling. Foundations and Trends in Machine
#' Learning 11(1), 1-96. \doi{10.1561/2200000070}
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' run_experiment(env, policy_thompson(), horizon = 500, seed = 1)
#'
#' @seealso [policy_ucb1()], [run_experiment()]
#' @export
policy_thompson <- function(alpha = 1, beta = 1) {
  if (!is.numeric(alpha) || any(!is.finite(alpha)) || any(alpha <= 0) ||
      !is.numeric(beta) || any(!is.finite(beta)) || any(beta <= 0)) {
    abort_bad("`alpha` and `beta` must be positive finite numbers.")
  }
  structure(
    list(prior_alpha = alpha, prior_beta = beta),
    class = c("thompson_policy", "bandit_policy")
  )
}

#' @export
policy_state.thompson_policy <- function(policy, arms, ...) {
  policy$arms <- check_arm_names(arms)
  k <- length(arms)
  if (length(policy$prior_alpha) != 1 && length(policy$prior_alpha) != k) {
    abort_bad("`alpha` must have length one or one value per arm.")
  }
  if (length(policy$prior_beta) != 1 && length(policy$prior_beta) != k) {
    abort_bad("`beta` must have length one or one value per arm.")
  }
  policy$alpha <- setNames(rep(policy$prior_alpha, length.out = k), arms)
  policy$beta <- setNames(rep(policy$prior_beta, length.out = k), arms)
  policy$pulls <- setNames(rep(0L, k), arms)
  policy
}

#' @export
select_arm.thompson_policy <- function(policy, t, ...) {
  draws <- rbeta(length(policy$arms), policy$alpha, policy$beta)
  index <- which.max(draws)
  list(
    arm = policy$arms[[index]],
    propensity = NA_real_,
    reason = "posterior_draw"
  )
}

#' @export
update_state.thompson_policy <- function(policy, arm, reward, t, ...) {
  if (!arm %in% policy$arms) {
    abort_bad("unknown arm: %s", arm)
  }
  if (!is.numeric(reward) || length(reward) != 1 || !(reward %in% c(0, 1))) {
    abort_bad(
      "policy_thompson() assumes Bernoulli rewards; received %s. %s",
      format(reward),
      "Use rewards coded 0/1 or choose another policy."
    )
  }
  policy$alpha[[arm]] <- policy$alpha[[arm]] + reward
  policy$beta[[arm]] <- policy$beta[[arm]] + 1 - reward
  policy$pulls[[arm]] <- policy$pulls[[arm]] + 1L
  policy
}
