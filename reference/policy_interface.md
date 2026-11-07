# The policy extension interface

A banditlab policy is an ordinary S3 object with class
`c("<your_class>", "bandit_policy")` and methods for three generics. The
experiment engine drives every policy, built-in or user-defined, through
this exact lifecycle:

1.  `policy_state(policy, arms)` is called once per replicate to
    initialise runtime state. It must return the policy object with any
    state fields added. Calling it again must produce a fresh state (it
    is also the reset operation).

2.  `select_arm(policy, t)` is called at every step `t = 1, 2, ...` and
    must return a list with element `arm` (one of the initialised arm
    names). Optional elements: `propensity`, the marginal probability
    with which the policy selects that arm given its current state (`NA`
    if it has no closed form), and `reason`, a short string.

3.  `update_state(policy, arm, reward, t)` receives the selected arm and
    observed reward and must return the updated policy object.

Methods must not set random seeds and must not depend on global mutable
state; all randomness must come from the current RNG so that the
engine's reproducibility guarantees hold.

One practical note on S3 dispatch: methods defined at the top level of a
script or inside a package are found automatically. Methods defined
inside other evaluation environments (for example testthat tests or
knitr chunks) are invisible to the engine unless registered:

    registerS3method("policy_state", "my_policy", policy_state.my_policy)
    registerS3method("select_arm", "my_policy", select_arm.my_policy)
    registerS3method("update_state", "my_policy", update_state.my_policy)

See
[`vignette("custom-policies", package = "banditlab")`](https://rprodigest.github.io/banditlab/articles/custom-policies.md)
for a worked implementation of a softmax policy using only this
interface.

## Usage

``` r
policy_state(policy, arms, ...)

select_arm(policy, t, ...)

update_state(policy, arm, reward, t, ...)
```

## Arguments

- policy:

  A `bandit_policy` object.

- arms:

  Character vector of arm names supplied by the environment.

- ...:

  Reserved for future methods.

- t:

  The current time step, starting at 1.

- arm:

  The selected arm name.

- reward:

  The observed numeric reward.

## Value

`policy_state()` and `update_state()` return the (initialised or
updated) policy object. `select_arm()` returns a list with elements
`arm` and optionally `propensity` and `reason`.

## Examples

``` r
# A minimal custom policy: always play the first arm.
policy_first <- function() {
  structure(list(), class = c("first_policy", "bandit_policy"))
}
policy_state.first_policy <- function(policy, arms, ...) {
  policy$arms <- arms
  policy
}
select_arm.first_policy <- function(policy, t, ...) {
  list(arm = policy$arms[[1]], propensity = 1, reason = "fixed")
}
update_state.first_policy <- function(policy, arm, reward, t, ...) {
  policy
}
```
