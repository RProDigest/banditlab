#' Regret definitions used by banditlab
#'
#' @description
#' The package uses these exact definitions. Let \eqn{\mu_a} be the true
#' expected reward of arm \eqn{a}, \eqn{\mu^* = \max_a \mu_a}, and
#' \eqn{A_t} the arm selected at step \eqn{t}.
#'
#' - **Instantaneous pseudo-regret** at step t:
#'   \eqn{\Delta_{A_t} = \mu^* - \mu_{A_t}}. Recorded per decision in
#'   trajectories.
#' - **Cumulative pseudo-regret** after T steps:
#'   \eqn{R_T = \sum_{t=1}^{T} (\mu^* - \mu_{A_t})}. Recorded at
#'   checkpoints and, at the final step, in the summary.
#' - **Expected regret**: the Monte Carlo mean of final cumulative
#'   pseudo-regret across replicates, reported by
#'   [summary.bandit_result()].
#' - **Optimal action share**: the fraction of steps at which a selected
#'   arm attains \eqn{\mu^*}.
#' - **Realised regret** (comparing observed rewards against
#'   counterfactual draws from the optimal arm) is **not** computed in
#'   this version.
#'
#' All quantities require known expected rewards. Environments that do
#' not declare them (a [bandit_custom()] without `expected_rewards`)
#' yield `NA` for every regret metric; no baseline is invented.
#'
#' @name regret_definitions
NULL

#' @export
print.bandit_result <- function(x, ...) {
  m <- x$meta
  cat(sprintf(
    "<bandit_result> %d %s x %d replicate%s x horizon %d (seed %d)\n",
    length(m$policy_names),
    if (length(m$policy_names) == 1) "policy" else "policies",
    m$replications,
    if (m$replications == 1) "" else "s",
    m$horizon,
    m$seed
  ))
  cat(sprintf(
    "environment: %s (%d arms)%s\n",
    m$environment_class, length(m$arms),
    if (is.null(m$expected_rewards)) ", expected rewards unknown" else ""
  ))
  cat(sprintf(
    "stored: summary%s%s\n",
    if (is.null(x$checkpoints)) "" else " + checkpoints",
    if (is.null(x$trajectories)) "" else " + trajectories"
  ))
  print(summary(x))
  invisible(x)
}

#' Summarise a bandit experiment
#'
#' Aggregates the per-replicate summaries into one row per policy. The
#' intervals are Monte Carlo quantiles across replicates (simulation
#' intervals), not confidence intervals for a deployment effect.
#'
#' @param object A `bandit_result` from [run_experiment()].
#' @param ... Unused.
#'
#' @return A tibble with one row per policy: mean, median, 2.5% and
#'   97.5% quantiles of final cumulative pseudo-regret (`NA` when the
#'   environment's expected rewards are unknown), mean total reward and
#'   mean optimal-action share. See [regret_definitions].
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' result <- run_experiment(env, policy_ucb1(), horizon = 200,
#'                          replications = 10, seed = 1)
#' summary(result)
#'
#' @export
summary.bandit_result <- function(object, ...) {
  s <- object$summary
  per_policy <- lapply(
    split(s, factor(s$policy, levels = object$meta$policy_names)),
    function(d) {
      regret <- d$cumulative_regret
      has_regret <- !anyNA(regret)
      tibble(
        policy = d$policy[[1]],
        replications = nrow(d),
        mean_regret = if (has_regret) mean(regret) else NA_real_,
        median_regret = if (has_regret) median(regret) else NA_real_,
        regret_q025 = if (has_regret) {
          unname(quantile(regret, 0.025))
        } else {
          NA_real_
        },
        regret_q975 = if (has_regret) {
          unname(quantile(regret, 0.975))
        } else {
          NA_real_
        },
        mean_reward = mean(d$total_reward),
        mean_optimal_share = mean(d$optimal_action_share)
      )
    }
  )
  do.call(rbind, per_policy)
}

#' Convert experiment results to a tibble
#'
#' @param x A `bandit_result` from [run_experiment()].
#' @param what Which component to return: the per-replicate `"summary"`
#'   (default), the `"checkpoints"` table, or the full `"trajectories"`.
#' @param ... Unused.
#'
#' @return A tibble.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' result <- run_experiment(env, policy_random(), horizon = 50,
#'                          replications = 3, seed = 1)
#' as_tibble(result)
#'
#' @exportS3Method tibble::as_tibble
as_tibble.bandit_result <- function(x, what = c("summary", "checkpoints",
                                                "trajectories"), ...) {
  what <- match.arg(what)
  out <- x[[what]]
  if (is.null(out)) {
    hint <- switch(
      what,
      checkpoints = "rerun run_experiment() with `checkpoints = `.",
      trajectories = "rerun run_experiment() with `keep_trajectories = TRUE`.",
      "no summary present."
    )
    abort_bad("this result holds no %s; %s", what, hint)
  }
  out
}

#' Seed-paired policy comparison
#'
#' Because every policy runs replicate `r` from the same random number
#' stream (see [run_experiment()]), per-replicate differences between
#' policies are paired. Pairing removes between-replicate noise from the
#' comparison, exactly as paired seeds do in a designed simulation study.
#'
#' @param result A `bandit_result` with at least two policies and at
#'   least two replications.
#' @param metric `"cumulative_regret"` (default) or `"total_reward"`.
#' @param baseline Name of the baseline policy. Default: the first
#'   policy in the experiment.
#'
#' @return A tibble with one row per non-baseline policy and replicate:
#'   `policy`, `baseline`, `replicate`, the metric under each, and
#'   `difference` (policy minus baseline). For `cumulative_regret`,
#'   negative differences favour the policy; for `total_reward`,
#'   positive differences favour the policy.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' result <- run_experiment(
#'   env,
#'   list(epsilon = policy_epsilon_greedy(0.1), ucb = policy_ucb1()),
#'   horizon = 300, replications = 20, seed = 7
#' )
#' comparison <- compare_policies(result, baseline = "epsilon")
#' aggregate(difference ~ policy, data = comparison, FUN = mean)
#'
#' @export
compare_policies <- function(result,
                             metric = c("cumulative_regret", "total_reward"),
                             baseline = NULL) {
  if (!inherits(result, "bandit_result")) {
    abort_bad("`result` must be a bandit_result from run_experiment().")
  }
  metric <- match.arg(metric)
  names_all <- result$meta$policy_names
  if (length(names_all) < 2) {
    abort_bad("compare_policies() needs at least two policies.")
  }
  if (result$meta$replications < 2) {
    abort_bad("compare_policies() needs replications >= 2.")
  }
  if (is.null(baseline)) {
    baseline <- names_all[[1]]
  }
  if (!baseline %in% names_all) {
    abort_bad("baseline '%s' is not a policy in this result.", baseline)
  }
  s <- result$summary
  if (metric == "cumulative_regret" && anyNA(s$cumulative_regret)) {
    abort_bad(
      "cumulative regret is unavailable for this environment; %s",
      "compare on metric = \"total_reward\" instead."
    )
  }

  base_rows <- s[s$policy == baseline, ]
  base_values <- base_rows[[metric]][order(base_rows$replicate)]

  others <- setdiff(names_all, baseline)
  pieces <- lapply(others, function(p) {
    rows <- s[s$policy == p, ]
    values <- rows[[metric]][order(rows$replicate)]
    tibble(
      policy = p,
      baseline = baseline,
      replicate = sort(rows$replicate),
      policy_value = values,
      baseline_value = base_values,
      difference = values - base_values
    )
  })
  out <- do.call(rbind, pieces)
  attr(out, "metric") <- metric
  out
}
