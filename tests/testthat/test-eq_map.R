context("Test file for eq_map()")
require(magrittr)

df <- system.file("extdata", "earthquakes.tsv", package = "NOAAearthquake")
df1 <- eq_clean_data(df)
df2 <- eq_location_clean(df1) %>% 
  dplyr::filter(Country == "Turkey", lubridate::year(Date) >= 2010)

test_that("eq_map returns a leaflet map", {
  mt <- df2 %>% eq_map(annot_col = "Date")
  testthat::expect_that(mt, is_a("leaflet"))
})