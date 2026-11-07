# Palette derivation (documented here, not eyeballed): start from the
# published Okabe-Ito categorical set (Okabe & Ito, 2008), then apply
# two corrections needed for it to work as a set of ggplot2 line/point
# colours on a white panel:
#
#   1. Black is dropped from the rotation entirely and reserved as ink
#      (axis text, titles) rather than a data colour. Okabe-Ito's own
#      black was intended as a reference/text colour, not a series hue,
#      and a colour with zero chroma reads as gray, not as an identity.
#   2. The Okabe-Ito yellow (#F0E442) is too light to read reliably as a
#      2px line or point outline against white; it is deepened to
#      #CCB300, a golden-yellow that keeps the same hue family. This is
#      the one hex value in the set that is not a literal Okabe-Ito
#      value.
#
# The resulting 7-hue, fixed-order set was checked programmatically
# (lightness band, chroma floor, CVD separation under simulated
# protanopia/deuteranopia, a normal-vision separation floor, and
# contrast against a white surface) rather than chosen by eye. All
# checks pass for the first four slots, which covers the common case of
# comparing two to five policies; the full seven-slot set passes every
# check except contrast, which sits in the 2.0-3.0:1 range for four of
# the seven hues on a pure white background. That is mitigated by
# secondary encoding rather than by weakening the colours further:
# every plot also varies linetype (line plots) or bar position and axis
# placement (bar plots), so identity is never colour alone, and
# `as_tibble()` on the same result gives exact values without reading
# them off the chart.
#
# The order is fixed and never cycled: series are assigned hues 1..7 in
# this sequence. An eighth policy in one experiment is not supported by
# a distinct hue; compare in two experiments or subset first.
okabe_ito_ordered <- c(
  "#E69F00", # orange
  "#56B4E9", # sky blue
  "#009E73", # bluish green
  "#0072B2", # blue
  "#D55E00", # vermillion
  "#CC79A7", # reddish purple
  "#CCB300"  # deepened yellow (Okabe-Ito yellow, darkened for contrast)
)

#' banditlab plot theme
#'
#' The default theme applied by [autoplot.bandit_result()]. Built on
#' [ggplot2::theme_minimal()] with a typographic hierarchy (a bold
#' title, a muted subtitle, restrained axis text) and reduced grid
#' clutter, so a plot reads clearly at report or slide size without
#' extra styling calls.
#'
#' No custom font family is set: fonts available at render time vary
#' across operating systems, and requiring one would add a dependency
#' and a portability risk out of proportion to the benefit. The theme
#' improves hierarchy (size and weight relationships between title,
#' subtitle, axis titles and axis text) and spacing instead, which is
#' portable everywhere R renders a plot.
#'
#' Like every ggplot2 theme, this one is a starting point: add
#' `+ ggplot2::theme(...)` afterwards to override any element, or
#' replace it entirely with `+ ggplot2::theme_bw()` or your own theme.
#'
#' @param base_size Base font size in points, as in
#'   [ggplot2::theme_minimal()].
#'
#' @return A ggplot2 theme object.
#'
#' @examples
#' env <- bandit_bernoulli(c(a = 0.2, b = 0.5))
#' result <- run_experiment(env, policy_ucb1(), horizon = 200, seed = 1,
#'                          checkpoints = c(100, 200))
#' autoplot(result) + theme_banditlab(base_size = 14)
#'
#' @seealso [autoplot.bandit_result()], [scale_colour_banditlab()]
#' @export
theme_banditlab <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold", size = ggplot2::rel(1.15),
        margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = "grey35", size = ggplot2::rel(0.85),
        margin = ggplot2::margin(b = 10)
      ),
      axis.title = ggplot2::element_text(size = ggplot2::rel(0.95)),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 8)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 8)),
      axis.text = ggplot2::element_text(colour = "grey30"),
      legend.title = ggplot2::element_text(
        face = "bold", size = ggplot2::rel(0.9)
      ),
      legend.text = ggplot2::element_text(size = ggplot2::rel(0.85)),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(
        colour = "grey90", linewidth = 0.4
      ),
      plot.margin = ggplot2::margin(t = 10, r = 14, b = 8, l = 8)
    )
}

#' Okabe-Ito-based discrete colour and fill scales
#'
#' The fixed-order, accessibility-checked 7-hue palette used by
#' [autoplot.bandit_result()]. Exported so that plots you build directly
#' from `as_tibble()` output can match the package's default figures.
#'
#' @param ... Passed to [ggplot2::discrete_scale()].
#'
#' @return A ggplot2 discrete scale.
#'
#' @details
#' Derived from Okabe and Ito's colour-blind-safe categorical palette,
#' with two changes: black is not included (reserved as text/ink, never
#' a data colour), and the yellow is deepened from `#F0E442` to
#' `#CCB300` so it remains legible as a line or point colour on a white
#' background. See the package source (`R/theme.R`) for the full
#' rationale. The scale supports up to seven series in a fixed hue
#' order; a series never changes colour when other series are added or
#' removed.
#'
#' @examples
#' library(ggplot2)
#' df <- data.frame(x = 1:6, y = c(1, 3, 2, 4, 3, 5),
#'                  policy = rep(c("a", "b"), 3))
#' ggplot(df, aes(x, y, colour = policy)) +
#'   geom_line() +
#'   scale_colour_banditlab()
#'
#' @seealso [theme_banditlab()], [autoplot.bandit_result()]
#' @export
scale_colour_banditlab <- function(...) {
  banditlab_discrete_scale("colour", ...)
}

#' @rdname scale_colour_banditlab
#' @export
scale_fill_banditlab <- function(...) {
  banditlab_discrete_scale("fill", ...)
}

# Internal: ggplot2 < 3.5.0 requires `scale_name`; 3.5.0 deprecates it.
# Supply it only where it is required so both versions work silently.
banditlab_discrete_scale <- function(aesthetics, ...) {
  args <- list(
    aesthetics = aesthetics,
    palette = function(n) okabe_ito_ordered[seq_len(n)],
    ...
  )
  if (utils::packageVersion("ggplot2") < "3.5.0" && is.null(args$scale_name)) {
    args$scale_name <- "banditlab"
  }
  do.call(ggplot2::discrete_scale, args)
}

#' @rdname scale_colour_banditlab
#' @export
scale_color_banditlab <- scale_colour_banditlab

# Internal: apply the package's colour and fill scales together. Bounds
# checking (at most length(okabe_ito_ordered) series) happens at the
# call site, before this runs, so the error names the plot's series
# count rather than a downstream ggplot2 recycling warning.
add_okabe_ito <- function(p) {
  p +
    scale_colour_banditlab() +
    scale_fill_banditlab()
}
