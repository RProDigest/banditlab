# Create a Bernoulli bandit environment

Each arm returns 1 with its own fixed probability and 0 otherwise.
Expected rewards are known, so all regret metrics are available.

## Usage

``` r
bandit_bernoulli(probabilities)
```

## Arguments

- probabilities:

  Numeric vector of success probabilities in `[0, 1]`, one per arm.
  Names, if present, are used as arm names; otherwise arms are named
  `arm_1`, `arm_2`, ...

## Value

A `bandit_environment` object.

## See also

[`bandit_gaussian()`](https://rprodigest.github.io/banditlab/reference/bandit_gaussian.md),
[`bandit_custom()`](https://rprodigest.github.io/banditlab/reference/bandit_custom.md),
[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
env
#> <bernoulli_environment> 2 arms: a, b
#> expected rewards:
#>   a   b 
#> 0.2 0.5 
#> optimal arm(s): b
sample_reward(env, "b")
#> [1] 0
```
