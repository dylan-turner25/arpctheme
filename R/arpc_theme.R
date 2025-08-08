#' ARPC ggplot2 Theme with NDSU Colors
#'
#' A clean, minimal ggplot2 theme designed for ARPC data visualizations.
#' This theme provides consistent styling with professional appearance and
#' automatically applies NDSU brand colors to plots.
#'
#' @param base_size Base font size (default: 11)
#' @param base_family Base font family (default: "cmr")
#' @param base_line_size Base line size (default: base_size/22)
#' @param base_rect_size Base rectangle size (default: base_size/22)
#'
#' @return A list of ggplot2 components including theme styling and NDSU color scales
#' @export
#' @import ggplot2
#'
#' @examples
#' library(ggplot2)
#' # Basic theme with automatic NDSU colors
#' ggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +
#'   geom_point() +
#'   theme_arpc()
#'   
#' # Theme with logo and NDSU colors
#' ggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +
#'   geom_point() +
#'   theme_arpc() +
#'   logo()
#'   
#' # Override colors if needed
#' ggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +
#'   geom_point() +
#'   theme_arpc() +
#'   scale_color_manual(values = c("red", "blue", "green"))
theme_arpc <- function(base_size = 11, 
                       base_family = "cmr",
                       base_line_size = base_size / 22,
                       base_rect_size = base_size / 22) {
  
  # Create the base theme
  base_theme <- theme_minimal(base_size = base_size,
                             base_family = base_family,
                             base_line_size = base_line_size,
                             base_rect_size = base_rect_size) +
    theme(
      # Plot title and subtitle
      plot.title = element_text(
        size = rel(1.2),
        hjust = 0,
        margin = margin(b = base_size / 2)
      ),
      plot.subtitle = element_text(
        size = rel(0.9),
        hjust = 0,
        color = "grey50",
        margin = margin(b = base_size)
      ),
      
      # Axis titles
      axis.title = element_text(size = rel(0.9), color = "grey30"),
      axis.title.x = element_text(margin = margin(t = base_size / 2)),
      axis.title.y = element_text(margin = margin(r = base_size / 2)),
      
      # Axis text
      axis.text = element_text(size = rel(0.8), color = "grey40"),
      
      # Legend
      legend.title = element_text(size = rel(0.9), color = "grey30"),
      legend.text = element_text(size = rel(0.8), color = "grey40"),
      legend.position = "bottom",
      legend.margin = margin(t = base_size),
      
      # Panel
      panel.grid.major = element_line(color = "grey90", size = rel(0.5)),
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      
      # Strip (for facets)
      strip.text = element_text(
        size = rel(0.9),
        color = "grey30",
        margin = margin(base_size / 2, base_size / 2, base_size / 2, base_size / 2)
      ),
      strip.background = element_rect(fill = "grey95", color = NA),
      
      # Plot margins
      plot.margin = margin(base_size, base_size, base_size, base_size)
    )
  
  # Return list with theme and NDSU color scales
  list(
    base_theme,
    scale_color_ndsu(),
    scale_fill_ndsu()
  )
}