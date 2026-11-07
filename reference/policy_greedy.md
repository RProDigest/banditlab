# Greedy policy with optional optimistic initial values

Always selects the arm with the highest estimated mean reward, with
uniform random tie-breaking. Estimates are sample averages.

## Usage

``` r
policy_greedy(initial_value = NULL)
```

## Arguments

- initial_value:

  `NULL` (default) or a single finite number used as the value estimate
  of untried arms.

## Value

A `bandit_policy` object.

## Details

By default (`initial_value = NULL`) each arm is tried once, in random
order, before greedy selection begins. Supplying a numeric
`initial_value` disables that forced initialisation: untried arms are
treated as having that estimated value, which implements optimistic
initial values when the value is set above the plausible reward range.
With sample-average estimates the optimism washes out after each arm's
first pull; its effect is to force early exploration.

## See also

[`policy_epsilon_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_epsilon_greedy.md),
[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
run_experiment(env, policy_greedy(), horizon = 200, seed = 1)
#> <bandit_result> 1 policy x 1 replicate x horizon 200 (seed 1)
#> environment: bernoulli_environment (2 arms)
#> stored: summary
#> # A tibble: 1 × 8
#>   policy        replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>                <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 greedy_policy            1        59.7          59.7        59.7        59.7
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>

# Optimistic initialisation: untried arms look better than any
# possible Bernoulli reward until sampled.
run_experiment(env, policy_greedy(initial_value = 1), horizon = 200, seed = 1)
#> <bandit_result> 1 policy x 1 replicate x horizon 200 (seed 1)
#> environment: bernoulli_environment (2 arms)
#> stored: summary
#> # A tibble: 1 × 8
#>   policy        replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>                <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 greedy_policy            1        59.7          59.7        59.7        59.7
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
```
