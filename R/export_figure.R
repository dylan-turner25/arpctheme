#' Export ggplot2 Figures with Consistent Formatting
#'
#' This function provides a standardized way to export ggplot2 figures with
#' consistent dimensions, resolution, and formatting options suitable for
#' ARPC publications and presentations.
#'
#' @param plot A ggplot2 plot object to export
#' @param filename Character string specifying the output filename (without extension)
#' @param path Character string specifying the directory path (default: current directory)
#' @param format Character string specifying output format: "png", "pdf", "svg", or "eps" (default: "png")
#' @param width Numeric value for plot width in inches (default: 8)
#' @param height Numeric value for plot height in inches (default: 6)
#' @param dpi Numeric value for resolution in dots per inch (default: 300)
#' @param units Character string for units: "in", "cm", or "mm" (default: "in")
#' @param bg Background color (default: "white")
#' @param device_args Named list of additional arguments to pass to the graphics device
#'
#' @return Invisibly returns the full path to the saved file
#' @export
#' @importFrom grDevices dev.off pdf png svg
#' @import ggplot2
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   theme_arpc()
#' 
#' # Export as PNG with default settings
#' export_arpc(p, "my_plot")
#' 
#' # Export as PDF with custom dimensions
#' export_arpc(p, "my_plot", format = "pdf", width = 10, height = 8)
export_arpc <- function(plot,
                        filename,
                        path = ".",
                        format = c("png", "pdf", "svg", "eps"),
                        width = 8,
                        height = 6,
                        dpi = 300,
                        units = "in",
                        bg = "white",
                        device_args = list()) {
  
  # Input validation
  if (!inherits(plot, "ggplot")) {
    stop("plot must be a ggplot2 object")
  }
  
  if (missing(filename)) {
    stop("filename is required")
  }
  
  format <- match.arg(format)
  
  # Construct full file path
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  
  full_filename <- file.path(path, paste0(filename, ".", format))
  
  # Set up device-specific arguments
  base_args <- list(
    filename = full_filename,
    width = width,
    height = height,
    bg = bg
  )
  
  # Add format-specific arguments
  if (format %in% c("png", "svg")) {
    base_args$units <- units
    if (format == "png") {
      base_args$res <- dpi
    }
  }
  
  # Merge with user-specified device arguments
  final_args <- modifyList(base_args, device_args)
  
  # Open graphics device
  if (format == "png") {
    do.call(png, final_args)
  } else if (format == "pdf") {
    do.call(pdf, final_args)
  } else if (format == "svg") {
    do.call(svg, final_args)
  } else if (format == "eps") {
    # EPS requires postscript device
    final_args$file <- final_args$filename
    final_args$filename <- NULL
    final_args$onefile <- FALSE
    final_args$horizontal <- FALSE
    final_args$paper <- "special"
    do.call(postscript, final_args)
  }
  
  # Print the plot
  print(plot)
  
  # Close the device
  dev.off()
  
  # Return the full path invisibly
  invisible(full_filename)
}