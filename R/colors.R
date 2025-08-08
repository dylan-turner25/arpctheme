#' NDSU Brand Colors
#'
#' A collection of colors from the official NDSU brand palette.
#' These colors are automatically applied when using theme_arpc().
#'
#' @format A named character vector of hex color codes
#' @export
#'
#' @examples
#' ndsu_colors()
#' ndsu_colors("green")
#' ndsu_colors(c("green", "yellow"))
ndsu_colors <- function(names = NULL) {
  
  ndsu_palette <- c(
    # Primary Colors
    green = "#00583d",
    yellow = "#FFC425",
    
    # Secondary Colors  
    dark_green = "#003524",
    lime_green = "#8ED73B",
    teal = "#51ABD0", 
    lemon_yellow = "#F4F287",
    sage = "#8ABD78",
    pale_sage = "#D7E8C8",
    
    # Accent Colors
    rust = "#B83E27",
    morning_sky = "#90DF7",
    night = "#0F374B"
  )
  
  if (is.null(names)) {
    return(ndsu_palette)
  }
  
  if (any(!names %in% names(ndsu_palette))) {
    stop("Color not found. Available colors: ", paste(names(ndsu_palette), collapse = ", "))
  }
  
  ndsu_palette[names]
}

#' NDSU Color Scale for Discrete Variables (Color)
#'
#' Applies NDSU brand colors to discrete color aesthetics.
#' This function is automatically called by theme_arpc().
#'
#' @param palette Character, which NDSU palette to use (default: "primary")
#' @param ... Additional arguments passed to scale_color_manual()
#'
#' @return A ggplot2 color scale
#' @export
#' @import ggplot2
#'
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +
#'   geom_point() +
#'   scale_color_ndsu()
scale_color_ndsu <- function(palette = "primary", ...) {
  
  colors <- switch(palette,
    "primary" = c(
      ndsu_colors("green"),        # 1st priority
      ndsu_colors("yellow"),       # 2nd priority  
      ndsu_colors("rust"),         # 3rd priority
      ndsu_colors("night"),        # 4th priority
      ndsu_colors("teal"),         # Rest in any order
      ndsu_colors("sage"),
      ndsu_colors("dark_green"),
      ndsu_colors("lime_green"),
      ndsu_colors("lemon_yellow"),
      ndsu_colors("pale_sage"),
      ndsu_colors("morning_sky")
    ),
    "greens" = c(
      ndsu_colors("green"),
      ndsu_colors("dark_green"),
      ndsu_colors("sage"),
      ndsu_colors("lime_green"),
      ndsu_colors("pale_sage")
    ),
    "full" = unname(ndsu_colors())
  )
  
  # Remove names to avoid level matching issues
  scale_color_manual(values = unname(colors), ...)
}

#' NDSU Color Scale for Discrete Variables (Fill)
#'
#' Applies NDSU brand colors to discrete fill aesthetics.
#' This function is automatically called by theme_arpc().
#'
#' @param palette Character, which NDSU palette to use (default: "primary")
#' @param ... Additional arguments passed to scale_fill_manual()
#'
#' @return A ggplot2 fill scale
#' @export
#' @import ggplot2
#'
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(x = factor(cyl), fill = factor(cyl))) +
#'   geom_bar() +
#'   scale_fill_ndsu()
scale_fill_ndsu <- function(palette = "primary", ...) {
  
  colors <- switch(palette,
    "primary" = c(
      ndsu_colors("green"),        # 1st priority
      ndsu_colors("yellow"),       # 2nd priority  
      ndsu_colors("rust"),         # 3rd priority
      ndsu_colors("night"),        # 4th priority
      ndsu_colors("teal"),         # Rest in any order
      ndsu_colors("sage"),
      ndsu_colors("dark_green"),
      ndsu_colors("lime_green"),
      ndsu_colors("lemon_yellow"),
      ndsu_colors("pale_sage"),
      ndsu_colors("morning_sky")
    ),
    "greens" = c(
      ndsu_colors("green"),
      ndsu_colors("dark_green"),
      ndsu_colors("sage"),
      ndsu_colors("lime_green"),
      ndsu_colors("pale_sage")
    ),
    "full" = unname(ndsu_colors())
  )
  
  # Remove names to avoid level matching issues
  scale_fill_manual(values = unname(colors), ...)
}