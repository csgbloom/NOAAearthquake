# Coursera: Mastering Software Development in R Capstone
# Tomás Murray
# 2021/03/11
# Capstone Assignment: Documentation and Packaging
#------------------------------------------------------------------------------
# Load and tidy data
#------------------------------------------------------------------------------
#' @title Clean NCEI earthquake data
#'
#' @description
#' Reads, tidies and returns earthquake data downloadedfrom the US National
#' Centers for Environmental Information:
#' \url{https://www.ngdc.noaa.gov/hazel/view/hazards/earthquake/search}.
#' Longitude and latitude fields are read in automatically as numeric data types
#' using the readr::read_delim function and do not need to be specified.
#'
#' @param filename A character string giving the path and name of the delimited
#' file to be read in e.g."data/earthquakes.tsv"
#'
#' @return Output will be a data.frame object.
#'
#' @examples
#' \dontrun{
#' eq_clean_data("data/earthquakes.tsv")
#' }
#'
#' @importFrom readr read_delim cols col_double col_integer col_character
#' @importFrom dplyr select slice mutate
#' @importFrom tidyr replace_na
#' @importFrom lubridate make_date
#' @importFrom magrittr %>%
#' @importFrom utils globalVariables
#'
#' @export
eq_clean_data <- function(filename){

  eq_c <- readr::read_delim(filename, "\t", col_types = readr::cols(
    'Damage ($Mil)' = readr::col_double(),
    'Missing' = readr::col_integer(),
    'Total Missing' = readr::col_integer(),
    'Total Damage ($Mil)' = readr::col_double(),
    'Total Missing Description' = readr::col_character())) %>%
    dplyr::select(-'Search Parameters') %>%
    dplyr::slice(-1) %>%
    tidyr::replace_na(list(Mo = 1, Dy = 1)) %>% # Assume 01/01 for years without month or day data
    dplyr::mutate(Date = lubridate::make_date(Year, Mo, Dy)) # class(eq_c$Date) returns "Date" class

  return(eq_c);
}
utils::globalVariables(c("Year", "Mo", "Dy")) # Mitigate devtools::check() NOTE
#' @title Cleans LOCATION_NAME column
#'
#' @description
#' Cleans LOCATION_NAME column and returns earthquake data from the US National Centers for
#' Environmental Information:
#' \url{https://www.ngdc.noaa.gov/hazel/view/hazards/earthquake/search}.
#'
#' @param dataframe A character string giving the name of the input dataframe.
#'
#' @return Output will be a data.frame object.
#'
#' @examples
#' \dontrun{
#' eq_location_clean(eq_clean_data("data/earthquakes.tsv"))
#' }
#'
#' @importFrom stringr str_to_title word
#' @importFrom dplyr mutate
#' @importFrom magrittr %>%
#' @importFrom utils globalVariables
#'
#' @export
eq_location_clean <- function(dataframe){

  dataframe <- dataframe %>%
    dplyr::mutate(Country = stringr::str_to_title(stringr::word(`Location Name`, 1, sep = ":"))) %>%
    dplyr::mutate(`Location Name` = stringr::str_to_title(stringr::word(`Location Name`, 2, sep = ": ")))

  return(dataframe);
}
utils::globalVariables("Location Name") # Mitigate devtools::check() NOTE
#------------------------------------------------------------------------------
# Build the geom_timeline() Geom
#------------------------------------------------------------------------------
#' @title ggproto class GeomTimeline
#'
#' @description
#' Builds the ggproto class GeomTimeline for geom_timeline() funtion
#'
#' @return Output will be ggplot2 layer
#'
#' @example
#' \dontrun{
#' eq_location_clean(eq_clean_data("data/earthquakes.tsv")) %>%
#' dplyr::filter(Country %in% c("Mexico", "Turkey"), lubridate::year(Date) > 2000) %>%
#'   ggplot(aes(x = Date, y = Country, color = `Total Deaths`, size = Mag)) +
#'   geom_timeline() +
#'   labs(size = "Richter scale value", col = "# Deaths")
#' }
#'
#' @importFrom ggplot2 ggproto Geom aes draw_key_point
#' @importFrom grid polylineGrob unit gpar pointsGrob gList
#' @importFrom scales alpha
#'
GeomTimeline <- ggplot2::ggproto(
  "GeomTimeline", ggplot2::Geom,
  required_aes = c("x"),
  default_aes = ggplot2::aes(y = 0, size = 3, colour = "grey",
                             fill = "grey", alpha = 0.6, shape = 21),
  draw_key = ggplot2::draw_key_point,
  draw_panel = function(data, panel_scales, coord){

    # transform data
    coords <- coord$transform(data, panel_scales)

    # construct grobs for yline and datapoints
    ypos <- unique(coords$y)
    yline <- grid::polylineGrob(
      x = grid::unit(rep(c(0, 1), each = length(ypos)), "npc"),
      y = grid::unit(c(ypos, ypos), "npc"),
      id = rep(seq_along(ypos), 2),
      gp = grid::gpar(
        col = scales::alpha("grey", alpha = 0.8), lwd = 0.5))
    dps <- grid::pointsGrob(
      x = coords$x,
      y = coords$y,
      pch = coords$shape,
      size = grid::unit(coords$size / 4, "char"),
      gp = grid::gpar(
        col = scales::alpha(coords$colour, coords$alpha),
        fill = scales::alpha(coords$colour, coords$alpha)))

    # return yline and dps grobs
    grid::gList(yline, dps)
  }
)
#' @title ggplot2 layer geom_timeline()
#'
#' @description
#' Builds the geom_timeline() ggplot2 layer for the GeomTimeline geom.
#'
#' @param mapping Aesthetics mappings for call to ggplot2::layer
#' @param data Data to be displayed
#' @param stat Statistical transformation to be used
#' @param position Position adjustment
#' @param show.legend Logical to include legends
#' @param inherit.aes Logical to overide default aesthetics
#' @param na.rm use na.rm = FALSE from function
#' @param ... list of other default parameters
#'
#' @return Output will be ggplot2 layer
#'
#' @example
#' \dontrun{
#' eq_location_clean(eq_clean_data("data/earthquakes.tsv")) %>%
#' dplyr::filter(Country %in% c("Mexico", "Turkey"), lubridate::year(Date) > 2000) %>%
#'   ggplot(aes(x = Date, y = Country, color = `Total Deaths`, size = Mag)) +
#'   geom_timeline() +
#'   labs(size = "Richter scale value", col = "# Deaths")
#' }
#'
#' @importFrom ggplot2 layer
#'
#' @export
geom_timeline <- function(mapping = NULL, data = NULL, stat = "identity",
                          position = "identity", na.rm = FALSE,
                          show.legend = NA, inherit.aes = TRUE, ...) {
  ggplot2::layer(
    geom = GeomTimeline,
    mapping = mapping,
    data = data,
    stat = stat,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, ...)
  )
}
#' @title theme_timeline
#'
#' @description
#' Function to build ggplot2 theme to display plot as specified in exercise
#'
#' @return Output will be ggplot2 layer
#'
#' @example
#' \dontrun{
#' eq_location_clean(eq_clean_data("data/earthquakes.tsv")) %>%
#' dplyr::filter(Country %in% c("Mexico", "Turkey"), lubridate::year(Date) > 2000) %>%
#'   ggplot(aes(x = Date, y = Country, color = `Total Deaths`, size = Mag)) +
#'   geom_timeline() +
#'   theme_timeline() +
#'   labs(size = "Richter scale value", col = "# Deaths")
#' }
#'
#' @importFrom ggplot2 theme
#'
#' @export
theme_timeline <- function() {
  ggplot2::theme(
    plot.background = ggplot2::element_blank(),
    panel.background = ggplot2::element_blank(),
    axis.title.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    axis.line.y = ggplot2::element_blank(),
    axis.line.x = ggplot2::element_line(size = 0.5, linetype = 1),
    legend.key = ggplot2::element_blank(),
    legend.position = "bottom"
  )
}
#------------------------------------------------------------------------------
# Build the geom_timeline_label() Geom
#------------------------------------------------------------------------------
#' @title ggproto class GeomTimeline
#'
#' @description
#' Builds the ggproto class GeomTimeline for geom_timeline() funtion
#'
#' @return Output will be ggplot2 layer
#'
#' @example
#' \dontrun{
#' eq_location_clean(eq_clean_data("data/earthquakes.tsv")) %>%
#'   dplyr::filter(Country %in% c("India", "Chile"), lubridate::year(Date) > 2000) %>%
#'   ggplot(aes(x = Date, y = Country, color = `Total Deaths`, size = Mag)) +
#'   geom_timeline() +
#'   geom_timeline_label(aes(label = `Location Name`), n_max = 3) +
#'   theme_timeline() +
#'   labs(size = "Richter scale value", col = "# Deaths")
#' }
#'
#' @importFrom ggplot2 ggproto Geom aes draw_key_blank
#' @importFrom dplyr group_by_ top_n ungroup
#' @importFrom grid polylineGrob unit gpar textGrob gList
#' @importFrom magrittr %>%
#'
GeomTimelineLabel <- ggplot2::ggproto(
  "GeomTimelineLabel", ggplot2::Geom,
  required_aes = c("x", "label"),
  draw_key = ggplot2::draw_key_blank,

  # Setup values for n_max
  setup_data = function(data, params) {
    data <- data %>%
      dplyr::group_by_("group") %>% # SE version of group_by
      dplyr::top_n(params$n_max, size) %>%
      dplyr::ungroup()
  },

  draw_panel = function(data, panel_scales, coord, n_max){

    # transform data
    coords <- coord$transform(data, panel_scales)

    # construct grobs for lines and locations
    n_grp <- length(unique(data$group))
    offset <- 0.1 / n_grp
    lines <- grid::polylineGrob(
      x = grid::unit(c(coords$x, coords$x), "npc"),
      y = grid::unit(c(coords$y, coords$y + offset), "npc"),
      id = rep(1:dim(coords)[1], 2),
      gp = grid::gpar(col = "darkgrey", alpha = 0.6, lwd = 0.5)
    )

    locations <- grid::textGrob(
      label = coords$label,
      x = grid::unit(coords$x, "npc"),
      y = grid::unit(coords$y + offset, "npc"),
      just = c("left", "bottom"),
      rot = 45,
      gp = grid::gpar(fontsize = 10)
    )

    # return yline and dps grobs
    grid::gList(lines, locations)
  }
)
#' @title ggplot2 layer geom_timeline_label()
#'
#' @description
#' Builds the geom_timeline_label() ggplot2 layer for the GeomTimeline geom.
#'
#' @param mapping Aesthetics mappings for call to ggplot2::layer
#' @param data Data to be displayed
#' @param stat Statistical transformation to be used
#' @param position Position adjustment
#' @param show.legend Logical to include legends
#' @param inherit.aes Logical to overide default aesthetics
#' @param na.rm use na.rm = FALSE from function
#' @param ... list of other default parameters
#'
#'
#' @return Output will be ggplot2 layer
#'
#' @example
#' \dontrun{
#' eq_location_clean(eq_clean_data("data/earthquakes.tsv")) %>%
#'   dplyr::filter(Country %in% c("India", "Chile"), lubridate::year(Date) > 2000) %>%
#'   ggplot(aes(x = Date, y = Country, color = `Total Deaths`, size = Mag)) +
#'   geom_timeline() +
#'   geom_timeline_label(aes(label = `Location Name`), n_max = 3) +
#'   theme_timeline() +
#'   labs(size = "Richter scale value", col = "# Deaths")
#' }
#'
#' @importFrom ggplot2 layer
#'
#' @export
geom_timeline_label <- function(mapping = NULL, data = NULL, stat = "identity",
                          position = "identity", na.rm = FALSE,
                          show.legend = NA, inherit.aes = TRUE, ...) {
  ggplot2::layer(
    geom = GeomTimelineLabel,
    mapping = mapping,
    data = data,
    stat = stat,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, ...)
  )
}
#------------------------------------------------------------------------------
# Build the eq_map() mapping function
#------------------------------------------------------------------------------
#' @title eq_map() mapping function
#'
#' @description
#' Builds the eq_map() mapping function for generating a Leaflet map
#'
#' @param data Data frame
#' @param annot_col Attribute of data to be displayed as a popup on the map
#'
#' @return Output will be a Leaflet map
#'
#' @example
#' \dontrun{
#' eq_location_clean(eq_clean_data("data/earthquakes.tsv")) %>%
#'   dplyr::filter(Country == "Turkey", lubridate::year(Date) >= 2010) %>%
#'   eq_map(annot_col = "Date")
#' }
#'
#' @importFrom dplyr mutate
#' @importFrom leaflet leaflet addTiles addCircleMarkers
#' @importFrom magrittr %>%
#'
#' @export
eq_map <- function(data, annot_col) {
  data <- data %>%
    dplyr::mutate(poplabel = data[[annot_col]])
  m <- data %>%
    leaflet::leaflet() %>%
    leaflet::addTiles() %>%
    leaflet::addCircleMarkers(~Longitude,
                              ~Latitude,
                              popup = ~poplabel,
                              weight = 1,
                              radius = ~Mag)
  return(m)
}
#------------------------------------------------------------------------------
# Build the eq_create_label() HTML label function
#------------------------------------------------------------------------------
#' @title eq_create_label() HTML label function
#'
#' @description
#' Builds eq_create_label() HTML label function for when generating the
#' Leaflet map
#'
#' @param data Data frame
#'
#' @return Output will be a vector of character strings
#'
#' @example
#' \dontrun{
#' eq_location_clean(eq_clean_data("data/earthquakes.tsv")) %>%
#'   dplyr::filter(Country == "Turkey", lubridate::year(Date) >= 2010) %>%
#'   dplyr::mutate(popup_text = eq_create_label(.)) %>%
#'   eq_map(annot_col = "popup_text")
#' }
#'
#' @importFrom stringr str_c str_remove_all
#' @importFrom dplyr mutate
#' @importFrom htmltools HTML
#' @importFrom magrittr %>%
#' @importFrom utils globalVariables
#'
#' @export
eq_create_label <- function(data) {
  # use | to evaluate as a regex OR for list to remove from label if NA
  rm <- stringr::str_c(c("<strong>Location: </strong>NA<br/>",
                         "<strong>Magnitude: </strong>NA<br/>",
                         "<strong>Total Deaths: </strong>NA"), collapse = "|")
  data <- data %>%
    dplyr::mutate(popup_text = (paste0('<strong>Location: </strong>',
                                       `Location Name`, '<br/>',
                                       '<strong>Magnitude: </strong>',
                                       Mag, '<br/>',
                                       '<strong>Total Deaths: </strong>',
                                       `Total Deaths`) %>% lapply(htmltools::HTML))) %>%
    dplyr::mutate(popup_text = stringr::str_remove_all(popup_text, rm))

  return(as.vector(data$popup_text))
}
utils::globalVariables(c("Location Name", "Mag", "Total Deaths", "popup_text")) # Mitigate devtools::check() NOTE
