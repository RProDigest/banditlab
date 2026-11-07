# Internal RNG management.
#
# Design (documented for users in ?run_experiment):
# - One user-facing seed produces one L'Ecuyer-CMRG stream per replicate
#   via parallel::nextRNGStream(). Replicate r is identical whether run
#   alone, in any subset, or with any future parallel backend.
# - Every policy runs replicate r from the same stream start, so policy
#   comparisons are seed-paired by construction.
# - The caller's RNG state (including RNG kind) is restored on exit.
# - No set.seed() exists anywhere below this file.

get_random_seed <- function() {
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
    get(".Random.seed", envir = globalenv(), inherits = FALSE)
  } else {
    NULL
  }
}

set_random_seed <- function(state) {
  assign(".Random.seed", state, envir = globalenv())
}

restore_random_seed <- function(state) {
  if (is.null(state)) {
    if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  } else {
    set_random_seed(state)
  }
}

# Derive n independent L'Ecuyer-CMRG stream states from one seed.
# Leaves the global RNG in an arbitrary state; callers are responsible
# for saving and restoring around this.
derive_streams <- function(seed, n) {
  set.seed(seed, kind = "L'Ecuyer-CMRG")
  state <- get_random_seed()
  streams <- vector("list", n)
  for (i in seq_len(n)) {
    state <- parallel::nextRNGStream(state)
    streams[[i]] <- state
  }
  streams
}
