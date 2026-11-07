# Create a Gaussian bandit environment

Each arm returns a draw from its own normal distribution. Expected
rewards are known, so all regret metrics are available.

## Usage

``` r
bandit_gaussian(means, sds = 1)
```

## Arguments

- means:

  Numeric vector of arm means. Names, if present, are used as arm names;
  otherwise arms are named `arm_1`, `arm_2`, ...

- sds:

  Standard deviations, recycled to the number of arms. Must be positive.
  Default 1.

## Value

A `bandit_environment` object.

## See also

[`bandit_bernoulli()`](https://rprodigest.github.io/banditlab/reference/bandit_bernoulli.md),
[`bandit_custom()`](https://rprodigest.github.io/banditlab/reference/bandit_custom.md),
[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)

## Examples

``` r
env <- bandit_gaussian(means = c(0.0, 0.5), sds = c(1, 2))
env
#> <gaussian_environment> 2 arms: arm_1, arm_2
#> expected rewards:
#> arm_1 arm_2 
#>   0.0   0.5 
#> optimal arm(s): arm_2
```
