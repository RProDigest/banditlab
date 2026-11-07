# Explore-then-commit policy

Plays every arm `explore_steps` times in round-robin order, then commits
permanently to the arm with the highest sample-average reward (uniform
tie-breaking at the moment of commitment).

## Usage

``` r
policy_etc(explore_steps)
```

## Arguments

- explore_steps:

  Number of exploration pulls per arm, a positive whole number.

## Value

A `bandit_policy` object.

## Details

If the horizon ends before exploration completes, the policy never
commits; this is visible in the `reason` column of trajectories.

## See also

[`policy_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_greedy.md),
[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
run_experiment(env, policy_etc(explore_steps = 20), horizon = 500, seed = 1)
#> <bandit_result> 1 policy x 1 replicate x horizon 500 (seed 1)
#> environment: bernoulli_environment (2 arms)
#> stored: summary
#> # A tibble: 1 × 8
#>   policy     replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>             <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 etc_policy            1           6             6           6           6
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
```
