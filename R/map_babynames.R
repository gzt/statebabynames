#' Adding a color to the background.
#'
#' @import ggplot2 dplyr gganimate
#' @importFrom scales wrap_format
#'
#' @param name, name to generate a plot for
#' @param filename, the file to save the plot to. if NULL, defaults to {nam parameter}.gif"
#' @param start_year, first year to include names. must be between 1910 and 2016. defaults to 2000 to avoid accidentally making a huge plot.
#' @param stop_year, last year to include names. must be between 1910 and 2016. defaults to 2016.
#' @param raleway, whether or not to change the plot font to Raleway and use theme_fancy() to add background color. needs the google Raleway font downloaded to work (https://fonts.google.com/specimen/Raleway). Defaults to false.
#' @param ani.width, width of the animation, passed to gganimate
#' @param ani.height, height of the animation, passed to gganimate
#' @param interval, time in seconds spent on each frame, passed to gganimate
#' @param proportion, whether to display raw numbers or proportions. Defaults to false.
#' @param ..., other args passed to gganimate
#'
#' @export
map_babynames <- function(nam, filename = NULL, start_year = 2000, stop_year = 2016, raleway = FALSE,
                          ani.width = 560, ani.height = 360, interval = .2, proportion = FALSE, ...) {


    wrap90 <- scales::wrap_format(90)

    # if(!exists("statebabynames", envir = globalenv())) {data("statebabynames")}
    numberdf <- statebabynames %>% group_by(state, year) %>%
      summarize(total = sum(n)) %>%
      filter(year >= start_year & year <= stop_year)

    namedf <- statebabynames %>%
    filter(name == nam & year >= start_year & year <= stop_year)

    statebabynames <- statebabynames %>%
        select(state, year) %>%
        filter(year >= start_year & year <= stop_year) %>%
        unique()

    namedf <- full_join(namedf, statebabynames, by = c("state", "year"))
    if(proportion) namedf <- full_join(namedf, numberdf, by = c("state", "year"))

    state_lookup = dplyr::data_frame(state = state.abb, region = state.name)

    usa_map <- ggplot2::map_data("state")

    state_map <- full_join(namedf, state_lookup, by = "state") %>%
        mutate(region = tolower(region)) %>%
        full_join(usa_map, by = "region")

    if(proportion) state_map <- state_map %>% mutate(proportion = n/total)

    ti <- paste0("Babies named ", nam, " born in each state," )

    g <- ggplot() +
        if(proportion) {geom_polygon(data = state_map, aes(fill = proportion, x = long, y = lat, group = group, frame = year))} else {
        geom_polygon(data = state_map, aes(fill = n, x = long, y = lat, group = group, frame = year))
        }
    g <- g +
        scale_fill_gradient(low = "lightblue", high = "darkblue", na.value = "lightgray", guide = "legend")  +
        ggtitle(ti) +
        labs(caption = wrap90("Data from the Social Security Administration. To protect privacy, if a name has less than 5 occurrences for a year of birth in any state, those names are not recorded. The sum of the state counts is thus less than the national count.")) +
        theme_void() +
         theme(text = element_text(family = "Avenir"),
            plot.title = element_text(size = 22, hjust = .5,
                                      margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
            plot.subtitle = element_text(size = 12, hjust = .5, vjust = -2, color = "#4e4d47"),
            axis.text = element_blank())

    if(raleway == TRUE) {
        #library(bplots) # devtools::install_github("brooke-watson/bplots")
        # download the raleway font for theme_raleway() to work: https://fonts.google.com/?selection.family=Raleway
        g <- g + bplots::theme_blank(element_text(family = "Raleway")) + bplots::theme_fancy()
    }

    if(is.null(filename)) {
        path <- paste0(nam, ".gif")
    } else if(!grepl(".gif$", "filename.gif")) {
        path <- paste0(filename, ".gif")
    } else  {path <- filename}

    gganimate::gganimate(g, path, ani.width = ani.width, ani.height = ani.height, interval = interval, ...)
}
