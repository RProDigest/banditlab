# Random selection policy

Selects an arm uniformly at random at every step. Useful as a floor
baseline and for generating uniformly randomised logs.

## Usage

``` r
policy_random()
```

## Value

A `bandit_policy` object.

## See also

[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md),
[policy_interface](https://rprodigest.github.io/banditlab/reference/policy_interface.md)

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
result <- run_experiment(env, policy_random(), horizon = 100, seed = 1)
summary(result)
#> # A tibble: 1 × 8
#>   policy        replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>                <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 random_policy            1        15.9          15.9        15.9        15.9
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
```
