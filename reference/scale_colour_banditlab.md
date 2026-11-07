# Okabe-Ito-based discrete colour and fill scales

The fixed-order, accessibility-checked 7-hue palette used by
[`autoplot.bandit_result()`](https://rprodigest.github.io/banditlab/reference/autoplot.bandit_result.md).
Exported so that plots you build directly from
[`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
output can match the package's default figures.

## Usage

``` r
scale_colour_banditlab(...)

scale_fill_banditlab(...)

scale_color_banditlab(...)
```

## Arguments

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Value

A ggplot2 discrete scale.

## Details

Derived from Okabe and Ito's colour-blind-safe categorical palette, with
two changes: black is not included (reserved as text/ink, never a data
colour), and the yellow is deepened from `#F0E442` to `#CCB300` so it
remains legible as a line or point colour on a white background. See the
package source (`R/theme.R`) for the full rationale. The scale supports
up to seven series in a fixed hue order; a series never changes colour
when other series are added or removed.

## See also

[`theme_banditlab()`](https://rprodigest.github.io/banditlab/reference/theme_banditlab.md),
[`autoplot.bandit_result()`](https://rprodigest.github.io/banditlab/reference/autoplot.bandit_result.md)

## Examples

``` r
library(ggplot2)
df <- data.frame(x = 1:6, y = c(1, 3, 2, 4, 3, 5),
                 policy = rep(c("a", "b"), 3))
ggplot(df, aes(x, y, colour = policy)) +
  geom_line() +
  scale_colour_banditlab()

```
