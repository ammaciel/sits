#' @title Check if the raster files are on the web
#' @name .sits_raster_check_webfiles
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param files         files associated to the raster data
#' @return files        Updated files with  information for GDAL access
.sits_raster_check_webfiles <- function(files) {
    # are there webfiles?
    if (all(grepl("http", c(files[1])))) {
        # append "vsicurl" prefix for all web files if it is not there
        if (!grepl("vsicurl", c(files[1])))
            files <- paste("/vsicurl", files, sep = "/")
    }
    return(files)
}

#' @title Check if the raster files are accessible by GDAL
#' @name .sits_raster_check_gdal_access
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param files         files associated to the raster data
#' @return TRUE         true if filles are acessible
.sits_raster_check_gdal_access <- function(files){
    # verify if all files are reacheable
    r <- suppressWarnings(rgdal::GDALinfo(files, silent = FALSE))
    assertthat::assert_that(all(!purrr::is_null(r)),
                            msg = "sits_cube: raster files cannot be accessed")
    return(TRUE)
}

#' @title Check if the raster files are bricks
#' @name .sits_raster_check_bricks
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param files         files associated to the raster data
#' @return TRUE         true if filles are acessible
.sits_raster_check_bricks <- function(files){
    # are the files bricks?
    tryCatch({
        brick <- raster::brick(files[1])
    }, error = function(e){
        msg <- paste0("Raster files are not bricks")
        .sits_log_error(msg)
        message(msg)
    })
    return(TRUE)
}

#' @title Check if the raster files are stacks
#' @name .sits_raster_check_stacks
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param files         files associated to the raster data
#' @return TRUE         true if filles are acessible
.sits_raster_check_stacks <- function(files){
    # are the files stacks?
    tryCatch({
        brick <- raster::stack(files[1])
    }, error = function(e){
        msg <- paste0("Raster files are not stacks")
        .sits_log_error(msg)
        message(msg)
    })
    return(TRUE)
}
#' @title Create a data cube based on a set of Raster Bricks
#' @name .sits_raster_cube
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @description  This function creates a tibble containing the metadata for
#'               a set of spatio-temporal raster files,
#'               organized as a set of "Raster Bricks".
#'               These files should be of the same size and
#'               projection. Each raster brick file should contain one band
#'               per time step.
#'               Different bands are archived in different raster files.
#'
#' @param  service               Name of the data service.
#' @param  URL                   URL of the service provider.
#' @param  satellite             Name of satellite
#' @param  sensor                Name of sensor
#' @param  name                  Name of the data cube.
#' @param  timeline              Vector of dates with the timeline of the bands.
#' @param  bands                 Vector of bands contained in the Raster Brick
#'                               set (in the same order as the files).
#' @param  files                 Vector with the file paths of the raster files.
#' @return A tibble with metadata information about a raster data set.
.sits_raster_cube <- function(service,
                              URL,
                              satellite,
                              sensor,
                              name,
                              timeline,
                              bands,
                              files) {

    assertthat::assert_that(length(bands) == length(files),
                            msg = "sits_raster_cube: bands do not match files")

    assertthat::assert_that(!purrr::is_null(name),
                            msg = "sits_raster_cube: missing cube name")

    assertthat::assert_that(!purrr::is_null(files),
                            msg = "sits_raster_cube - files must be provided")

    assertthat::assert_that(!purrr::is_null(timeline),
                            msg = "sits_raster_cube - missing timeline")

    # try to guess which is the satellite
    if (purrr::is_null(satellite)) {
        satellite <- .sits_raster_guess_satellite(
            .sits_raster_files_robj(service, files))
        message(paste0("satellite information missing - assuming ", satellite))
    }
    # is the satellite supported by SITS?
    assertthat::assert_that(satellite %in% .sits_config_satellites(),
                            msg = "satellite not supported by SITS - please edit config file")

    # try to guess which is the sensor
    if (purrr::is_null(sensor)) {
        sensor <- .sits_config_default_sensor(satellite)
        message(paste0("sensor information not provided - assuming ", sensor))
    }
    # is the sensor supported by SITS?
    assertthat::assert_that(sensor %in% .sits_config_sensors(satellite),
                            msg = "sensor not supported by SITS - please edit config file")

    # transform the timeline to date format
    timeline <- lubridate::as_date(timeline)

    # set the labels
    labels <- c("NoClass")

    # obtain the parameters
    params <- .sits_raster_params(.sits_raster_files_robj(service, files))

    # get scale factors
    scale_factors  <- .sits_config_scale_factors(sensor, bands)
    # get missing values
    missing_values <- .sits_config_missing_values(sensor, bands)
    # get minimum values
    minimum_values <- .sits_config_minimum_values(sensor, bands)
    # get maximum values
    maximum_values <- .sits_config_maximum_values(sensor, bands)


    # create a tibble to store the metadata
    cube <- .sits_cube_create(service        = service,
                              URL            = URL,
                              satellite      = satellite,
                              sensor         = sensor,
                              name           = name,
                              bands          = bands,
                              labels         = labels,
                              scale_factors  = scale_factors,
                              missing_values = missing_values,
                              minimum_values = minimum_values,
                              maximum_values = maximum_values,
                              timelines      = list(timeline),
                              nrows = params$nrows,
                              ncols = params$ncols,
                              xmin  = params$xmin,
                              xmax  = params$xmax,
                              ymin  = params$ymin,
                              ymax  = params$ymax,
                              xres  = params$xres,
                              yres  = params$yres,
                              crs   = params$xmin,
                              files = files )
    return(cube)
}

