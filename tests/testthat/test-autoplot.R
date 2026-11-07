test_that("autoplot builds each metric from checkpoints or trajectories", {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  result <- run_experiment(
    env, list(e = policy_epsilon_greedy(0.1), u = policy_ucb1()),
    horizon = 60, replications = 4, seed = 2,
    checkpoints = c(20, 40, 60), keep_trajectories = TRUE
  )
  for (metric in c("cumulative_regret", "cumulative_reward",
                   "optimal_action_share", "arm_share")) {
    p <- ggplot2::autoplot(result, metric = metric)
    expect_s3_class(p, "ggplot")
    built <- ggplot2::ggplot_build(p)
    expect_gt(length(built$data), 0)
  }
})

test_that("autoplot falls back to trajectories when no checkpoints stored", {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  result <- run_experiment(env, policy_greedy(), horizon = 30,
                           replications = 3, seed = 4,
                           keep_trajectories = TRUE)
  p <- ggplot2::autoplot(result)
  expect_s3_class(p, "ggplot")
})

test_that("autoplot errors with guidance when data is missing", {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  summary_only <- run_experiment(env, policy_greedy(), horizon = 30,
                                 replications = 3, seed = 4)
  expect_error(ggplot2::autoplot(summary_only), "checkpoints")
  expect_error(ggplot2::autoplot(summary_only, metric = "arm_share"),
               "keep_trajectories")
})

test_that("regret plot refuses environments without an oracle", {
  env <- bandit_custom(function(arm) rbinom(1, 1, 0.5), arms = c("a", "b"))
  result <- run_experiment(env, policy_random(), horizon = 30,
                           replications = 3, seed = 1,
                           checkpoints = c(10, 30))
  expect_error(ggplot2::autoplot(result), "expected rewards")
  p <- ggplot2::autoplot(result, metric = "cumulative_reward")
  expect_s3_class(p, "ggplot")
})
