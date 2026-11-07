# UCB1 policy

The upper confidence bound policy of Auer, Cesa-Bianchi and Fischer
(2002). After one initial pull of each arm, it selects the arm
maximising \$\$\hat{\mu}\_a + \sqrt{2 \log t / n_a},\$\$ where
\\\hat{\mu}\_a\\ is the sample-average reward of arm \\a\\, \\n_a\\ its
pull count and \\t\\ the current step. Ties are broken uniformly at
random.

## Usage

``` r
policy_ucb1()
```

## Value

A `bandit_policy` object.

## Details

The classical regret analysis assumes rewards bounded in `[0, 1]` and a
stationary environment; the implementation accepts any numeric rewards
but the theoretical guarantee does not transfer automatically.

## References

Auer, P., Cesa-Bianchi, N., Fischer, P. (2002). Finite-time analysis of
the multiarmed bandit problem. Machine Learning 47(2-3), 235-256.
[doi:10.1023/A:1013689704352](https://doi.org/10.1023/A%3A1013689704352)

## See also

[`policy_thompson()`](https://rprodigest.github.io/banditlab/reference/policy_thompson.md),
[`policy_epsilon_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_epsilon_greedy.md)

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
run_experiment(env, policy_ucb1(), horizon = 500, seed = 1)
#> <bandit_result> 1 policy x 1 replicate x horizon 500 (seed 1)
#> environment: bernoulli_environment (2 arms)
#> stored: summary
#> # A tibble: 1 × 8
#>   policy      replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>              <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 ucb1_policy            1        17.4          17.4        17.4        17.4
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
```
