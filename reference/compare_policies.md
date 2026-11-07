# Seed-paired policy comparison

Because every policy runs replicate `r` from the same random number
stream (see
[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)),
per-replicate differences between policies are paired. Pairing removes
between-replicate noise from the comparison, exactly as paired seeds do
in a designed simulation study.

## Usage

``` r
compare_policies(
  result,
  metric = c("cumulative_regret", "total_reward"),
  baseline = NULL
)
```

## Arguments

- result:

  A `bandit_result` with at least two policies and at least two
  replications.

- metric:

  `"cumulative_regret"` (default) or `"total_reward"`.

- baseline:

  Name of the baseline policy. Default: the first policy in the
  experiment.

## Value

A tibble with one row per non-baseline policy and replicate: `policy`,
`baseline`, `replicate`, the metric under each, and `difference` (policy
minus baseline). For `cumulative_regret`, negative differences favour
the policy; for `total_reward`, positive differences favour the policy.

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
result <- run_experiment(
  env,
  list(epsilon = policy_epsilon_greedy(0.1), ucb = policy_ucb1()),
  horizon = 300, replications = 20, seed = 7
)
comparison <- compare_policies(result, baseline = "epsilon")
aggregate(difference ~ policy, data = comparison, FUN = mean)
#>   policy difference
#> 1    ucb      3.015
```
