# Run a replicated bandit experiment

Runs one or more policies against an environment for a fixed horizon,
optionally replicated, and returns tidy results. This is the single
entry point to the simulation engine; every policy, built-in or
user-defined via the
[policy_interface](https://rprodigest.github.io/banditlab/reference/policy_interface.md),
runs through it.

## Usage

``` r
run_experiment(
  environment,
  policies,
  horizon,
  replications = 1,
  seed = NULL,
  checkpoints = NULL,
  keep_trajectories = FALSE
)
```

## Arguments

- environment:

  A `bandit_environment` created by
  [`bandit_bernoulli()`](https://rprodigest.github.io/banditlab/reference/bandit_bernoulli.md),
  [`bandit_gaussian()`](https://rprodigest.github.io/banditlab/reference/bandit_gaussian.md),
  [`bandit_custom()`](https://rprodigest.github.io/banditlab/reference/bandit_custom.md),
  or a user-defined environment class with a
  [`sample_reward()`](https://rprodigest.github.io/banditlab/reference/sample_reward.md)
  method.

- policies:

  A single `bandit_policy` or a named list of them. The names label the
  results; a single unnamed policy is labelled with its class name.

- horizon:

  Number of decisions per replicate.

- replications:

  Number of independent replicates per policy.

- seed:

  Single integer controlling all randomness, or `NULL`. See Details.

- checkpoints:

  Optional increasing vector of steps at which cumulative metrics are
  recorded per replicate. Enables trajectory plots without retaining
  full logs.

- keep_trajectories:

  If `TRUE`, retain the full event log of every replicate (one row per
  decision). Default `FALSE`: for large experiments the logs dominate
  memory, so retention is opt-in.

## Value

A `bandit_result` object: a list with elements

- summary:

  tibble, one row per policy and replicate: `policy`, `replicate`,
  `total_reward`, `cumulative_regret`, `optimal_action_share`.

- checkpoints:

  tibble of cumulative metrics at the requested steps, or `NULL`.

- trajectories:

  tibble with one row per decision (`policy`, `replicate`, `step`,
  `arm`, `reward`, `propensity`, `reason`, `expected_reward`,
  `instantaneous_regret`), or `NULL`.

- meta:

  list of experiment metadata, including the seed used.

## Details

### Randomness and reproducibility

When `seed` is supplied, the engine derives one independent
L'Ecuyer-CMRG stream per replicate using
[`parallel::nextRNGStream()`](https://rdrr.io/r/parallel/RngStream.html).
Replicate `r` always runs on stream `r`, so its results do not depend on
how many other replicates run, and every policy faces replicate `r` from
the same stream start, making comparisons seed-paired by construction.
The caller's RNG state, including the RNG kind, is restored on exit.

When `seed` is `NULL`, a seed is drawn from the current RNG (advancing
it, so repeated calls differ) and then used the same way; the drawn seed
is stored in the result's `$meta$seed`, so any run can be reproduced
after the fact.

Within a replicate, environment and policy randomness share the
replicate's stream. Two policies that consume different amounts of
randomness therefore see different reward realisations at later steps;
comparisons remain fair because both face the same distribution, and
paired because both start from the same stream.

### Regret

If the environment's expected rewards are known, each step records the
instantaneous pseudo-regret `max(mu) - mu[arm]`; see
[regret_definitions](https://rprodigest.github.io/banditlab/reference/regret_definitions.md)
for exact definitions. If they are unknown (a
[`bandit_custom()`](https://rprodigest.github.io/banditlab/reference/bandit_custom.md)
without `expected_rewards`), regret and optimal-action columns are `NA`.

## See also

[`summary.bandit_result()`](https://rprodigest.github.io/banditlab/reference/summary.bandit_result.md),
[`compare_policies()`](https://rprodigest.github.io/banditlab/reference/compare_policies.md),
[`autoplot.bandit_result()`](https://rprodigest.github.io/banditlab/reference/autoplot.bandit_result.md),
[policy_interface](https://rprodigest.github.io/banditlab/reference/policy_interface.md)

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
result <- run_experiment(
  env,
  policies = list(
    epsilon = policy_epsilon_greedy(0.1),
    thompson = policy_thompson()
  ),
  horizon = 300,
  replications = 20,
  seed = 42,
  checkpoints = c(50, 100, 200, 300)
)
result
#> <bandit_result> 2 policies x 20 replicates x horizon 300 (seed 42)
#> environment: bernoulli_environment (2 arms)
#> stored: summary + checkpoints
#> # A tibble: 2 × 8
#>   policy   replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>           <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 epsilon            20       13.2            5.1        2.83       63.9 
#> 2 thompson           20        4.62           4.2        1.94        8.43
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
summary(result)
#> # A tibble: 2 × 8
#>   policy   replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>           <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 epsilon            20       13.2            5.1        2.83       63.9 
#> 2 thompson           20        4.62           4.2        1.94        8.43
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
```
