#' Add ARPC Logo to ggplot
#'
#' Adds the ARPC logo to a ggplot object. This function returns a special object
#' that automatically handles both the logo annotation and coordinate clipping
#' when added to any ggplot using the + operator.
#'
#' @param position Character or numeric vector, position of logo. 
#'   Character options: "bottom-right", "bottom-left", "top-right", "top-left", 
#'   "bottom", "top", "left", "right" (default: "bottom-right") - predefined positions. 
#'   Numeric option: c(x, y) coordinates in normalized units (0-1 = plot area, 
#'   >1 or <0 = margin areas, e.g., c(1.1, 0.5) for right margin)
#' @param size Numeric, size of logo as proportion of plot area (default: 0.3)
#' @param path Character, path to logo file. If NULL, uses package default logo (default: NULL)
#' @param alpha Numeric, transparency of logo (0 = transparent, 1 = opaque) (default: 0.8)
#'
#' @return A special logo object that automatically adds both annotation and coordinate system
#' @export
#' @import ggplot2
#' @importFrom grid unit rectGrob gpar gTree gList viewport rasterGrob
#' @importFrom png readPNG
#' @importFrom tools file_ext
#'
#' @examples
#' library(ggplot2)
#' 
#' # Add logo to bottom-right (default) - automatic clipping handling
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
#'   
#' # Use custom coordinates - 0-1 is plot area, outside is margins
#' ggplot(mtcars, aes(x = wt, y = mpg)) +
#'   geom_point() +
#'   theme_arpc() +
#'   logo(position = c(1.1, 0.5), size = 0.08)  # Right margin, vertically centered
logo <- function(position = "bottom-right", 
                 size = 0.3, 
                 path = NULL, 
                 alpha = 0.8) {
  
  # Validate position
  valid_positions <- c("bottom-right", "bottom-left", "top-right", "top-left", 
                      "bottom", "top", "left", "right")
  
  if (is.character(position)) {
    # String position validation
    if (!position %in% valid_positions) {
      stop("position must be one of: ", paste(valid_positions, collapse = ", "), 
           " or a numeric vector of length 2 with x,y coordinates")
    }
  } else if (is.numeric(position)) {
    # Numeric position validation
    if (length(position) != 2) {
      stop("numeric position must be a vector of length 2 (x, y coordinates)")
    }
    if (any(!is.finite(position))) {
      stop("position coordinates must be finite numbers")
    }
  } else {
    stop("position must be either a character string (", 
         paste(valid_positions, collapse = ", "), 
         ") or a numeric vector of length 2 with x,y coordinates")
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
    # Try to find package logo in inst directory (prefer PNG over PDF)
    pkg_dir <- system.file(package = "arpctheme")
    if (pkg_dir != "") {
      # Package is installed - logo is in inst directory
      logo_path <- system.file("arpc_logo.png", package = "arpctheme")
      if (!file.exists(logo_path)) {
        logo_path <- system.file("arpc_logo.pdf", package = "arpctheme")
      }
    } else {
      # Development mode - look in inst directory
      logo_path <- file.path("inst", "arpc_logo.png")
      if (!file.exists(logo_path)) {
        logo_path <- file.path("inst", "arpc_logo.pdf")
      }
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
  
  # No longer need clipping warnings - handled automatically
  
  # Create the annotation with automatic clipping support
  tryCatch({
    # Create the logo grob
    logo_grob <- create_logo_grob(logo_path, coords, alpha)
    
    # Create annotation
    annotation <- annotation_custom(
      grob = logo_grob,
      xmin = -Inf, xmax = Inf,
      ymin = -Inf, ymax = Inf
    )
    
    # Return both annotation and coordinate system as a special object
    logo_layers <- list(
      annotation = annotation,
      coord = coord_cartesian(clip = 'off')
    )
    
    class(logo_layers) <- "arpc_logo_layers"
    return(logo_layers)
    
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
#' @param position Character or numeric vector, logo position
#' @param size Numeric, logo size as proportion
#' @param logo_path Character, path to logo file for aspect ratio calculation
#' @return List with xmin, xmax, ymin, ymax coordinates
#' @keywords internal
#' @importFrom png readPNG
#' @importFrom tools file_ext
calculate_logo_coordinates <- function(position, size, logo_path = NULL) {
  
  # Determine base coordinates
  if (is.character(position)) {
    # Use predefined string positions at plot edges
    base_coords <- switch(position,
      "bottom-right" = list(x = 0.8, y = -0.1),     # Lower-right plot edge
      "bottom-left" = list(x = 0.2, y = -0.1),      # Lower-left plot edge
      "top-right" = list(x = 0.8, y = 1.0),        # Upper-right plot edge
      "top-left" = list(x = 0.2, y = 1.0),         # Upper-left plot edge
      "bottom" = list(x = 0.5, y = 0.0),           # Bottom edge center
      "top" = list(x = 0.5, y = 1.0),              # Top edge center
      "left" = list(x = 0.0, y = 0.5),             # Left edge center
      "right" = list(x = 1.0, y = 0.5)             # Right edge center
    )
  } else if (is.numeric(position) && length(position) == 2) {
    # Use custom x,y coordinates
    base_coords <- list(x = position[1], y = position[2])
  } else {
    # Fallback to bottom-right if something goes wrong
    base_coords <- list(x = 0.85, y = 0.08)
  }
  
  # Get logo aspect ratio if file exists
  aspect_ratio <- 1  # Default to square
  if (!is.null(logo_path) && file.exists(logo_path)) {
    tryCatch({
      if (tolower(tools::file_ext(logo_path)) == "png") {
        # For PNG files, get dimensions from file header
        img_data <- png::readPNG(logo_path, native = TRUE, info = TRUE)
        img_info <- attr(img_data, "info")
        aspect_ratio <- img_info$dim[1] / img_info$dim[2]  # width / height (native aspect ratio)
      } else {
        # For PDF files, use a reasonable default aspect ratio
        # Most logos are wider than tall, so use 1.5:1 ratio
        aspect_ratio <- 1.5
      }
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
  
  # Calculate bounds (no clamping - allows margin positioning)
  xmin <- base_coords$x - logo_width / 2
  xmax <- base_coords$x + logo_width / 2
  ymin <- base_coords$y - logo_height / 2
  ymax <- base_coords$y + logo_height / 2
  
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
#' @importFrom grid gTree gList rasterGrob rectGrob viewport unit gpar textGrob
#' @importFrom png readPNG
#' @importFrom tools file_ext
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
      if (tolower(tools::file_ext(logo_path)) == "png") {
        # Read PNG file directly
        img_raster <- png::readPNG(logo_path)
        
        # Apply alpha transparency to the image data
        if (length(dim(img_raster)) == 3) {
          # Check if image has alpha channel (4th dimension)
          if (dim(img_raster)[3] == 4) {
            # RGBA image - multiply existing alpha channel by our alpha parameter
            img_raster[,,4] <- img_raster[,,4] * alpha
          } else if (dim(img_raster)[3] == 3) {
            # RGB image - add alpha channel
            img_rgba <- array(dim = c(dim(img_raster)[1], dim(img_raster)[2], 4))
            img_rgba[,,1:3] <- img_raster[,,1:3]  # Copy RGB channels
            img_rgba[,,4] <- alpha  # Set alpha channel
            img_raster <- img_rgba
          }
        }
        
        # Create raster grob from the actual logo
        logo_element <- grid::rasterGrob(
          image = img_raster,
          x = unit(coords$xmin + (coords$xmax - coords$xmin)/2, "npc"),
          y = unit(coords$ymin + (coords$ymax - coords$ymin)/2, "npc"),
          width = unit(coords$xmax - coords$xmin, "npc"),
          height = unit(coords$ymax - coords$ymin, "npc"),
          interpolate = TRUE
        )
      } else {
        # For non-PNG files (like PDF), create a text placeholder
        warning("Non-PNG logo files no longer supported. Convert to PNG format.")
        logo_element <- grid::textGrob(
          label = "ARPC\nLOGO",
          x = unit(coords$xmin + (coords$xmax - coords$xmin)/2, "npc"),
          y = unit(coords$ymin + (coords$ymax - coords$ymin)/2, "npc"),
          gp = grid::gpar(
            fontsize = 12,
            fontface = "bold",
            col = rgb(0, 0, 0, alpha)
          )
        )
      }
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

#' ggplot2 S3 Method for Logo Layers
#'
#' This S3 method allows the logo function to automatically add both the 
#' annotation layer and coord_cartesian(clip = 'off') to ggplot objects.
#' Users can simply use + logo() without needing to manually add coord_cartesian.
#'
#' @param object The arpc_logo_layers object returned by logo()
#' @param plot The ggplot object to add layers to
#' @param object_name Not used
#' @return The modified ggplot object with both annotation and coordinate system
#' @export
#' @method ggplot_add arpc_logo_layers
ggplot_add.arpc_logo_layers <- function(object, plot, object_name) {
  # Add both the annotation and coordinate system to the plot
  plot + object$annotation + object$coord
}