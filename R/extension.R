#' The policy extension interface
#'
#' @description
#' A banditlab policy is an ordinary S3 object with class
#' `c("<your_class>", "bandit_policy")` and methods for three generics.
#' The experiment engine drives every policy, built-in or user-defined,
#' through this exact lifecycle:
#'
#' 1. `policy_state(policy, arms)` is called once per replicate to
#'    initialise runtime state. It must return the policy object with any
#'    state fields added. Calling it again must produce a fresh state
#'    (it is also the reset operation).
#' 2. `select_arm(policy, t)` is called at every step `t = 1, 2, ...` and
#'    must return a list with element `arm` (one of the initialised arm
#'    names). Optional elements: `propensity`, the marginal probability
#'    with which the policy selects that arm given its current state
#'    (`NA` if it has no closed form), and `reason`, a short string.
#' 3. `update_state(policy, arm, reward, t)` receives the selected arm
#'    and observed reward and must return the updated policy object.
#'
#' Methods must not set random seeds and must not depend on global
#' mutable state; all randomness must come from the current RNG so that
#' the engine's reproducibility guarantees hold.
#'
#' One practical note on S3 dispatch: methods defined at the top level of
#' a script or inside a package are found automatically. Methods defined
#' inside other evaluation environments (for example testthat tests or
#' knitr chunks) are invisible to the engine unless registered:
#'
#' ```r
#' registerS3method("policy_state", "my_policy", policy_state.my_policy)
#' registerS3method("select_arm", "my_policy", select_arm.my_policy)
#' registerS3method("update_state", "my_policy", update_state.my_policy)
#' ```
#'
#' See `vignette("custom-policies", package = "banditlab")` for a worked
#' implementation of a softmax policy using only this interface.
#'
#' @param policy A `bandit_policy` object.
#' @param arms Character vector of arm names supplied by the environment.
#' @param t The current time step, starting at 1.
#' @param arm The selected arm name.
#' @param reward The observed numeric reward.
#' @param ... Reserved for future methods.
#'
#' @return
#' `policy_state()` and `update_state()` return the (initialised or
#' updated) policy object. `select_arm()` returns a list with elements
#' `arm` and optionally `propensity` and `reason`.
#'
#' @examples
#' # A minimal custom policy: always play the first arm.
#' policy_first <- function() {
#'   structure(list(), class = c("first_policy", "bandit_policy"))
#' }
#' policy_state.first_policy <- function(policy, arms, ...) {
#'   policy$arms <- arms
#'   policy
#' }
#' select_arm.first_policy <- function(policy, t, ...) {
#'   list(arm = policy$arms[[1]], propensity = 1, reason = "fixed")
#' }
#' update_state.first_policy <- function(policy, arm, reward, t, ...) {
#'   policy
#' }
#'
#' @name policy_interface
NULL

#' @rdname policy_interface
#' @export
policy_state <- function(policy, arms, ...) {
  UseMethod("policy_state")
}

#' @rdname policy_interface
#' @export
select_arm <- function(policy, t, ...) {
  UseMethod("select_arm")
}

#' @rdname policy_interface
#' @export
update_state <- function(policy, arm, reward, t, ...) {
  UseMethod("update_state")
}

#' @export
print.bandit_policy <- function(x, ...) {
  config <- x[!vapply(x, is.function, logical(1))]
  config <- config[setdiff(
    names(config),
    c("arms", "pulls", "reward_sum", "alpha", "beta", "committed")
  )]
  cat(sprintf("<bandit policy: %s>\n", class(x)[1]))
  if (length(config)) {
    for (nm in names(config)) {
      cat(sprintf(
        "  %s: %s\n", nm,
        paste(format(config[[nm]]), collapse = ", ")
      ))
    }
  }
  invisible(x)
}
