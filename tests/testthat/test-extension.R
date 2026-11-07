# The extension-architecture test required by the design: implement a
# softmax policy entirely outside the package, using only the exported
# interface, and run it through the standard engine.

policy_softmax <- function(temperature = 0.1) {
  stopifnot(is.numeric(temperature), length(temperature) == 1,
            temperature > 0)
  structure(
    list(temperature = temperature),
    class = c("softmax_policy", "bandit_policy")
  )
}

policy_state.softmax_policy <- function(policy, arms, ...) {
  policy$arms <- arms
  policy$pulls <- stats::setNames(rep(0L, length(arms)), arms)
  policy$reward_sum <- stats::setNames(rep(0, length(arms)), arms)
  policy
}

select_arm.softmax_policy <- function(policy, t, ...) {
  estimates <- ifelse(policy$pulls > 0,
                      policy$reward_sum / pmax(policy$pulls, 1), 0)
  centred <- (estimates - max(estimates)) / policy$temperature
  probabilities <- exp(centred) / sum(exp(centred))
  index <- sample.int(length(policy$arms), 1, prob = probabilities)
  list(
    arm = policy$arms[[index]],
    propensity = probabilities[[index]],
    reason = "softmax"
  )
}

update_state.softmax_policy <- function(policy, arm, reward, t, ...) {
  policy$pulls[[arm]] <- policy$pulls[[arm]] + 1L
  policy$reward_sum[[arm]] <- policy$reward_sum[[arm]] + reward
  policy
}

# In an ordinary script or package, S3 dispatch finds these methods
# automatically. Inside testthat (and knitr) evaluation environments the
# engine cannot see them, so they are registered explicitly. This is the
# documented pattern from ?policy_interface.
registerS3method("policy_state", "softmax_policy", policy_state.softmax_policy)
registerS3method("select_arm", "softmax_policy", select_arm.softmax_policy)
registerS3method("update_state", "softmax_policy", update_state.softmax_policy)

test_that("a custom policy runs in the standard engine", {
  env <- bandit_bernoulli(c(bad = 0.1, good = 0.9))
  result <- run_experiment(
    env,
    list(softmax = policy_softmax(0.1), ucb = policy_ucb1()),
    horizon = 300, replications = 4, seed = 8,
    keep_trajectories = TRUE
  )
  expect_equal(sort(unique(result$summary$policy)), c("softmax", "ucb"))
  soft <- result$summary[result$summary$policy == "softmax", ]
  expect_true(all(soft$optimal_action_share > 0.5))

  # The custom policy's propensities are logged like built-in ones.
  tr <- result$trajectories
  soft_prop <- tr$propensity[tr$policy == "softmax"]
  expect_true(all(soft_prop > 0 & soft_prop <= 1))
})

test_that("custom policies are reproducible and comparable", {
  env <- bandit_bernoulli(c(a = 0.3, b = 0.6))
  pols <- list(softmax = policy_softmax(0.05), thompson = policy_thompson())
  r1 <- run_experiment(env, pols, horizon = 100, replications = 5, seed = 3)
  r2 <- run_experiment(env, pols, horizon = 100, replications = 5, seed = 3)
  expect_equal(r1$summary, r2$summary)
  cmp <- compare_policies(r1, baseline = "thompson")
  expect_equal(nrow(cmp), 5)
})
