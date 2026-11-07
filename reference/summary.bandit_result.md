# Summarise a bandit experiment

Aggregates the per-replicate summaries into one row per policy. The
intervals are Monte Carlo quantiles across replicates (simulation
intervals), not confidence intervals for a deployment effect.

## Usage

``` r
# S3 method for class 'bandit_result'
summary(object, ...)
```

## Arguments

- object:

  A `bandit_result` from
  [`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md).

- ...:

  Unused.

## Value

A tibble with one row per policy: mean, median, 2.5% and 97.5% quantiles
of final cumulative pseudo-regret (`NA` when the environment's expected
rewards are unknown), mean total reward and mean optimal-action share.
See
[regret_definitions](https://rprodigest.github.io/banditlab/reference/regret_definitions.md).

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
result <- run_experiment(env, policy_ucb1(), horizon = 200,
                         replications = 10, seed = 1)
summary(result)
#> # A tibble: 1 × 8
#>   policy      replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>              <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 ucb1_policy           10        10.5           9.9         6.9        17.5
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
```
