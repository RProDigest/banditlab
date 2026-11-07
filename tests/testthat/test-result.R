make_result <- function(...) {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  run_experiment(
    env,
    list(epsilon = policy_epsilon_greedy(0.1), ucb = policy_ucb1()),
    horizon = 100, replications = 6, seed = 11, ...
  )
}

test_that("summary returns one labelled row per policy", {
  s <- summary(make_result())
  expect_equal(nrow(s), 2)
  expect_equal(s$policy, c("epsilon", "ucb"))
  expect_equal(s$replications, c(6, 6))
  expect_true(all(s$regret_q025 <= s$median_regret))
  expect_true(all(s$median_regret <= s$regret_q975))
})

test_that("print method reports composition", {
  expect_output(print(make_result()), "2 policies x 6 replicates")
})

test_that("as_tibble dispatches on component and errors helpfully", {
  result <- make_result()
  expect_s3_class(as_tibble(result), "tbl_df")
  expect_error(as_tibble(result, "trajectories"), "keep_trajectories")
  expect_error(as_tibble(result, "checkpoints"), "checkpoints")

  with_cp <- make_result(checkpoints = c(50, 100))
  expect_equal(nrow(as_tibble(with_cp, "checkpoints")), 2 * 6 * 2)
})

test_that("compare_policies produces paired differences", {
  result <- make_result()
  cmp <- compare_policies(result, baseline = "epsilon")
  expect_equal(nrow(cmp), 6)
  expect_equal(unique(cmp$policy), "ucb")
  expect_equal(cmp$difference, cmp$policy_value - cmp$baseline_value)

  expect_error(compare_policies(result, baseline = "nope"), "baseline")
})

test_that("compare_policies refuses regret without an oracle", {
  env <- bandit_custom(function(arm) rbinom(1, 1, 0.5), arms = c("a", "b"))
  result <- run_experiment(
    env, list(r = policy_random(), g = policy_greedy()),
    horizon = 20, replications = 3, seed = 1
  )
  expect_error(compare_policies(result), "unavailable")
  cmp <- compare_policies(result, metric = "total_reward")
  expect_equal(nrow(cmp), 3)
})

test_that("compare_policies requires two policies and replications", {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  one_pol <- run_experiment(env, policy_random(), 10, replications = 3, seed = 1)
  expect_error(compare_policies(one_pol), "two policies")
  one_rep <- run_experiment(
    env, list(a = policy_random(), b = policy_greedy()), 10, seed = 1
  )
  expect_error(compare_policies(one_rep), "replications")
})
