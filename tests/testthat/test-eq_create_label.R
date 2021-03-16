context("Test file for eq_create_label()")
require(magrittr)

df <- system.file("extdata", "earthquakes.tsv", package = "NOAAearthquake")
df1 <- eq_clean_data(df)
df2 <- eq_location_clean(df1) %>% 
  dplyr::filter(Country == "Turkey", lubridate::year(Date) >= 2010)

test_that("eq_create_label returns class character", {
  mt <- df2 %>% 
    dplyr::mutate(popup_text = eq_create_label(.))
  testthat::expect_that(mt$popup_text, is_a("character"))
})

test_that("eq_create_label omits NA values in label", {
  mt <- df2 %>% 
    dplyr::mutate(popup_text = eq_create_label(.)) %>% 
    dplyr::mutate(chk = grepl("NA", mt$popup_text, fixed = TRUE))
  testthat::expect_true(sum(mt$chk) == 0)
})