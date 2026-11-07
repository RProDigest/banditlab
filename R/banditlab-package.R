#' banditlab: Multi-Armed Bandit Experimentation and Policy Comparison
#'
#' A framework for simulating, comparing and extending multi-armed bandit
#' algorithms. The package separates three concerns:
#'
#' - **Environments** generate rewards: [bandit_bernoulli()],
#'   [bandit_gaussian()], [bandit_custom()].
#' - **Policies** select arms and learn from rewards: [policy_random()],
#'   [policy_greedy()], [policy_epsilon_greedy()], [policy_etc()],
#'   [policy_ucb1()], [policy_thompson()].
#' - **Experiments** connect the two: [run_experiment()] runs replicated
#'   simulations with reproducible per-replicate random number streams and
#'   returns tidy results for analysis with [summary()], [as_tibble()],
#'   [compare_policies()] and [ggplot2::autoplot()].
#'
#' Custom policies plug into the same engine through three documented S3
#' generics: [policy_state()], [select_arm()] and [update_state()]. See
#' `vignette("custom-policies", package = "banditlab")`.
#'
#' Regret metrics follow exact definitions documented in
#' [regret_definitions].
#'
#' @keywords internal
"_PACKAGE"

#' @importFrom stats setNames rbinom rnorm rbeta runif quantile median
#' @importFrom tibble tibble as_tibble
#' @importFrom ggplot2 autoplot
NULL

# Column names used unquoted in ggplot2 aesthetics.
utils::globalVariables(c(
  "step", "mid", "lower", "upper", "policy", "arm", "share"
))

#' Re-exported generics
#'
#' `as_tibble()` is re-exported from the tibble package and `autoplot()` from
#' ggplot2 so that `banditlab` results can be converted and plotted without
#' attaching those packages explicitly.
#'
#' @name reexports
#' @keywords internal
#' @aliases as_tibble autoplot
#' @export as_tibble
#' @export autoplot
NULL
