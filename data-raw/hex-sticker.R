# banditlab hex sticker, drawn with ggplot2 only.
# Motif: Thompson-sampling posteriors for three arms. Two broad,
# uncertain posteriors and one sharp posterior that has "won" -- the
# exploration-to-exploitation story the package is about.
library(ggplot2)

# Usage (from the package root):
#   Rscript data-raw/hex-sticker.R man/figures/logo.png 300     # web / pkgdown
#   Rscript data-raw/hex-sticker.R banditlab-hex-print.png 1200 # printing
# Needs ggplot2, ragg and the Inter font installed.
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[[1]] else "man/figures/logo.png"
dpi <- if (length(args) > 1) as.numeric(args[[2]]) else 300

# Package palette (R/theme.R), so the sticker matches the plots
orange <- "#E69F00"; sky <- "#56B4E9"; green <- "#009E73"
navy <- "#0B1F3A"; ink <- "#F4F6FA"

# Pointy-top hexagon, circumradius 1
hexagon <- function(r = 1) {
  a <- (90 + 60 * 0:5) * pi / 180
  data.frame(x = r * cos(a), y = r * sin(a))
}

# Posterior curves mapped into the sticker's upper half
posterior <- function(a, b, arm, x0 = -0.62, x1 = 0.62, y0 = -0.02, h = 0.56) {
  p <- seq(0.001, 0.999, length.out = 400)
  d <- dbeta(p, a, b)
  data.frame(arm = arm, x = x0 + p * (x1 - x0), ymin = y0, y = d)
}
curves <- rbind(
  posterior(3, 9, "a"),
  posterior(7, 7, "b"),
  posterior(46, 14, "c")
)
peak <- max(curves$y)
curves$y <- -0.02 + curves$y / peak * 0.56
curves <- curves[curves$y > -0.015, ]   # drop flat tails so curves don't pile onto the baseline
best_x <- -0.62 + (46 / 60) * 1.24  # posterior mean of the winning arm

# "Pull" ticks along the baseline: most pulls land on the winning arm
set.seed(7)
pulls <- data.frame(
  x = c(rnorm(5, -0.62 + 0.25 * 1.24, 0.07),
        rnorm(6, -0.62 + 0.50 * 1.24, 0.07),
        rnorm(18, best_x, 0.035)),
  arm = rep(c("a", "b", "c"), c(5, 6, 18))
)
pulls <- pulls[abs(pulls$x) < 0.6, ]

cols <- c(a = sky, b = green, c = orange)

p <- ggplot() +
  geom_polygon(data = hexagon(0.97), aes(x, y), fill = navy, colour = NA) +
  # baseline
  annotate("segment", x = -0.64, xend = 0.64, y = -0.02, yend = -0.02,
           colour = ink, alpha = 0.35, linewidth = 0.25) +
  geom_ribbon(data = curves, aes(x, ymin = ymin, ymax = y, fill = arm),
              alpha = 0.22) +
  geom_line(data = curves, aes(x, y, colour = arm), linewidth = 0.5,
            lineend = "round") +
  # pulls
  geom_segment(data = pulls, aes(x = x, xend = x, y = -0.07, yend = -0.035,
                                 colour = arm), linewidth = 0.3, alpha = 0.9) +
  # optimal-arm marker
  annotate("segment", x = best_x, xend = best_x, y = -0.02, yend = 0.585,
           colour = orange, linewidth = 0.25, linetype = "22") +
  annotate("point", x = best_x, y = 0.6, colour = orange, size = 1.1) +
  # name
  annotate("text", x = 0, y = -0.33, label = "banditlab", colour = ink,
           family = "Inter", fontface = "bold", size = 17.5 / .pt) +
  annotate("text", x = 0, y = -0.525, label = "explore  \u2022  exploit  \u2022  compare",
           colour = sky, family = "Inter", size = 5.6 / .pt) +
  # URL along the lower-right edge
  annotate("text", x = 0.392, y = -0.672, label = "rprodigest.github.io/banditlab",
           angle = 30, colour = ink, alpha = 0.7, family = "Inter",
           size = 3.4 / .pt) +
  # border drawn last so it sits on top
  geom_polygon(data = hexagon(0.97), aes(x, y), fill = NA,
               colour = sky, linewidth = 1.1, linejoin = "mitre") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = "none") +
  coord_fixed(xlim = c(-sqrt(3) / 2, sqrt(3) / 2), ylim = c(-1, 1),
              expand = FALSE) +
  theme_void() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA),
        panel.background = element_rect(fill = "transparent", colour = NA),
        plot.margin = margin(0, 0, 0, 0))

# Standard hex sticker: 43.9 mm x 50.8 mm
w_in <- 43.9 / 25.4; h_in <- 50.8 / 25.4
ragg::agg_png(out, width = w_in, height = h_in, units = "in", res = dpi,
              background = "transparent")
print(p)
invisible(dev.off())
