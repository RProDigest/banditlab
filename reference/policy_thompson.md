# Beta-Bernoulli Thompson sampling policy

Maintains an independent Beta posterior for each arm's success
probability, draws one sample from every posterior at each step and
selects the arm with the largest draw. Rewards must be 0 or 1; the
update adds the reward to the arm's `alpha` and `1 - reward` to its
`beta`.

## Usage

``` r
policy_thompson(alpha = 1, beta = 1)
```

## Arguments

- alpha, beta:

  Positive prior shape parameters, recycled across arms. The default
  `Beta(1, 1)` prior is uniform.

## Value

A `bandit_policy` object.

## Details

The logged propensity is `NA`: the marginal selection probability of
Thompson sampling is the posterior probability that the arm's draw is
the maximum, which has no simple closed form. Logging `NA` is honest;
estimating it by simulation is possible but consumes additional random
numbers and is not done here.

## References

Thompson, W. R. (1933). On the likelihood that one unknown probability
exceeds another in view of the evidence of two samples. Biometrika
25(3-4), 285-294. [doi:10.2307/2332286](https://doi.org/10.2307/2332286)

Russo, D. J., Van Roy, B., Kazerouni, A., Osband, I., Wen, Z. (2018). A
tutorial on Thompson sampling. Foundations and Trends in Machine
Learning 11(1), 1-96.
[doi:10.1561/2200000070](https://doi.org/10.1561/2200000070)

## See also

[`policy_ucb1()`](https://rprodigest.github.io/banditlab/reference/policy_ucb1.md),
[`run_experiment()`](https://rprodigest.github.io/banditlab/reference/run_experiment.md)

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
run_experiment(env, policy_thompson(), horizon = 500, seed = 1)
#> <bandit_result> 1 policy x 1 replicate x horizon 500 (seed 1)
#> environment: bernoulli_environment (2 arms)
#> stored: summary
#> # A tibble: 1 × 8
#>   policy          replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>                  <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 thompson_policy            1         7.8           7.8         7.8         7.8
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
```
