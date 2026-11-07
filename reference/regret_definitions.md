# Regret definitions used by banditlab

The package uses these exact definitions. Let \\\mu_a\\ be the true
expected reward of arm \\a\\, \\\mu^\* = \max_a \mu_a\\, and \\A_t\\ the
arm selected at step \\t\\.

- **Instantaneous pseudo-regret** at step t: \\\Delta\_{A_t} = \mu^\* -
  \mu\_{A_t}\\. Recorded per decision in trajectories.

- **Cumulative pseudo-regret** after T steps: \\R_T = \sum\_{t=1}^{T}
  (\mu^\* - \mu\_{A_t})\\. Recorded at checkpoints and, at the final
  step, in the summary.

- **Expected regret**: the Monte Carlo mean of final cumulative
  pseudo-regret across replicates, reported by
  [`summary.bandit_result()`](https://rprodigest.github.io/banditlab/reference/summary.bandit_result.md).

- **Optimal action share**: the fraction of steps at which a selected
  arm attains \\\mu^\*\\.

- **Realised regret** (comparing observed rewards against counterfactual
  draws from the optimal arm) is **not** computed in this version.

All quantities require known expected rewards. Environments that do not
declare them (a
[`bandit_custom()`](https://rprodigest.github.io/banditlab/reference/bandit_custom.md)
without `expected_rewards`) yield `NA` for every regret metric; no
baseline is invented.
