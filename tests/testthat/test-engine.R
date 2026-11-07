test_that("engine validates its arguments", {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  expect_error(run_experiment("x", policy_random(), 10), "bandit_environment")
  expect_error(run_experiment(env, "x", 10), "bandit_policy")
  expect_error(run_experiment(env, policy_random(), 0), "horizon")
  expect_error(run_experiment(env, policy_random(), 10, replications = 0),
               "replications")
  expect_error(
    run_experiment(env, policy_random(), 10, checkpoints = c(5, 20)),
    "checkpoints"
  )
  expect_error(
    run_experiment(env, list(policy_random(), policy_ucb1()), 10),
    "names"
  )
})

test_that("a single policy is labelled with its class", {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  result <- run_experiment(env, policy_ucb1(), horizon = 10, seed = 1)
  expect_equal(result$summary$policy, "ucb1_policy")
})

test_that("summary dimensions and regret arithmetic are correct", {
  env <- bandit_bernoulli(c(bad = 0, good = 1))
  result <- run_experiment(
    env, list(r = policy_random(), g = policy_greedy()),
    horizon = 50, replications = 4, seed = 9
  )
  expect_equal(nrow(result$summary), 8)
  # In this deterministic environment reward + regret = horizon * mu_max
  # whenever only optimal pulls earn reward.
  expect_equal(
    result$summary$total_reward + result$summary$cumulative_regret,
    rep(50, 8)
  )
})

test_that("checkpoints record cumulative metrics at the right steps", {
  env <- bandit_bernoulli(c(bad = 0, good = 1))
  result <- run_experiment(env, policy_greedy(), horizon = 20, seed = 3,
                           checkpoints = c(5, 10, 20),
                           keep_trajectories = TRUE)
  cp <- result$checkpoints
  tr <- result$trajectories
  expect_equal(cp$step, c(5, 10, 20))
  expect_equal(cp$cumulative_reward, cumsum(tr$reward)[c(5, 10, 20)])
  expect_equal(cp$cumulative_regret,
               cumsum(tr$instantaneous_regret)[c(5, 10, 20)])
})

test_that("results are reproducible under a fixed seed", {
  env <- bandit_bernoulli(c(a = 0.3, b = 0.6))
  pols <- list(e = policy_epsilon_greedy(0.1), t = policy_thompson())
  r1 <- run_experiment(env, pols, horizon = 100, replications = 3, seed = 42,
                       keep_trajectories = TRUE)
  r2 <- run_experiment(env, pols, horizon = 100, replications = 3, seed = 42,
                       keep_trajectories = TRUE)
  expect_equal(r1$summary, r2$summary)
  expect_equal(r1$trajectories, r2$trajectories)
})

test_that("replicate results do not depend on the number of replications", {
  env <- bandit_bernoulli(c(a = 0.3, b = 0.6))
  small <- run_experiment(env, policy_ucb1(), horizon = 50,
                          replications = 2, seed = 7)
  large <- run_experiment(env, policy_ucb1(), horizon = 50,
                          replications = 5, seed = 7)
  expect_equal(small$summary, large$summary[large$summary$replicate <= 2, ])
})

test_that("policies are seed-paired: same stream start per replicate", {
  env <- bandit_bernoulli(c(a = 0.5, b = 0.5))
  # Two copies of the same deterministic-after-init policy must produce
  # identical trajectories replicate by replicate.
  result <- run_experiment(
    env, list(one = policy_etc(2), two = policy_etc(2)),
    horizon = 30, replications = 3, seed = 5, keep_trajectories = TRUE
  )
  tr <- result$trajectories
  one <- tr[tr$policy == "one", setdiff(names(tr), "policy")]
  two <- tr[tr$policy == "two", setdiff(names(tr), "policy")]
  expect_equal(one, two, ignore_attr = TRUE)
})

test_that("caller RNG state is restored, seed = NULL still reproducible", {
  env <- bandit_bernoulli(c(a = 0.3, b = 0.6))
  set.seed(123)
  before <- .Random.seed
  result <- run_experiment(env, policy_random(), horizon = 20, seed = 99)
  expect_identical(before, .Random.seed)

  # seed = NULL draws a seed (advancing caller RNG) and records it.
  set.seed(123)
  r1 <- run_experiment(env, policy_random(), horizon = 20)
  expect_false(is.null(r1$meta$seed))
  r2 <- run_experiment(env, policy_random(), horizon = 20,
                       seed = r1$meta$seed)
  expect_equal(r1$summary, r2$summary)

  # Consecutive NULL-seed calls differ.
  set.seed(123)
  a <- run_experiment(env, policy_random(), horizon = 20)
  b <- run_experiment(env, policy_random(), horizon = 20)
  expect_false(identical(a$meta$seed, b$meta$seed))
})

test_that("an informative error names a policy returning an unknown arm", {
  broken <- structure(list(), class = c("broken_policy", "bandit_policy"))
  assign("policy_state.broken_policy",
         function(policy, arms, ...) { policy$arms <- arms; policy },
         envir = globalenv())
  assign("select_arm.broken_policy",
         function(policy, t, ...) list(arm = "nope"),
         envir = globalenv())
  assign("update_state.broken_policy",
         function(policy, arm, reward, t, ...) policy,
         envir = globalenv())
  on.exit(rm(list = c("policy_state.broken_policy",
                      "select_arm.broken_policy",
                      "update_state.broken_policy"), envir = globalenv()))
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  expect_error(
    run_experiment(env, list(bad = broken), horizon = 5, seed = 1),
    "unknown arm 'nope'"
  )
})
