# Draw one reward from an environment

The generic used by the experiment engine to generate rewards. It is
exported so that authors of new environment classes can provide methods;
most users never call it directly.

## Usage

``` r
sample_reward(environment, arm, ...)
```

## Arguments

- environment:

  A `bandit_environment` object.

- arm:

  One arm name belonging to the environment.

- ...:

  Reserved for future methods.

## Value

A single finite numeric reward.

## Examples

``` r
env <- bandit_bernoulli(c(a = 0, b = 1))
sample_reward(env, "b")
#> [1] 1
```
