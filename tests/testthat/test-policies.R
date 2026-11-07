test_that("constructors validate configuration", {
  expect_error(policy_epsilon_greedy(epsilon = 1.5), "epsilon")
  expect_error(policy_epsilon_greedy(schedule = 5), "schedule")
  expect_error(policy_etc(explore_steps = 0), "explore_steps")
  expect_error(policy_etc(explore_steps = 2.5), "whole number")
  expect_error(policy_thompson(alpha = -1), "positive")
})

test_that("policy_state initialises fresh state each time", {
  pol <- policy_epsilon_greedy(0.1)
  s1 <- policy_state(pol, c("a", "b"))
  s1 <- update_state(s1, "a", 1, 1)
  s2 <- policy_state(pol, c("a", "b"))
  expect_equal(unname(s2$pulls), c(0L, 0L))
  expect_equal(s1$pulls[["a"]], 1L)
  expect_null(pol$pulls)
})

test_that("value updates match hand calculations", {
  s <- policy_state(policy_greedy(), c("a", "b"))
  s <- update_state(s, "a", 1, 1)
  s <- update_state(s, "a", 0, 2)
  s <- update_state(s, "b", 1, 3)
  expect_equal(s$reward_sum[["a"]] / s$pulls[["a"]], 0.5)
  expect_equal(s$reward_sum[["b"]] / s$pulls[["b"]], 1)
})

test_that("greedy exploits a deterministic best arm after initialisation", {
  env <- bandit_bernoulli(c(bad = 0, good = 1))
  result <- run_experiment(env, policy_greedy(), horizon = 100, seed = 1,
                           keep_trajectories = TRUE)
  tail_arms <- result$trajectories$arm[3:100]
  expect_true(all(tail_arms == "good"))
  expect_equal(result$summary$cumulative_regret, 1)
})

test_that("optimistic initial values replace forced initialisation", {
  pol <- policy_greedy(initial_value = 5)
  s <- policy_state(pol, c("a", "b"))
  d <- withr::with_seed(1, select_arm(s, 1))
  expect_true(d$arm %in% c("a", "b"))
  expect_false(identical(d$reason, "initialisation"))
})

test_that("epsilon-greedy propensity is the marginal selection probability", {
  s <- policy_state(policy_epsilon_greedy(0.2), c("a", "b"))
  s <- update_state(s, "a", 1, 1)
  s <- update_state(s, "b", 0, 2)
  s$pulls <- c(a = 5L, b = 5L)
  s$reward_sum <- c(a = 4, b = 1)

  draws <- withr::with_seed(1, {
    replicate(4000, {
      d <- select_arm(s, 11)
      c(d$arm, d$propensity)
    })
  })
  arms <- draws[1, ]
  logged <- as.numeric(draws[2, ])

  expect_equal(unique(logged[arms == "a"]), 0.9)
  expect_equal(unique(logged[arms == "b"]), 0.1)
  expect_lt(abs(mean(arms == "a") - 0.9), 0.02)
})

test_that("epsilon schedule is applied and validated", {
  pol <- policy_epsilon_greedy(schedule = function(t) if (t < 5) 1 else 0)
  s <- policy_state(pol, c("a", "b"))
  s$pulls <- c(a = 1L, b = 1L)
  s$reward_sum <- c(a = 1, b = 0)
  d <- withr::with_seed(1, select_arm(s, 10))
  expect_equal(d$arm, "a")
  expect_equal(d$propensity, 1)

  bad <- policy_epsilon_greedy(schedule = function(t) 2)
  sb <- policy_state(bad, c("a", "b"))
  sb$pulls <- c(a = 1L, b = 1L)
  expect_error(select_arm(sb, 1), "schedule")
})

test_that("random policy is uniform with correct propensity", {
  s <- policy_state(policy_random(), c("a", "b", "c", "d"))
  d <- withr::with_seed(1, select_arm(s, 1))
  expect_equal(d$propensity, 0.25)
  picks <- withr::with_seed(
    2,
    replicate(4000, select_arm(s, 1)$arm)
  )
  expect_lt(max(abs(table(picks) / 4000 - 0.25)), 0.03)
})
