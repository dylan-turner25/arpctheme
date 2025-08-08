#' Add ARPC Logo to ggplot
#'
#' Adds the ARPC logo to a ggplot object. This function returns a ggplot2 layer
#' that can be added to any ggplot using the + operator.
#'
#' @param position Character, position of logo. Options: "bottom-right", "bottom-left", 
#'   "top-right", "top-left", "bottom", "top", "left", "right" (default: "bottom-right")
#' @param size Numeric, size of logo as proportion of plot area (default: 0.1)
#' @param path Character, path to logo file. If NULL, uses package default logo (default: NULL)
#' @param alpha Numeric, transparency of logo (0 = transparent, 1 = opaque) (default: 0.8)
#'
#' @return A ggplot2 annotation layer that can be added with +
#' @export
#' @import ggplot2
#' @importFrom grid unit rectGrob gpar gTree gList viewport rasterGrob
#' @importFrom magick image_read image_convert image_info
#'
#' @examples
#' library(ggplot2)
#' 
#' # Add logo to bottom-right (default)
#' ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   theme_arpc() +
#'   logo()
#'   
#' # Add logo to top-left corner
#' ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   theme_arpc() +
#'   logo(position = "top-left")
#'   
#' # Customize size and transparency
#' ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   theme_arpc() +
#'   logo(position = "top-right", size = 0.15, alpha = 0.6)
logo <- function(position = "bottom-right", 
                 size = 0.1, 
                 path = NULL, 
                 alpha = 0.8) {
  
  # Validate position
  valid_positions <- c("bottom-right", "bottom-left", "top-right", "top-left", 
                      "bottom", "top", "left", "right")
  if (!position %in% valid_positions) {
    stop("position must be one of: ", paste(valid_positions, collapse = ", "))
  }
  
  # Validate size
  if (!is.numeric(size) || size <= 0 || size > 1) {
    stop("size must be a numeric value between 0 and 1")
  }
  
  # Validate alpha
  if (!is.numeric(alpha) || alpha < 0 || alpha > 1) {
    stop("alpha must be a numeric value between 0 and 1")
  }
  
  # Determine logo path
  if (is.null(path)) {
    # Try to find package logo
    pkg_dir <- system.file(package = "arpctheme")
    if (pkg_dir != "") {
      # Package is installed
      logo_path <- system.file("Logo", "arpc_logo.pdf", package = "arpctheme")
    } else {
      # Development mode - look in current directory structure
      logo_path <- file.path("Logo", "arpc_logo.pdf")
    }
  } else {
    logo_path <- path
  }
  
  # Check if logo file exists
  if (!file.exists(logo_path)) {
    warning("Logo file not found at: ", logo_path, ". Using placeholder.")
    logo_path <- NULL
  }
  
  # Calculate logo coordinates based on position, preserving aspect ratio
  coords <- calculate_logo_coordinates(position, size, logo_path)
  
  # Create the annotation using a different approach
  tryCatch({
    # Create the logo grob
    logo_grob <- create_logo_grob(logo_path, coords, alpha)
    
    annotation_custom(
      grob = logo_grob,
      xmin = -Inf, xmax = Inf,
      ymin = -Inf, ymax = Inf
    )
  }, error = function(e) {
    warning("Failed to create logo annotation: ", e$message)
    return(NULL)
  })
}

