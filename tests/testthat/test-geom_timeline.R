context("Test file for geom_timeline()")
require(magrittr)

df <- system.file("extdata", "earthquakes.tsv", package = "NOAAearthquake")
df1 <- eq_clean_data(df)
df2 <- eq_location_clean(df1) %>% 
  dplyr::filter(Country %in% c("Mexico", "Turkey"), lubridate::year(Date) > 2000) %>% 
  ggplot2::ggplot(ggplot2::aes(x = Date, y = Country, color = `Total Deaths`, size = `Mag`))

test_that("geom_timeline returns ggplot object", {
  gt <- df2 + geom_timeline()
  testthat::expect_that(gt, is_a("ggplot"))
})