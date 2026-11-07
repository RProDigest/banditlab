#' Create a Bernoulli bandit environment
#'
#' Each arm returns 1 with its own fixed probability and 0 otherwise.
#' Expected rewards are known, so all regret metrics are available.
#'
#' @param probabilities Numeric vector of success probabilities in
#'   `[0, 1]`, one per arm. Names, if present, are used as arm names;
#'   otherwise arms are named `arm_1`, `arm_2`, ...
#'
#' @return A `bandit_environment` object.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' env
#' sample_reward(env, "b")
#'
#' @seealso [bandit_gaussian()], [bandit_custom()], [run_experiment()]
#' @export
bandit_bernoulli <- function(probabilities) {
  if (!is.numeric(probabilities) || length(probabilities) < 2) {
    abort_bad("`probabilities` must be a numeric vector with at least two arms.")
  }
  if (any(!is.finite(probabilities)) ||
      any(probabilities < 0 | probabilities > 1)) {
    abort_bad("`probabilities` must be finite values between zero and one.")
  }
  arms <- names(probabilities)
  if (is.null(arms)) {
    arms <- default_arm_names(length(probabilities))
  }
  check_arm_names(arms)
  probabilities <- setNames(as.numeric(probabilities), arms)

  new_bandit_environment(
    class = "bernoulli_environment",
    arms = arms,
    expected_rewards = probabilities,
    probabilities = probabilities
  )
}

#' Create a Gaussian bandit environment
#'
#' Each arm returns a draw from its own normal distribution. Expected
#' rewards are known, so all regret metrics are available.
#'
#' @param means Numeric vector of arm means. Names, if present, are used
#'   as arm names; otherwise arms are named `arm_1`, `arm_2`, ...
#' @param sds Standard deviations, recycled to the number of arms.
#'   Must be positive. Default 1.
#'
#' @return A `bandit_environment` object.
#'
#' @examples
#' env <- bandit_gaussian(means = c(0.0, 0.5), sds = c(1, 2))
#' env
#'
#' @seealso [bandit_bernoulli()], [bandit_custom()], [run_experiment()]
#' @export
bandit_gaussian <- function(means, sds = 1) {
  if (!is.numeric(means) || length(means) < 2 || any(!is.finite(means))) {
    abort_bad("`means` must be a finite numeric vector with at least two arms.")
  }
  if (!is.numeric(sds) || any(!is.finite(sds)) || any(sds <= 0)) {
    abort_bad("`sds` must be positive finite numbers.")
  }
  if (length(means) %% length(sds) != 0) {
    abort_bad("length of `means` must be a multiple of length of `sds`.")
  }
  sds <- rep(sds, length.out = length(means))
  arms <- names(means)
  if (is.null(arms)) {
    arms <- default_arm_names(length(means))
  }
  check_arm_names(arms)
  means <- setNames(as.numeric(means), arms)
  sds <- setNames(as.numeric(sds), arms)

  new_bandit_environment(
    class = "gaussian_environment",
    arms = arms,
    expected_rewards = means,
    means = means,
    sds = sds
  )
}

#' Create a custom bandit environment
#'
#' Wraps a user-supplied reward sampler so that any stochastic reward
#' process can run in [run_experiment()] without modifying the package.
#'
#' @param sampler A function of one argument, the arm name, returning a
#'   single finite numeric reward.
#' @param arms Character vector of at least two unique arm names.
#' @param expected_rewards Optional named numeric vector of true expected
#'   rewards, one per arm. When supplied, regret metrics are computed;
#'   when `NULL` (the default), regret columns are `NA` because the
#'   oracle value is unknown.
#'
#' @return A `bandit_environment` object.
#'
#' @details
#' The sampler is called once per decision with the selected arm name and
#' the current R random number generator state; use the current RNG
#' (e.g. `stats::rexp()`) rather than setting seeds inside the sampler,
#' otherwise reproducibility guarantees of [run_experiment()] are lost.
#'
#' @examples
#' env <- bandit_custom(
#'   sampler = function(arm) rexp(1, rate = if (arm == "fast") 2 else 1),
#'   arms = c("fast", "slow"),
#'   expected_rewards = c(fast = 0.5, slow = 1)
#' )
#' env
#'
#' @seealso [run_experiment()], [sample_reward()]
#' @export
bandit_custom <- function(sampler, arms, expected_rewards = NULL) {
  if (!is.function(sampler)) {
    abort_bad("`sampler` must be a function of one argument (the arm name).")
  }
  check_arm_names(arms)
  if (!is.null(expected_rewards)) {
    if (!is.numeric(expected_rewards) ||
        length(expected_rewards) != length(arms) ||
        any(!is.finite(expected_rewards))) {
      abort_bad("`expected_rewards` must be one finite number per arm.")
    }
    if (is.null(names(expected_rewards))) {
      names(expected_rewards) <- arms
    }
    if (!setequal(names(expected_rewards), arms)) {
      abort_bad("names of `expected_rewards` must match `arms`.")
    }
    expected_rewards <- expected_rewards[arms]
  }

  new_bandit_environment(
    class = "custom_environment",
    arms = arms,
    expected_rewards = expected_rewards,
    sampler = sampler
  )
}

# Shared constructor.
new_bandit_environment <- function(class, arms, expected_rewards, ...) {
  structure(
    list(
      arms = arms,
      n_arms = length(arms),
      expected_rewards = expected_rewards,
      ...
    ),
    class = c(class, "bandit_environment")
  )
}

#' Draw one reward from an environment
#'
#' The generic used by the experiment engine to generate rewards. It is
#' exported so that authors of new environment classes can provide
#' methods; most users never call it directly.
#'
#' @param environment A `bandit_environment` object.
#' @param arm One arm name belonging to the environment.
#' @param ... Reserved for future methods.
#'
#' @return A single finite numeric reward.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0, b = 1))
#' sample_reward(env, "b")
#'
#' @export
sample_reward <- function(environment, arm, ...) {
  UseMethod("sample_reward")
}

#' @export
sample_reward.bernoulli_environment <- function(environment, arm, ...) {
  rbinom(1, 1, environment$probabilities[[arm]])
}

#' @export
sample_reward.gaussian_environment <- function(environment, arm, ...) {
  rnorm(1, mean = environment$means[[arm]], sd = environment$sds[[arm]])
}

#' @export
sample_reward.custom_environment <- function(environment, arm, ...) {
  reward <- environment$sampler(arm)
  if (!is.numeric(reward) || length(reward) != 1 || !is.finite(reward)) {
    abort_bad("custom sampler must return one finite numeric reward.")
  }
  as.numeric(reward)
}

#' @export
print.bandit_environment <- function(x, ...) {
  cat(sprintf(
    "<%s> %d arms: %s\n",
    class(x)[1], x$n_arms, paste(x$arms, collapse = ", ")
  ))
  if (!is.null(x$expected_rewards)) {
    best <- names(x$expected_rewards)[argmax_set(x$expected_rewards)]
    cat("expected rewards:\n")
    print(round(x$expected_rewards, 4))
    cat(sprintf("optimal arm(s): %s\n", paste(best, collapse = ", ")))
  } else {
    cat("expected rewards: unknown (regret metrics unavailable)\n")
  }
  invisible(x)
}