#' Calculate Logo Coordinates
#'
#' Internal helper function to calculate logo placement coordinates
#' based on position and size parameters, preserving aspect ratio.
#'
#' @param position Character, logo position
#' @param size Numeric, logo size as proportion
#' @param logo_path Character, path to logo file for aspect ratio calculation
#' @return List with xmin, xmax, ymin, ymax coordinates
#' @keywords internal
#' @importFrom magick image_read image_info
calculate_logo_coordinates <- function(position, size, logo_path = NULL) {
  
  # Base coordinates for each position (as proportion of plot area)
  base_coords <- switch(position,
    "bottom-right" = list(x = 0.85, y = 0.08),
    "bottom-left" = list(x = 0.15, y = 0.08),
    "top-right" = list(x = 0.85, y = 0.92),
    "top-left" = list(x = 0.15, y = 0.92),
    "bottom" = list(x = 0.5, y = 0.08),
    "top" = list(x = 0.5, y = 0.92),
    "left" = list(x = 0.15, y = 0.5),
    "right" = list(x = 0.85, y = 0.5)
  )
  
  # Get logo aspect ratio if file exists
  aspect_ratio <- 1  # Default to square
  if (!is.null(logo_path) && file.exists(logo_path)) {
    tryCatch({
      img_info <- magick::image_info(magick::image_read(logo_path))
      aspect_ratio <- img_info$width / img_info$height
    }, error = function(e) {
      # If we can't read the image, use default aspect ratio
      aspect_ratio <<- 1
    })
  }
  
  # Calculate logo dimensions based on size parameter and aspect ratio
  if (aspect_ratio >= 1) {
    # Wide logo: use full width, adjust height
    logo_width <- size
    logo_height <- size / aspect_ratio
  } else {
    # Tall logo: use full height, adjust width  
    logo_width <- size * aspect_ratio
    logo_height <- size
  }
  
  # Calculate bounds
  xmin <- base_coords$x - logo_width / 2
  xmax <- base_coords$x + logo_width / 2
  ymin <- base_coords$y - logo_height / 2
  ymax <- base_coords$y + logo_height / 2
  
  # Ensure logo stays within plot bounds
  xmin <- max(0.01, xmin)
  xmax <- min(0.99, xmax)
  ymin <- max(0.01, ymin)
  ymax <- min(0.99, ymax)
  
  list(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
}

#' Create Logo Grob
#'
#' Internal helper function to create a grob for the logo, either from
#' an actual image file or as a placeholder.
#'
#' @param logo_path Character, path to logo file (or NULL)
#' @param coords List with logo coordinates
#' @param alpha Numeric, transparency level
#' @return A grob object
#' @keywords internal
#' @importFrom grid gTree gList rasterGrob rectGrob viewport unit gpar
#' @importFrom magick image_read image_convert
create_logo_grob <- function(logo_path, coords, alpha) {
  
  if (is.null(logo_path)) {
    # Use visible placeholder rectangle if logo file not found
    logo_element <- grid::rectGrob(
      x = unit(coords$xmin + (coords$xmax - coords$xmin)/2, "npc"),
      y = unit(coords$ymin + (coords$ymax - coords$ymin)/2, "npc"),
      width = unit(coords$xmax - coords$xmin, "npc"),
      height = unit(coords$ymax - coords$ymin, "npc"),
      gp = grid::gpar(
        fill = "red", 
        alpha = alpha, 
        col = "darkred",
        lwd = 3
      )
    )
  } else {
    # Try to load the actual logo
    tryCatch({
      # Read the PDF and convert to raster
      img <- magick::image_read(logo_path, density = 300)
      img_raster <- as.raster(magick::image_convert(img, "png"))
      
      # Create raster grob from the actual logo
      logo_element <- grid::rasterGrob(
        image = img_raster,
        x = unit(coords$xmin + (coords$xmax - coords$xmin)/2, "npc"),
        y = unit(coords$ymin + (coords$ymax - coords$ymin)/2, "npc"),
        width = unit(coords$xmax - coords$xmin, "npc"),
        height = unit(coords$ymax - coords$ymin, "npc"),
        interpolate = TRUE
      )
    }, error = function(e) {
      warning("Failed to load logo image: ", e$message, ". Using placeholder.")
      # Fall back to placeholder if image loading fails
      logo_element <<- grid::rectGrob(
        x = unit(coords$xmin + (coords$xmax - coords$xmin)/2, "npc"),
        y = unit(coords$ymin + (coords$ymax - coords$ymin)/2, "npc"),
        width = unit(coords$xmax - coords$xmin, "npc"),
        height = unit(coords$ymax - coords$ymin, "npc"),
        gp = grid::gpar(
          fill = "orange", 
          alpha = alpha, 
          col = "darkorange",
          lwd = 3
        )
      )
    })
  }
  
  # Return as gTree with viewport
  grid::gTree(
    children = grid::gList(logo_element),
    vp = grid::viewport(clip = "off")
  )
}