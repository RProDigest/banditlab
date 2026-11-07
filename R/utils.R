# Internal helpers. None of these are exported.

# Stop with a formatted message and no call in the condition.
abort_bad <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

check_scalar_number <- function(x, name, min = -Inf, max = Inf) {
  if (!is.numeric(x) || length(x) != 1 || !is.finite(x) || x < min || x > max) {
    abort_bad(
      "`%s` must be a single finite number in [%s, %s].",
      name, format(min), format(max)
    )
  }
  x
}

check_count <- function(x, name, min = 1) {
  check_scalar_number(x, name, min = min)
  if (x != as.integer(x)) {
    abort_bad("`%s` must be a whole number.", name)
  }
  as.integer(x)
}

check_arm_names <- function(arms) {
  if (!is.character(arms) || length(arms) < 2 || anyDuplicated(arms) ||
      any(is.na(arms)) || any(!nzchar(arms))) {
    abort_bad("arms must be at least two unique, non-empty character names.")
  }
  arms
}

default_arm_names <- function(n) {
  sprintf("arm_%d", seq_len(n))
}

# Uniform tie-breaking over the maximising positions of a numeric vector.
# Returns a single index. sample() on a length-one integer vector would
# sample from 1:x, so indices are drawn from the candidate set explicitly.
argmax_random <- function(x) {
  candidates <- which(x == max(x))
  if (length(candidates) == 1L) {
    return(candidates)
  }
  candidates[[sample.int(length(candidates), 1L)]]
}

# The set of maximising positions.
argmax_set <- function(x) {
  which(x == max(x))
}
