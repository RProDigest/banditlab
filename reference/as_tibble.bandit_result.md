# Convert experiment results to a tibble

Convert experiment results to a tibble

## Usage

``` r
# S3 method for class 'bandit_result'
as_tibble(x, what = c("summary", "checkpoints", "trajectories"), ...)
```

## Arguments

- x:

  A `bandit_result` from
  [`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md).

- what:

  Which component to return: the per-replicate `"summary"` (default),
  the `"checkpoints"` table, or the full `"trajectories"`.

- ...:

  Unused.

## Value

A tibble.

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
result <- run_experiment(env, policy_random(), horizon = 50,
                         replications = 3, seed = 1)
as_tibble(result)
#> # A tibble: 3 × 5
#>   policy        replicate total_reward cumulative_regret optimal_action_share
#>   <chr>             <int>        <dbl>             <dbl>                <dbl>
#> 1 random_policy         1           19               7.8                 0.48
#> 2 random_policy         2           19               8.4                 0.44
#> 3 random_policy         3           10               6.9                 0.54
```
