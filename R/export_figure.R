#' Export ggplot2 Figures with Consistent Formatting
#'
#' This function provides a standardized way to export ggplot2 figures with
#' consistent dimensions, resolution, and formatting options suitable for
#' ARPC publications and presentations. Automatically exports PNG, PDF, and EPS versions.
#'
#' @param plot A ggplot2 plot object to export
#' @param filename Character string specifying the base filename (without extension)
#' @param path Character string specifying the directory path (default: current directory)
#' @param width Numeric value for plot width in inches (default: 8)
#' @param height Numeric value for plot height in inches (default: 6)
#' @param dpi Numeric value for resolution in dots per inch (default: 300)
#' @param bg Background color (default: "white")
#' @param plot_data Optional data.frame to export as CSV file alongside the figures
#' @param device_args Named list of additional arguments to pass to the graphics device
#'
#' @return Invisibly returns a list of full paths to all saved files
#' @export
#' @importFrom utils write.csv
#' @import ggplot2
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   theme_arpc()
#' 
#' # Export all formats with default settings
#' export_arpc(p, "my_plot")
#' 
#' # Export with custom dimensions and include data
#' export_arpc(p, "my_plot", width = 10, height = 8, plot_data = mtcars)
export_arpc <- function(plot,
                        filename,
                        path = ".",
                        width = 8,
                        height = 6,
                        dpi = 300,
                        bg = "white",
                        plot_data = NULL,
                        device_args = list()) {
  
  # Input validation
  if (!inherits(plot, "ggplot")) {
    stop("plot must be a ggplot2 object")
  }
  
  if (missing(filename)) {
    stop("filename is required")
  }
  
  # Construct directory path
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  
  # Apply CMR font to the plot
  cmr_font <- get_computer_modern_font()
  plot_with_font <- plot + theme(text = element_text(family = cmr_font))
  
  # Define formats to export
  formats <- c("png", "pdf", "eps")
  exported_files <- character(0)
  
  # Export each format using ggsave
  for (format in formats) {
    full_filename <- file.path(path, paste0(filename, ".", format))
    
    # Set up ggsave arguments
    ggsave_args <- list(
      filename = full_filename,
      plot = plot_with_font,
      width = width,
      height = height,
      units = "in",
      bg = bg
    )
    
    # Add format-specific arguments
    if (format == "png") {
      ggsave_args$dpi <- dpi
    } else if (format == "eps") {
      ggsave_args$device <- "eps"
    }
    
    # Merge with user-specified device arguments
    final_args <- modifyList(ggsave_args, device_args)
    
    # Save using ggsave
    do.call(ggsave, final_args)
    
    # Add to exported files list
    exported_files <- c(exported_files, full_filename)
    
    # Print progress message
    message("Exported: ", basename(full_filename))
  }
  
  # Export plot data if provided
  if (!is.null(plot_data)) {
    if (!is.data.frame(plot_data)) {
      stop("plot_data must be a data.frame")
    }
    
    csv_filename <- file.path(path, paste0(filename, ".csv"))
    write.csv(plot_data, csv_filename, row.names = FALSE)
    exported_files <- c(exported_files, csv_filename)
    message("Exported: ", basename(csv_filename))
  }
  
  # Return all exported file paths invisibly
  invisible(exported_files)
}