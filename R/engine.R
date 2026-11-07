#' Run a replicated bandit experiment
#'
#' Runs one or more policies against an environment for a fixed horizon,
#' optionally replicated, and returns tidy results. This is the single
#' entry point to the simulation engine; every policy, built-in or
#' user-defined via the [policy_interface], runs through it.
#'
#' @param environment A `bandit_environment` created by
#'   [bandit_bernoulli()], [bandit_gaussian()], [bandit_custom()], or a
#'   user-defined environment class with a [sample_reward()] method.
#' @param policies A single `bandit_policy` or a named list of them. The
#'   names label the results; a single unnamed policy is labelled with
#'   its class name.
#' @param horizon Number of decisions per replicate.
#' @param replications Number of independent replicates per policy.
#' @param seed Single integer controlling all randomness, or `NULL`.
#'   See Details.
#' @param checkpoints Optional increasing vector of steps at which
#'   cumulative metrics are recorded per replicate. Enables trajectory
#'   plots without retaining full logs.
#' @param keep_trajectories If `TRUE`, retain the full event log of every
#'   replicate (one row per decision). Default `FALSE`: for large
#'   experiments the logs dominate memory, so retention is opt-in.
#'
#' @details
#' ## Randomness and reproducibility
#'
#' When `seed` is supplied, the engine derives one independent
#' L'Ecuyer-CMRG stream per replicate using
#' [parallel::nextRNGStream()]. Replicate `r` always runs on stream `r`,
#' so its results do not depend on how many other replicates run, and
#' every policy faces replicate `r` from the same stream start, making
#' comparisons seed-paired by construction. The caller's RNG state,
#' including the RNG kind, is restored on exit.
#'
#' When `seed` is `NULL`, a seed is drawn from the current RNG (advancing
#' it, so repeated calls differ) and then used the same way; the drawn
#' seed is stored in the result's `$meta$seed`, so any run can be
#' reproduced after the fact.
#'
#' Within a replicate, environment and policy randomness share the
#' replicate's stream. Two policies that consume different amounts of
#' randomness therefore see different reward realisations at later
#' steps; comparisons remain fair because both face the same
#' distribution, and paired because both start from the same stream.
#'
#' ## Regret
#'
#' If the environment's expected rewards are known, each step records the
#' instantaneous pseudo-regret `max(mu) - mu[arm]`; see
#' [regret_definitions] for exact definitions. If they are unknown
#' (a [bandit_custom()] without `expected_rewards`), regret and
#' optimal-action columns are `NA`.
#'
#' @return A `bandit_result` object: a list with elements
#' \describe{
#'   \item{summary}{tibble, one row per policy and replicate: `policy`,
#'     `replicate`, `total_reward`, `cumulative_regret`,
#'     `optimal_action_share`.}
#'   \item{checkpoints}{tibble of cumulative metrics at the requested
#'     steps, or `NULL`.}
#'   \item{trajectories}{tibble with one row per decision (`policy`,
#'     `replicate`, `step`, `arm`, `reward`, `propensity`, `reason`,
#'     `expected_reward`, `instantaneous_regret`), or `NULL`.}
#'   \item{meta}{list of experiment metadata, including the seed used.}
#' }
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' result <- run_experiment(
#'   env,
#'   policies = list(
#'     epsilon = policy_epsilon_greedy(0.1),
#'     thompson = policy_thompson()
#'   ),
#'   horizon = 300,
#'   replications = 20,
#'   seed = 42,
#'   checkpoints = c(50, 100, 200, 300)
#' )
#' result
#' summary(result)
#'
#' @seealso [summary.bandit_result()], [compare_policies()],
#'   [autoplot.bandit_result()], [policy_interface]
#' @export
run_experiment <- function(environment, policies, horizon,
                           replications = 1, seed = NULL,
                           checkpoints = NULL,
                           keep_trajectories = FALSE) {
  if (!inherits(environment, "bandit_environment")) {
    abort_bad(
      "`environment` must be a bandit_environment; see ?bandit_bernoulli."
    )
  }
  policies <- normalise_policies(policies)
  horizon <- check_count(horizon, "horizon", min = 1)
  replications <- check_count(replications, "replications", min = 1)
  if (!is.null(checkpoints)) {
    if (!is.numeric(checkpoints) || any(checkpoints != as.integer(checkpoints)) ||
        any(checkpoints < 1) || any(checkpoints > horizon) ||
        is.unsorted(checkpoints, strictly = TRUE)) {
      abort_bad(
        "`checkpoints` must be strictly increasing whole numbers in [1, horizon]."
      )
    }
    checkpoints <- as.integer(checkpoints)
  }
  if (!isTRUE(keep_trajectories) && !isFALSE(keep_trajectories)) {
    abort_bad("`keep_trajectories` must be TRUE or FALSE.")
  }

  arms <- environment$arms
  mu <- environment$expected_rewards
  has_oracle <- !is.null(mu)
  optimal_value <- if (has_oracle) max(mu) else NA_real_
  optimal_arms <- if (has_oracle) argmax_set(mu) else integer(0)

  # Seed handling: NULL draws a reproducible seed from the caller's RNG.
  caller_state <- get_random_seed()
  if (is.null(seed)) {
    seed <- sample.int(.Machine$integer.max, 1L)
    caller_state <- get_random_seed()
  } else {
    seed <- check_count(seed, "seed", min = -.Machine$integer.max)
  }
  on.exit(restore_random_seed(caller_state), add = TRUE)
  streams <- derive_streams(seed, replications)

  n_policies <- length(policies)
  n_runs <- n_policies * replications

  # Preallocated summary storage.
  sum_policy <- character(n_runs)
  sum_replicate <- integer(n_runs)
  sum_reward <- numeric(n_runs)
  sum_regret <- numeric(n_runs)
  sum_optshare <- numeric(n_runs)

  # Preallocated checkpoint storage.
  n_cp <- if (is.null(checkpoints)) 0L else length(checkpoints)
  cp_policy <- character(n_runs * n_cp)
  cp_replicate <- integer(n_runs * n_cp)
  cp_step <- integer(n_runs * n_cp)
  cp_reward <- numeric(n_runs * n_cp)
  cp_regret <- numeric(n_runs * n_cp)
  cp_optshare <- numeric(n_runs * n_cp)

  trajectory_list <- if (keep_trajectories) vector("list", n_runs) else NULL

  run_index <- 0L
  for (p in seq_len(n_policies)) {
    policy_name <- names(policies)[[p]]
    policy_config <- policies[[p]]

    for (r in seq_len(replications)) {
      run_index <- run_index + 1L
      set_random_seed(streams[[r]])

      state <- policy_state(policy_config, arms)

      arm_idx <- integer(horizon)
      reward_out <- numeric(horizon)
      propensity_out <- numeric(horizon)
      reason_out <- character(horizon)

      for (t in seq_len(horizon)) {
        decision <- select_arm(state, t)
        idx <- match(decision$arm, arms)
        if (is.na(idx)) {
          abort_bad(
            "policy '%s' selected unknown arm '%s' at step %d.",
            policy_name, format(decision$arm), t
          )
        }
        reward <- sample_reward(environment, decision$arm)

        arm_idx[t] <- idx
        reward_out[t] <- reward
        propensity_out[t] <-
          if (is.null(decision$propensity)) NA_real_ else decision$propensity
        reason_out[t] <-
          if (is.null(decision$reason)) NA_character_ else decision$reason

        state <- update_state(state, decision$arm, reward, t)
      }

      cumulative_reward <- cumsum(reward_out)
      if (has_oracle) {
        instantaneous_regret <- optimal_value - unname(mu[arm_idx])
        cumulative_regret <- cumsum(instantaneous_regret)
        optimal_hit <- as.numeric(arm_idx %in% optimal_arms)
        optimal_share_path <- cumsum(optimal_hit) / seq_len(horizon)
      } else {
        instantaneous_regret <- rep(NA_real_, horizon)
        cumulative_regret <- rep(NA_real_, horizon)
        optimal_share_path <- rep(NA_real_, horizon)
      }

      sum_policy[run_index] <- policy_name
      sum_replicate[run_index] <- r
      sum_reward[run_index] <- cumulative_reward[horizon]
      sum_regret[run_index] <- cumulative_regret[horizon]
      sum_optshare[run_index] <- optimal_share_path[horizon]

      if (n_cp > 0L) {
        rows <- ((run_index - 1L) * n_cp + 1L):(run_index * n_cp)
        cp_policy[rows] <- policy_name
        cp_replicate[rows] <- r
        cp_step[rows] <- checkpoints
        cp_reward[rows] <- cumulative_reward[checkpoints]
        cp_regret[rows] <- cumulative_regret[checkpoints]
        cp_optshare[rows] <- optimal_share_path[checkpoints]
      }

      if (keep_trajectories) {
        trajectory_list[[run_index]] <- tibble(
          policy = policy_name,
          replicate = r,
          step = seq_len(horizon),
          arm = arms[arm_idx],
          reward = reward_out,
          propensity = propensity_out,
          reason = reason_out,
          expected_reward = if (has_oracle) unname(mu[arm_idx]) else NA_real_,
          instantaneous_regret = instantaneous_regret
        )
      }
    }
  }

  result <- list(
    summary = tibble(
      policy = sum_policy,
      replicate = sum_replicate,
      total_reward = sum_reward,
      cumulative_regret = sum_regret,
      optimal_action_share = sum_optshare
    ),
    checkpoints = if (n_cp > 0L) {
      tibble(
        policy = cp_policy,
        replicate = cp_replicate,
        step = cp_step,
        cumulative_reward = cp_reward,
        cumulative_regret = cp_regret,
        optimal_action_share = cp_optshare
      )
    },
    trajectories = if (keep_trajectories) {
      do.call(rbind, trajectory_list)
    },
    meta = list(
      environment_class = class(environment)[1],
      arms = arms,
      expected_rewards = mu,
      optimal_arms = if (has_oracle) arms[optimal_arms] else NULL,
      policy_names = names(policies),
      horizon = horizon,
      replications = replications,
      seed = seed,
      rng_kind = "L'Ecuyer-CMRG",
      package_version = as.character(utils::packageVersion("banditlab"))
    )
  )
  class(result) <- "bandit_result"
  result
}

# Accept one policy or a named list of policies; return a named list.
normalise_policies <- function(policies) {
  if (inherits(policies, "bandit_policy")) {
    policies <- setNames(list(policies), class(policies)[1])
  }
  if (!is.list(policies) || length(policies) == 0 ||
      !all(vapply(policies, inherits, logical(1), "bandit_policy"))) {
    abort_bad(
      "`policies` must be a bandit_policy or a list of bandit_policy objects."
    )
  }
  if (length(policies) > 1 &&
      (is.null(names(policies)) || any(!nzchar(names(policies))) ||
       anyDuplicated(names(policies)))) {
    abort_bad("a list of policies must have unique, non-empty names.")
  }
  if (is.null(names(policies))) {
    names(policies) <- vapply(policies, function(p) class(p)[1], character(1))
  }
  policies
}
