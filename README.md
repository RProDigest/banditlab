# banditlab <img src="man/figures/logo.png" align="right" height="139" alt="banditlab hex logo" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/RProDigest/banditlab/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/RProDigest/banditlab/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/banditlab)](https://CRAN.R-project.org/package=banditlab)
[![pkgdown](https://img.shields.io/badge/docs-pkgdown-blue)](https://rprodigest.github.io/banditlab/)
<!-- badges: end -->

banditlab is an R framework for multi-armed bandit experimentation:
simulating, comparing and extending sequential decision algorithms.

It provides:

- **Environments**: Bernoulli, Gaussian, and arbitrary user-defined
  reward processes.
- **Policies**: random, greedy (with optimistic initial values),
  epsilon-greedy (fixed and scheduled), explore-then-commit, UCB1 and
  Beta-Bernoulli Thompson sampling.
- **One experiment engine**: replicated runs, one independent random
  number stream per replicate (results do not depend on how many
  replicates you run), and seed-paired policy comparisons by
  construction.
- **Explicit metrics**: pseudo-regret with exact documented definitions
  (`?regret_definitions`), never computed when the environment cannot
  support them.
- **Tidy results**: summaries, checkpoints and full trajectories as
  tibbles, sized deliberately (trajectories are opt-in).
- **Propensity-complete logs**: every built-in stochastic policy logs
  the marginal probability of each selected action, the prerequisite
  for importance-weighted offline evaluation.
- **A small extension API**: implement three S3 methods and your policy
  runs in the same engine as the built-ins
  (`vignette("custom-policies")`).

## Why it exists

The only general bandit framework R has had, `contextual`, was archived
from CRAN in 2021. What remains covers Bayesian A/B analysis and
clinical trial designs, not general bandit experimentation. banditlab
fills that gap with a deliberately small, tested, dependency-light core
(tibble and ggplot2 are the only non-base imports).

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("RProDigest/banditlab")
```

Once released on CRAN:

```r
install.packages("banditlab")
```

## In 60 seconds

```r
library(banditlab)

env <- bandit_bernoulli(c(low = 0.15, mid = 0.25, high = 0.40))

result <- run_experiment(
  env,
  policies = list(
    epsilon  = policy_epsilon_greedy(0.1),
    ucb      = policy_ucb1(),
    thompson = policy_thompson()
  ),
  horizon = 1000,
  replications = 50,
  seed = 42,
  checkpoints = seq(50, 1000, by = 50)
)

summary(result)
#> one row per policy: mean and quantiles of final cumulative regret,
#> mean reward, mean optimal-action share

autoplot(result, metric = "cumulative_regret")
```

Seed-paired comparison against a baseline:

```r
cmp <- compare_policies(result, baseline = "epsilon")
aggregate(difference ~ policy, data = cmp, FUN = mean)
```

## Telecoms case study

The article [Bandits for RAN optimisation: 5G NR link adaptation](https://rprodigest.github.io/banditlab/articles/nr-link-adaptation.html)
uses banditlab to compare bandit policies with a static CQI rule and
outer-loop link adaptation (OLLA) in simulated stationary and drifting
radio conditions. It builds both industry baselines with the extension
API, without modifying the package.

## Extending

A custom policy is a constructor plus three S3 methods
(`policy_state()`, `select_arm()`, `update_state()`). The vignette
`vignette("custom-policies")` implements softmax exploration from
scratch and runs it against the built-in policies; the package's own
test suite runs a policy implemented this way to guarantee the
extension interface keeps working.

## Relationship to the book

banditlab is the computational companion of the book in progress
*Adaptive Bandit Methods with R*, which teaches the algorithms by
building transparent implementations before introducing the package.
The package is designed to stand alone: nothing in its documentation
requires the book.

## Development status

Version 0.1.0. The public API described in the reference and vignettes
is intended to be stable; the extension generics (`policy_state()`,
`select_arm()`, `update_state()`) are the package's compatibility
contract. Planned directions (non-stationary environments, contextual
policies, offline evaluation) are listed in the repository's roadmap.

## License

MIT.
