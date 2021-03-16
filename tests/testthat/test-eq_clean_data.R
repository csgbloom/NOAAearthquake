context("Test file for eq_clean_data()")

df <- system.file("extdata", "earthquakes.tsv", package = "NOAAearthquake")

test_that("eq_clean_data returns a data.frame", {
  df1 <- eq_clean_data(df)
  testthat::expect_is(df1, "data.frame")
})

test_that("eq_clean_data returns class date", {
  df1 <- eq_clean_data(df)
  testthat::expect_that(df1$Date, is_a("Date"))
})