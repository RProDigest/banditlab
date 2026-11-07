# Changelog

## banditlab 0.1.0

Initial CRAN release.

- [`scale_colour_banditlab()`](https://rprodigest.github.io/banditlab/reference/scale_colour_banditlab.md)
  and
  [`scale_fill_banditlab()`](https://rprodigest.github.io/banditlab/reference/scale_colour_banditlab.md)
  work with ggplot2 versions both before and after 3.5.0 (older versions
  require `scale_name` in
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html)).
- New website article, “Bandits for RAN optimisation: 5G NR link
  adaptation”, comparing bandit policies with a static CQI rule and
  outer-loop link adaptation in simulated stationary and drifting radio
  conditions.
- Environments:
  [`bandit_bernoulli()`](https://rprodigest.github.io/banditlab/reference/bandit_bernoulli.md),
  [`bandit_gaussian()`](https://rprodigest.github.io/banditlab/reference/bandit_gaussian.md),
  [`bandit_custom()`](https://rprodigest.github.io/banditlab/reference/bandit_custom.md).
- Policies:
  [`policy_random()`](https://rprodigest.github.io/banditlab/reference/policy_random.md),
  [`policy_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_greedy.md)
  (optimistic initial values via `initial_value`),
  [`policy_epsilon_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_epsilon_greedy.md)
  (fixed epsilon or a `schedule` function),
  [`policy_etc()`](https://rprodigest.github.io/banditlab/reference/policy_etc.md),
  [`policy_ucb1()`](https://rprodigest.github.io/banditlab/reference/policy_ucb1.md),
  [`policy_thompson()`](https://rprodigest.github.io/banditlab/reference/policy_thompson.md).
- [`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md):
  replicated experiments with one L’Ecuyer-CMRG stream per replicate;
  results are independent of the number of replicates run and
  seed-paired across policies.
- Results: per-replicate summaries, optional checkpoints, optional full
  trajectories with logged marginal propensities;
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html),
  [`compare_policies()`](https://rprodigest.github.io/banditlab/reference/compare_policies.md),
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).
- Regret metrics with exact definitions in
  [`?regret_definitions`](https://rprodigest.github.io/banditlab/reference/regret_definitions.md);
  metrics are `NA` when the environment’s expected rewards are unknown.
- Extension API:
  [`policy_state()`](https://rprodigest.github.io/banditlab/reference/policy_interface.md),
  [`select_arm()`](https://rprodigest.github.io/banditlab/reference/policy_interface.md),
  [`update_state()`](https://rprodigest.github.io/banditlab/reference/policy_interface.md),
  documented in
  [`vignette("custom-policies")`](https://rprodigest.github.io/banditlab/articles/custom-policies.md)
  and exercised by a policy implemented outside the package in the test
  suite.
- Visualisation:
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  now applies
  [`theme_banditlab()`](https://rprodigest.github.io/banditlab/reference/theme_banditlab.md)
  (clean typography hierarchy, horizontal-only gridlines) and a
  fixed-order, 7-hue accessible palette
  ([`scale_colour_banditlab()`](https://rprodigest.github.io/banditlab/reference/scale_colour_banditlab.md)
  /
  [`scale_fill_banditlab()`](https://rprodigest.github.io/banditlab/reference/scale_colour_banditlab.md),
  aliased as
  [`scale_color_banditlab()`](https://rprodigest.github.io/banditlab/reference/scale_colour_banditlab.md))
  by default. The palette is derived from Okabe and Ito’s categorical
  set, checked programmatically for lightness, chroma, simulated
  colour-vision-deficiency separation and contrast rather than chosen by
  eye (black excluded and reserved as ink; yellow deepened for
  legibility on white). Plot titles and axis labels name every metric in
  full (for example “Cumulative pseudo-regret”, “Decision step”).
  Identity is never colour-alone: line plots also vary linetype and the
  arm-share plot also varies bar position. Requesting more than seven
  policies in one
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  call errors with guidance rather than falling back silently to a
  non-accessible palette.
