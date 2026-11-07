# Epsilon-greedy policy

With probability `epsilon` selects an arm uniformly at random, otherwise
selects the arm with the highest sample-average estimate (uniform
tie-breaking). The logged propensity is always the marginal selection
probability of the chosen arm, combining both routes to selection, which
makes the resulting logs usable for importance-weighted offline
evaluation.

## Usage

``` r
policy_epsilon_greedy(epsilon = 0.1, initial_value = NULL, schedule = NULL)
```

## Arguments

- epsilon:

  Exploration probability in `[0, 1]`. Ignored at steps where `schedule`
  is supplied.

- initial_value:

  As in
  [`policy_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_greedy.md):
  `NULL` forces one trial of each arm first; a number is used as the
  estimate of untried arms.

- schedule:

  Optional function of the time step `t` returning the exploration
  probability at that step, for decaying schedules.

## Value

A `bandit_policy` object.

## See also

[`policy_greedy()`](https://rprodigest.github.io/banditlab/reference/policy_greedy.md),
[`policy_ucb1()`](https://rprodigest.github.io/banditlab/reference/policy_ucb1.md),
[`policy_thompson()`](https://rprodigest.github.io/banditlab/reference/policy_thompson.md)

## Examples

``` r
env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
run_experiment(env, policy_epsilon_greedy(0.1), horizon = 200, seed = 1)
#> <bandit_result> 1 policy x 1 replicate x horizon 200 (seed 1)
#> environment: bernoulli_environment (2 arms)
#> stored: summary
#> # A tibble: 1 × 8
#>   policy          replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>                  <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 epsilon_greedy…            1        24.3          24.3        24.3        24.3
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>

# A decaying schedule.
pol <- policy_epsilon_greedy(schedule = function(t) min(1, 5 / t))
run_experiment(env, pol, horizon = 200, seed = 1)
#> <bandit_result> 1 policy x 1 replicate x horizon 200 (seed 1)
#> environment: bernoulli_environment (2 arms)
#> stored: summary
#> # A tibble: 1 × 8
#>   policy          replications mean_regret median_regret regret_q025 regret_q975
#> * <chr>                  <int>       <dbl>         <dbl>       <dbl>       <dbl>
#> 1 epsilon_greedy…            1           3             3           3           3
#> # ℹ 2 more variables: mean_reward <dbl>, mean_optimal_share <dbl>
```
