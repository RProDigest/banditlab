#' Plot bandit experiment results
#'
#' Standard diagnostic plots for a `bandit_result`. Every plot uses
#' [theme_banditlab()] and the package's accessibility-checked
#' [scale_colour_banditlab()] palette by default, and returns a plain
#' ggplot object: add `+ ggplot2::theme(...)` or a different scale
#' afterwards to change anything.
#'
#' @param object A `bandit_result` from [run_experiment()].
#' @param metric One of:
#'   \describe{
#'     \item{`"cumulative_regret"`}{Median cumulative pseudo-regret over
#'       time per policy, with a 10th to 90th percentile ribbon across
#'       replicates. Requires checkpoints or trajectories, and known
#'       expected rewards.}
#'     \item{`"cumulative_reward"`}{Same display for cumulative reward.}
#'     \item{`"optimal_action_share"`}{Share of decisions selecting an
#'       optimal arm, over time.}
#'     \item{`"arm_share"`}{Overall selection share per arm and policy.
#'       Requires trajectories.}
#'   }
#' @param ... Unused.
#'
#' @return A ggplot object.
#'
#' @section Accessibility:
#' Colour is never the only channel that carries policy identity: line
#' plots also vary linetype, and the bar plot also varies bar position
#' along the arm axis. The palette supports up to seven policies in a
#' fixed order (see [scale_colour_banditlab()]); plotting an eighth
#' policy in one call is an error rather than a silent fallback to a
#' non-accessible default. `as_tibble(object)` gives the exact values
#' behind any plot.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' result <- run_experiment(
#'   env,
#'   list(epsilon = policy_epsilon_greedy(0.1), thompson = policy_thompson()),
#'   horizon = 200, replications = 10, seed = 1,
#'   checkpoints = seq(20, 200, by = 20)
#' )
#' autoplot(result)
#' autoplot(result, metric = "optimal_action_share")
#'
#' @seealso [theme_banditlab()], [scale_colour_banditlab()],
#'   [run_experiment()]
#' @exportS3Method ggplot2::autoplot
autoplot.bandit_result <- function(object,
                                   metric = c("cumulative_regret",
                                              "cumulative_reward",
                                              "optimal_action_share",
                                              "arm_share"),
                                   ...) {
  metric <- match.arg(metric)
  if (metric == "arm_share") {
    return(plot_arm_share(object))
  }
  plot_metric_band(object, metric)
}

# Checkpoint-style data: prefer stored checkpoints, else derive from
# trajectories, else fail with guidance.
checkpoint_data <- function(object) {
  if (!is.null(object$checkpoints)) {
    return(object$checkpoints)
  }
  if (!is.null(object$trajectories)) {
    tr <- object$trajectories
    pieces <- lapply(
      split(tr, list(tr$policy, tr$replicate), drop = TRUE),
      function(d) {
        d <- d[order(d$step), ]
        horizon <- nrow(d)
        optimal <- object$meta$optimal_arms
        tibble(
          policy = d$policy[[1]],
          replicate = d$replicate[[1]],
          step = d$step,
          cumulative_reward = cumsum(d$reward),
          cumulative_regret = cumsum(d$instantaneous_regret),
          optimal_action_share = if (is.null(optimal)) {
            NA_real_
          } else {
            cumsum(as.numeric(d$arm %in% optimal)) / seq_len(horizon)
          }
        )
      }
    )
    return(do.call(rbind, pieces))
  }
  abort_bad(
    "this result has no time-resolved data; rerun run_experiment() with %s",
    "`checkpoints = ` or `keep_trajectories = TRUE`."
  )
}

plot_metric_band <- function(object, metric) {
  cp <- checkpoint_data(object)
  if (anyNA(cp[[metric]])) {
    abort_bad(
      "metric '%s' is unavailable: the environment's expected rewards %s",
      metric, "are unknown; see ?regret_definitions."
    )
  }

  pieces <- lapply(
    split(cp, list(cp$policy, cp$step), drop = TRUE),
    function(d) {
      tibble(
        policy = d$policy[[1]],
        step = d$step[[1]],
        mid = median(d[[metric]]),
        lower = unname(quantile(d[[metric]], 0.10)),
        upper = unname(quantile(d[[metric]], 0.90))
      )
    }
  )
  band <- do.call(rbind, pieces)
  band <- band[order(band$policy, band$step), ]

  title <- switch(
    metric,
    cumulative_regret = "Cumulative pseudo-regret by policy",
    cumulative_reward = "Cumulative reward by policy",
    optimal_action_share = "Share of decisions on an optimal arm"
  )
  ylabel <- switch(
    metric,
    cumulative_regret = "Cumulative pseudo-regret",
    cumulative_reward = "Cumulative reward",
    optimal_action_share = "Optimal action share"
  )

  p <- ggplot2::ggplot(
    band,
    ggplot2::aes(
      x = step, y = mid,
      colour = policy, fill = policy,
      linetype = policy
    )
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = lower, ymax = upper),
      alpha = 0.15, colour = NA
    ) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::labs(
      title = title,
      subtitle = "Median across replicates; band spans the 10th to 90th percentiles",
      x = "Decision step",
      y = ylabel,
      colour = "Policy", fill = "Policy", linetype = "Policy"
    )
  finish_plot(p, n = length(unique(band$policy)))
}

plot_arm_share <- function(object) {
  if (is.null(object$trajectories)) {
    abort_bad(
      "arm_share needs full trajectories; rerun run_experiment() with %s",
      "`keep_trajectories = TRUE`."
    )
  }
  tr <- object$trajectories
  counts <- as.data.frame(table(policy = tr$policy, arm = tr$arm))
  totals <- tapply(counts$Freq, counts$policy, sum)
  counts$share <- counts$Freq / as.numeric(totals[counts$policy])
  counts <- tibble(
    policy = as.character(counts$policy),
    arm = as.character(counts$arm),
    share = counts$share
  )

  p <- ggplot2::ggplot(
    counts,
    ggplot2::aes(x = arm, y = share, fill = policy)
  ) +
    ggplot2::geom_col(
      position = ggplot2::position_dodge(width = 0.75),
      width = 0.65, colour = "white", linewidth = 0.3
    ) +
    ggplot2::scale_y_continuous(labels = scales_percent) +
    ggplot2::labs(
      title = "Arm selection share by policy",
      x = "Arm", y = "Selection share", fill = "Policy"
    )
  finish_plot(p, n = length(unique(counts$policy)))
}

# Format a proportion 0-1 as a percentage without adding a dependency
# on the scales package for one label formatter.
scales_percent <- function(x) {
  paste0(round(100 * x), "%")
}

# Apply the package's default theme and accessible palette together, so
# every autoplot() branch stays visually consistent by construction.
finish_plot <- function(p, n) {
  if (n > length(okabe_ito_ordered)) {
    abort_bad(
      "autoplot() supports up to %d policies with distinct colours in one plot (got %d). %s",
      length(okabe_ito_ordered), n,
      "Compare a subset of policies, or build a custom plot from as_tibble()."
    )
  }
  add_okabe_ito(p) + theme_banditlab()
}