#' @title Define a filename associated to one classified raster layer
#' @name .sits_raster_filename
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @description    Creates a filename for a raster layer
#'                 with associated temporal information,
#'                 given a basic filename.
#' @param output_dir     Output directory
#' @param version        Output version
#' @param name           Original cube name (without temporal information).
#' @param type           Type of output
#' @param start_date    Starting date of the time series classification.
#' @param end_date      End date of the time series classification.
#' @return Name of the classification file for the required interval.
.sits_raster_filename <- function(output_dir,
                                  version,
                                  name,
                                  type,
                                  start_date,
                                  end_date) {
    y1 <- lubridate::year(start_date)
    m1 <- lubridate::month(start_date)
    y2 <- lubridate::year(end_date)
    m2 <- lubridate::month(end_date)

    file_name <- paste0(output_dir,"/", name, "_", type, "_",
                        y1, "_", m1, "_", y2, "_", m2, "_", version,".tif")

    return(file_name)
}
#' @title Determine the cube params to write in the metadata
#' @name .sits_raster_params
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @description    Based on the R object associated to a raster object,
#'                 determine its params
#'
#' @param r_obj    An R object associated to a Raster (Layer, Brick or Stack)
#' @return A tibble with the cube params
.sits_raster_params <- function(r_obj) {

    params.tb <- tibble::tibble(
        nrows = raster::nrow(r_obj),
        ncols = raster::ncol(r_obj),
        xmin  = raster::xmin(r_obj),
        xmax  = raster::xmax(r_obj),
        ymin  = raster::ymin(r_obj),
        ymax  = raster::ymax(r_obj),
        xres  = raster::xres(r_obj),
        yres  = raster::yres(r_obj),
        crs   = as.character(raster::crs(r_obj))
    )
    return(params.tb)
}
#' @title Raster object from file
#' @name .sits_raster_files_robj
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @description     Given the vector of files and the name of the service,
#'                  return the Raster object for the file
#' @param service   Name of the service (must be "BRICK" or "STACK!)
#' @param files     Vector of files
#' @return          Raster object associated to the first file
#'
.sits_raster_files_robj <- function(service, files){
    assertthat::assert_that(service %in% c("BRICK", "STACK"),
                            msg = "Error in creating a data cube from raster files; data should be
                BRICK or STACK")
    if (service == "BRICK")
        return(raster::brick(files[1]))
    if (service == "STACK")
        return(raster::stack(files[1]))
}
#' @title Tests if an XY position is inside a ST Raster Brick
#' @name .sits_raster_xy_inside
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @description Compares an XY position to the extent of a RasterBrick
#'              described by a raster metadata tibble.
#'              Returns TRUE if the point is
#'              inside the extent of the RasterBrick object.
#'
#' @param xy         XY extent compatible with the R raster package.
#' @param raster.tb  Tibble with metadata information about a raster data set.
#' @return TRUE if XY is inside the raster extent, FALSE otherwise.
.sits_raster_xy_inside <- function(xy, raster.tb){
    if (xy[1, "X"] < raster.tb[1, ]$xmin) return(FALSE)
    if (xy[1, "X"] > raster.tb[1, ]$xmax) return(FALSE)
    if (xy[1, "Y"] < raster.tb[1, ]$ymin) return(FALSE)
    if (xy[1, "Y"] > raster.tb[1, ]$ymax) return(FALSE)
    return(TRUE)
}
