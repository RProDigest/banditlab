# banditlab 0.1.0

Initial CRAN release.

- `scale_colour_banditlab()` and `scale_fill_banditlab()` work with
  ggplot2 versions both before and after 3.5.0 (older versions require
  `scale_name` in `ggplot2::discrete_scale()`).
- New website article, "Bandits for RAN optimisation: 5G NR link
  adaptation", comparing bandit policies with a static CQI rule and
  outer-loop link adaptation in simulated stationary and drifting radio
  conditions.
- Environments: `bandit_bernoulli()`, `bandit_gaussian()`,
  `bandit_custom()`.
- Policies: `policy_random()`, `policy_greedy()` (optimistic initial
  values via `initial_value`), `policy_epsilon_greedy()` (fixed epsilon
  or a `schedule` function), `policy_etc()`, `policy_ucb1()`,
  `policy_thompson()`.
- `run_experiment()`: replicated experiments with one L'Ecuyer-CMRG
  stream per replicate; results are independent of the number of
  replicates run and seed-paired across policies.
- Results: per-replicate summaries, optional checkpoints, optional full
  trajectories with logged marginal propensities; `summary()`,
  `as_tibble()`, `compare_policies()`, `autoplot()`.
- Regret metrics with exact definitions in `?regret_definitions`;
  metrics are `NA` when the environment's expected rewards are unknown.
- Extension API: `policy_state()`, `select_arm()`, `update_state()`,
  documented in `vignette("custom-policies")` and exercised by a policy
  implemented outside the package in the test suite.
- Visualisation: `autoplot()` now applies `theme_banditlab()` (clean
  typography hierarchy, horizontal-only gridlines) and a fixed-order,
  7-hue accessible palette (`scale_colour_banditlab()` /
  `scale_fill_banditlab()`, aliased as `scale_color_banditlab()`) by
  default. The palette is derived from Okabe and Ito's categorical set,
  checked programmatically for lightness, chroma, simulated
  colour-vision-deficiency separation and contrast rather than chosen
  by eye (black excluded and reserved as ink; yellow deepened for
  legibility on white). Plot titles and axis labels name every metric
  in full (for example "Cumulative pseudo-regret", "Decision step").
  Identity is never colour-alone: line plots also vary linetype and the
  arm-share plot also varies bar position. Requesting more than seven
  policies in one `autoplot()` call errors with guidance rather than
  falling back silently to a non-accessible palette.
