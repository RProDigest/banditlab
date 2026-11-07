test_that("theme_banditlab returns a usable ggplot2 theme", {
  th <- theme_banditlab()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")

  p <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) +
    ggplot2::geom_point() +
    theme_banditlab(base_size = 14)
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
})

test_that("the palette is fixed-order, 7 hues, and excludes black", {
  expect_length(banditlab:::okabe_ito_ordered, 7)
  expect_false("#000000" %in% toupper(banditlab:::okabe_ito_ordered))
  expect_equal(length(unique(banditlab:::okabe_ito_ordered)), 7)
})

test_that("scale_colour_banditlab and the color alias agree", {
  expect_identical(scale_color_banditlab, scale_colour_banditlab)
})

test_that("scale_colour_banditlab assigns the fixed order regardless of factor levels", {
  df <- data.frame(
    x = 1:4,
    y = 1:4,
    policy = factor(c("z", "a", "m", "b"), levels = c("z", "a", "m", "b"))
  )
  p <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = policy)) +
    ggplot2::geom_point() +
    scale_colour_banditlab()
  built <- ggplot2::ggplot_build(p)
  used <- unique(built$data[[1]]$colour)
  expect_setequal(toupper(used), toupper(banditlab:::okabe_ito_ordered[1:4]))
})

test_that("autoplot applies the package theme and palette by default", {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  result <- run_experiment(env, list(a = policy_random(), b = policy_ucb1()),
                           horizon = 60, replications = 5, seed = 1,
                           checkpoints = c(30, 60))
  p <- autoplot(result)
  expect_true(any(vapply(p$theme, is.null, logical(1)) == FALSE))
  built <- ggplot2::ggplot_build(p)
  used_colours <- unique(built$data[[2]]$colour)
  expect_setequal(toupper(used_colours), toupper(banditlab:::okabe_ito_ordered[1:2]))
})

test_that("plots carry clear titles and axis labels", {
  env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
  result <- run_experiment(env, policy_ucb1(), horizon = 60, seed = 1,
                           checkpoints = c(30, 60), keep_trajectories = TRUE)

  regret_plot <- autoplot(result, metric = "cumulative_regret")
  expect_equal(regret_plot$labels$x, "Decision step")
  expect_equal(regret_plot$labels$y, "Cumulative pseudo-regret")
  expect_equal(regret_plot$labels$title, "Cumulative pseudo-regret by policy")

  reward_plot <- autoplot(result, metric = "cumulative_reward")
  expect_equal(reward_plot$labels$y, "Cumulative reward")

  share_plot <- autoplot(result, metric = "optimal_action_share")
  expect_equal(share_plot$labels$y, "Optimal action share")

  arm_plot <- autoplot(result, metric = "arm_share")
  expect_equal(arm_plot$labels$x, "Arm")
  expect_equal(arm_plot$labels$y, "Selection share")
  expect_equal(arm_plot$labels$title, "Arm selection share by policy")
})

test_that("more policies than the palette supports errors with guidance", {
  env <- bandit_bernoulli(setNames(seq(0.1, 0.8, length.out = 8), letters[1:8]))
  pols <- setNames(
    replicate(8, policy_random(), simplify = FALSE),
    paste0("p", 1:8)
  )
  result <- run_experiment(env, pols, horizon = 20, seed = 1,
                           checkpoints = c(10, 20))
  expect_error(autoplot(result), "up to 7 policies")
})
