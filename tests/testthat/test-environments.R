test_that("bernoulli environment validates input", {
  expect_error(bandit_bernoulli(0.5), "at least two")
  expect_error(bandit_bernoulli(c(0.5, 1.2)), "between zero and one")
  expect_error(bandit_bernoulli(c(a = 0.1, a = 0.2)), "unique")
})

test_that("bernoulli boundary probabilities behave deterministically", {
  env <- bandit_bernoulli(c(never = 0, always = 1))
  expect_true(all(replicate(20, sample_reward(env, "always")) == 1))
  expect_true(all(replicate(20, sample_reward(env, "never")) == 0))
})

test_that("unnamed arms get default names", {
  env <- bandit_bernoulli(c(0.1, 0.2, 0.3))
  expect_equal(env$arms, c("arm_1", "arm_2", "arm_3"))
})

test_that("gaussian environment recycles sds and validates", {
  env <- bandit_gaussian(means = c(a = 0, b = 1, c = 2), sds = 0.5)
  expect_equal(unname(env$sds), rep(0.5, 3))
  expect_error(bandit_gaussian(c(0, 1), sds = -1), "positive")
  expect_error(bandit_gaussian(c(0, 1, 2), sds = c(1, 2)), "multiple")
})

test_that("custom environment computes rewards and validates sampler output", {
  env <- bandit_custom(
    sampler = function(arm) if (arm == "a") 1 else 2,
    arms = c("a", "b"),
    expected_rewards = c(a = 1, b = 2)
  )
  expect_equal(sample_reward(env, "a"), 1)
  expect_equal(sample_reward(env, "b"), 2)

  bad <- bandit_custom(function(arm) "x", arms = c("a", "b"))
  expect_error(sample_reward(bad, "a"), "finite numeric")
})

test_that("custom environment without expected rewards yields NA regret", {
  env <- bandit_custom(function(arm) 1, arms = c("a", "b"))
  result <- run_experiment(env, policy_random(), horizon = 10, seed = 1)
  expect_true(is.na(result$summary$cumulative_regret))
  expect_true(is.na(result$summary$optimal_action_share))
  expect_equal(result$summary$total_reward, 10)
})

test_that("environment print method runs", {
  expect_output(print(bandit_bernoulli(c(a = 0.2, b = 0.5))), "optimal")
  expect_output(
    print(bandit_custom(function(arm) 1, arms = c("a", "b"))),
    "unknown"
  )
})
