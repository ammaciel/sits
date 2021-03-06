context("Data input")
test_that("Creating a WTSS data cube", {
    #skip_on_cran()
    cube_wtss <- sits_cube(service = "WTSS", name = "MOD13Q1")

    expect_true(cube_wtss$service == "WTSS")
    expect_true(length(cube_wtss$timeline[[1]][[1]]) > 1)
})

test_that("Creating a SATVEG data cube", {
    #skip_on_cran()
    cube_satveg <- sits_cube(service = "SATVEG", name = "terra")

    expect_true(length(cube_satveg$timeline[[1]][[1]]) > 1)
})

test_that("Reading a CSV file from WTSS", {
    #skip_on_cran()
    csv_file <- system.file("extdata/samples/samples_matogrosso.csv",
                            package = "sits")
    cube_wtss <- sits_cube(service = "WTSS", name = "MOD13Q1")

    points.tb <- sits_get_data(cube_wtss, file = csv_file)

    expect_true(all(unique(points.tb$label) == c("Pasture", "Cerrado")))

    expect_equal(min(points.tb$longitude), -55.0399, tolerance = 1e-5)
    expect_equal(min(points.tb$latitude), -15.1933, tolerance = 1e-5)
    expect_equal(max(points.tb$longitude), -46.407, tolerance = 1e-5)
    expect_equal(max(points.tb$latitude), -10.4142, tolerance = 1e-5)

    mylabels <- sits_labels(points.tb)

    expect_equal(dplyr::filter(mylabels, label == "Cerrado")$count, 3)
    expect_equal(dplyr::filter(mylabels, label == "Pasture")$count, 3)

    df_csv <- utils::read.csv(system.file("extdata/samples/samples_matogrosso.csv",
                                          package = "sits"))
    expect_true(NROW(points.tb) == NROW(df_csv))
})

test_that("Reading a CSV file from RASTER", {
    #skip_on_cran()
    file <- c(system.file("extdata/raster/mod13q1/sinop-crop-ndvi.tif",
                          package = "sits"))
    raster_cube <- sits_cube(name = "Sinop-crop",
                             timeline = sits::timeline_modis_392,
                             bands = c("ndvi"),
                             files = file)
    csv_raster_file <- system.file("extdata/samples/samples_sinop_crop.csv",
                                   package = "sits")
    points.tb <- sits_get_data(raster_cube, file = csv_raster_file)
    df_csv <- utils::read.csv(system.file("extdata/samples/samples_sinop_crop.csv",
                                          package = "sits"))
    expect_true(NROW(points.tb) == NROW(df_csv))

    expect_true("Forest" %in% sits_labels(points.tb)$label)
    expect_equal(names(points.tb)[1], "longitude")
    expect_equal(length(names(points.tb)), 7)
    expect_true(ncol(sits_time_series(points.tb)) == 2)
    expect_true(length(sits_time_series_dates(points.tb)) == 23)
})

test_that("Reading a point from WTSS ", {
    #skip_on_cran()
    cube_wtss <- sits_cube(service = "WTSS", name = "MOD13Q1")
    point.tb <- sits_get_data(cube_wtss,
                              longitude = -55.50563, latitude = -11.71557)
    timeline <- lubridate::as_date(as.vector(sits_time_series_dates(point.tb)))

    expect_true(ncol(sits_time_series(point.tb)) == 7)
    expect_equal(sum(sits_time_series(point.tb)$evi[1:423]),                    
                 157.3737, tolerance = 1e-3)  
    expect_true(point.tb$start_date == timeline[1])
    expect_true(point.tb$end_date == timeline[length(timeline)])
})

test_that("Reading a point from SATVEG ", {
    #skip_on_cran()
    cube_1 <- sits_cube(service = "SATVEG", name = "terra")
    cube_2 <- sits_cube(service = "SATVEG", name = "aqua")
    cube_3 <- sits_cube(service = "SATVEG", name = "comb")

    point_terra <- sits_get_data(cube_1,
                                 longitude = -55.50563, latitude = -11.71557)

    expect_equal(ncol(sits_time_series(point_terra)), 3)
    expect_equal(sum(sits_time_series(point_terra)$evi), 158.11, tolerance = 2)

    point_aqua <- sits_get_data(cube_2,
                                longitude = -55.50563, latitude = -11.71557)

    expect_equal(ncol(sits_time_series(point_aqua)), 3)
    expect_equal(sum(sits_time_series(point_aqua)$evi),
                 132.3852, tolerance = 2)

    point_comb <- sits_get_data(cube_3,
                                longitude = -55.50563, latitude = -11.71557)

    expect_equal(ncol(sits_time_series(point_comb)), 3)
    expect_equal(sum(sits_time_series(point_comb)$evi), 290.3342, tolerance = 2)

    expect_true(length(sits_time_series_dates(point_comb)) >=
                    length(sits_time_series_dates(point_terra)))
})

test_that("Reading a ZOO time series", {
    #skip_on_cran()
    data(ts_zoo)
    data <- sits_from_zoo(ts_zoo, longitude = -54.2313, latitude = -14.0482,
                             label = "Cerrado", name = "mod13q1")

    expect_equal(sum(sits_time_series(data)$ndvi), 13.6291, tolerance = 1e-3)
    expect_true(NROW(ts_zoo) == length(sits_time_series_dates(data)))
})

test_that("Reading a POLYGON shapefile", {
    #skip_on_cran()
    cube_wtss <- sits_cube(service = "WTSS", name = "MOD13Q1")
    shp_file <- system.file("extdata/shapefiles/parcel_agriculture.shp",
                            package = "sits")
    parcel.tb <- sits_get_data(cube_wtss,
                               file = shp_file,
                               shp_attr = "ext_na",
                               .n_shp_pol = 3)

    sf_shape <- sf::read_sf(shp_file)
    sf_shape <- sf::st_transform(sf_shape, crs = 4326)
    bbox <- sf::st_bbox(sf_shape)
    longitudes_shp <- parcel.tb$longitude

    expect_true(nrow(parcel.tb) > 1)
    expect_true(all(unique(longitudes_shp) > bbox["xmin"]))
    expect_true(all(unique(longitudes_shp) < bbox["xmax"]))
    expect_true(all(parcel.tb$label == "Soja_Algodao"))
})

test_that("Reading a POINT shapefile", {
    #skip_on_cran()
    cube_wtss <- sits_cube(service = "WTSS", name = "MOD13Q1")
    shp_file <- system.file("extdata/shapefiles/cerrado_forested.shp",
                            package = "sits")
    points.tb <- sits_get_data(cube_wtss, file = shp_file,
                               label = "Cerrado_Forested", .n_shp_pts = 3)

    expect_true(all(points.tb$label == "Cerrado_Forested"))
})

test_that("Labels and re-label", {
    #skip_on_cran()
    data(prodes_226_064)
    conv.lst <- list(Deforestation_2014 = "NonForest",
                     Deforestation_2015 = "NonForest",
                     Forest = "Forest",
                     Pasture = "NonForest")
    new_data <- sits_relabel(prodes_226_064, conv.lst)

    labels <- sits_labels(new_data)

    expect_equal(length(labels$label), 2)
    expect_equal(labels$label[1], "Forest")
    expect_equal(sum(labels$prop), 1)
})
