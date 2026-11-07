test_that("etc explores round-robin then commits to the best arm", {
  env <- bandit_bernoulli(c(bad = 0, good = 1))
  result <- run_experiment(env, policy_etc(explore_steps = 3),
                           horizon = 20, seed = 1, keep_trajectories = TRUE)
  tr <- result$trajectories
  expect_equal(tr$arm[1:6], rep(c("bad", "good"), 3))
  expect_equal(tr$reason[1:6], rep("explore", 6))
  expect_true(all(tr$arm[7:20] == "good"))
  expect_true(all(tr$reason[7:20] == "commit"))
  expect_true(all(tr$propensity == 1))
})

test_that("ucb1 index matches a hand calculation", {
  s <- policy_state(policy_ucb1(), c("a", "b"))
  s$pulls <- c(a = 4L, b = 1L)
  s$reward_sum <- c(a = 2, b = 1)
  # At t = 6: index_a = 0.5 + sqrt(2 log 6 / 4), index_b = 1 + sqrt(2 log 6 / 1)
  index_a <- 0.5 + sqrt(2 * log(6) / 4)
  index_b <- 1 + sqrt(2 * log(6) / 1)
  expect_gt(index_b, index_a)
  d <- select_arm(s, 6)
  expect_equal(d$arm, "b")
  expect_equal(d$propensity, 1)
  expect_equal(d$reason, "ucb")
})

test_that("ucb1 initialises every arm once", {
  env <- bandit_bernoulli(c(a = 0.5, b = 0.5, c = 0.5))
  result <- run_experiment(env, policy_ucb1(), horizon = 3, seed = 1,
                           keep_trajectories = TRUE)
  expect_setequal(result$trajectories$arm, c("a", "b", "c"))
  expect_true(all(result$trajectories$reason == "initialisation"))
})

test_that("ucb1 concentrates on a dominant arm", {
  env <- bandit_bernoulli(c(bad = 0.1, good = 0.9))
  result <- run_experiment(env, policy_ucb1(), horizon = 500,
                           replications = 5, seed = 1)
  expect_true(all(result$summary$optimal_action_share > 0.7))
})

test_that("thompson posterior update matches conjugate arithmetic", {
  s <- policy_state(policy_thompson(alpha = 2, beta = 3), c("a", "b"))
  s <- update_state(s, "a", 1, 1)
  s <- update_state(s, "a", 0, 2)
  s <- update_state(s, "b", 1, 3)
  expect_equal(unname(s$alpha), c(3, 3))
  expect_equal(unname(s$beta), c(4, 3))
})

test_that("thompson rejects non-binary rewards with guidance", {
  s <- policy_state(policy_thompson(), c("a", "b"))
  expect_error(update_state(s, "a", 0.5, 1), "Bernoulli")
})

test_that("thompson per-arm priors are accepted", {
  s <- policy_state(policy_thompson(alpha = c(1, 5), beta = c(1, 2)),
                    c("a", "b"))
  expect_equal(unname(s$alpha), c(1, 5))
  expect_error(
    policy_state(policy_thompson(alpha = c(1, 2, 3)), c("a", "b")),
    "length"
  )
})

test_that("thompson logs NA propensity", {
  s <- policy_state(policy_thompson(), c("a", "b"))
  d <- withr::with_seed(1, select_arm(s, 1))
  expect_true(is.na(d$propensity))
})
