context("Test file for eq_location_clean()")

df <- system.file("extdata", "earthquakes.tsv", package = "NOAAearthquake")
df1 <- eq_clean_data(df)

test_that("eq_location_clean reformats location name and returns class character", {
  df2 <- eq_location_clean(df1)
  testthat::expect_that(df2$`Location Name`, is_a("character"))
  testthat::expect_that(df2$Country, is_a("character"))
})