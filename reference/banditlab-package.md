# banditlab: Multi-Armed Bandit Experimentation and Policy Comparison

A framework for simulating, comparing and extending multi-armed bandit
algorithms. The package separates three concerns:

## Details

- **Environments** generate rewards:
  [`bandit_bernoulli()`](https://rprodigest.github.io/banditlab/reference/bandit_bernoulli.md),
  [`bandit_gaussian()`](https://rprodigest.github.io/banditlab/reference/bandit_gaussian.md),
  [`bandit_custom()`](https://rprodigest.github.io/banditlab/reference/bandit_custom.md).

- **Policies** select arms and learn from rewards:
  [`policy_random()`](https://rprodigest.github.io/banditlab/reference/policy_random.md),
  [`policy_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_greedy.md),
  [`policy_epsilon_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_epsilon_greedy.md),
  [`policy_etc()`](https://rprodigest.github.io/banditlab/reference/policy_etc.md),
  [`policy_ucb1()`](https://rprodigest.github.io/banditlab/reference/policy_ucb1.md),
  [`policy_thompson()`](https://rprodigest.github.io/banditlab/reference/policy_thompson.md).

- **Experiments** connect the two:
  [`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)
  runs replicated simulations with reproducible per-replicate random
  number streams and returns tidy results for analysis with
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html),
  [`compare_policies()`](https://rprodigest.github.io/banditlab/reference/compare_policies.md)
  and
  [`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).

Custom policies plug into the same engine through three documented S3
generics:
[`policy_state()`](https://rprodigest.github.io/banditlab/reference/policy_interface.md),
[`select_arm()`](https://rprodigest.github.io/banditlab/reference/policy_interface.md)
and
[`update_state()`](https://rprodigest.github.io/banditlab/reference/policy_interface.md).
See
[`vignette("custom-policies", package = "banditlab")`](https://rprodigest.github.io/banditlab/articles/custom-policies.md).

Regret metrics follow exact definitions documented in
[regret_definitions](https://rprodigest.github.io/banditlab/reference/regret_definitions.md).

## See also

Useful links:

- <https://github.com/RProDigest/banditlab>

- Report bugs at <https://github.com/RProDigest/banditlab/issues>

## Author

**Maintainer**: Mubanga Nsofu <ProDigest@Protonmail.com>

Authors:

- Mubanga Nsofu <ProDigest@Protonmail.com>
