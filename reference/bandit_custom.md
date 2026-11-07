# Create a custom bandit environment

Wraps a user-supplied reward sampler so that any stochastic reward
process can run in
[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)
without modifying the package.

## Usage

``` r
bandit_custom(sampler, arms, expected_rewards = NULL)
```

## Arguments

- sampler:

  A function of one argument, the arm name, returning a single finite
  numeric reward.

- arms:

  Character vector of at least two unique arm names.

- expected_rewards:

  Optional named numeric vector of true expected rewards, one per arm.
  When supplied, regret metrics are computed; when `NULL` (the default),
  regret columns are `NA` because the oracle value is unknown.

## Value

A `bandit_environment` object.

## Details

The sampler is called once per decision with the selected arm name and
the current R random number generator state; use the current RNG (e.g.
[`stats::rexp()`](https://rdrr.io/r/stats/Exponential.html)) rather than
setting seeds inside the sampler, otherwise reproducibility guarantees
of
[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)
are lost.

## See also

[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md),
[`sample_reward()`](https://rprodigest.github.io/banditlab/reference/sample_reward.md)

## Examples

``` r
env <- bandit_custom(
  sampler = function(arm) rexp(1, rate = if (arm == "fast") 2 else 1),
  arms = c("fast", "slow"),
  expected_rewards = c(fast = 0.5, slow = 1)
)
env
#> <custom_environment> 2 arms: fast, slow
#> expected rewards:
#> fast slow 
#>  0.5  1.0 
#> optimal arm(s): slow
```
