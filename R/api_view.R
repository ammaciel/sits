#' @title  Include leaflet to view images (BW or RGB)
#' @name .view_image_raster
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  cube          Cube to be plotted (raster cube)
#' @param  class_cube    Classified cube to be overlayed on top on image
#' @param  tiles         Tiles to be plotted (in case of a multi-tile cube).
#' @param  dates         Dates to be plotted.
#' @param  band          For plotting grey images.
#' @param  red           Band for red color.
#' @param  green         Band for green color.
#' @param  blue          Band for blue color.
#' @param  legend        Named vector that associates labels to colors.
#' @param  palette       Palette provided in the configuration file.
#'
#' @return               A leaflet object.
#'
.view_image_raster <- function(cube,
                        class_cube,
                        tiles,
                        dates,
                        band,
                        red,
                        green,
                        blue,
                        legend,
                        palette,
                        opacity) {
    # filter the tiles to be processed
    cube <- .view_filter_tiles(cube, tiles)
    # get the dates
    dates <- .view_set_dates(cube, dates)
    # find out if resampling is required (for big images)
    output_size <- .view_resample_size(
        cube = cube,
        ndates = max(length(dates), 1)
    )
    # create a leaflet and add providers
    leaf_map <- .view_add_basic_maps()
    # get names of basic maps
    base_maps <- .view_get_base_maps(leaf_map)
    # add B/W band if required
    # create a leaflet for B/W bands
    if (.has(band)) {
        leaf_map <- leaf_map |>
            .view_bw_band(
                cube = cube,
                band = band,
                dates = dates,
                output_size = output_size,
                palette = palette
            )
    } else {
        # add RGB bands if required
        # create a leaflet for RGB bands
        leaf_map <- leaf_map |>
            .view_rgb_bands(
                cube = cube,
                red = red,
                green = green,
                blue = blue,
                dates = dates,
                output_size = output_size
            )
    }
    # include class cube if available
    leaf_map <- leaf_map |>
        .view_class_cube(
            class_cube = class_cube,
            tiles = tiles,
            legend = legend,
            palette = palette,
            opacity = opacity,
            output_size = output_size
        )
    # get overlay groups
    overlay_groups <- .view_add_overlay_grps(
        cube = cube,
        dates = dates,
        class_cube = class_cube
    )
    # add layers control to leafmap
    leaf_map <- leaf_map |>
        leaflet::addLayersControl(
            baseGroups = base_maps,
            overlayGroups = overlay_groups,
            options = leaflet::layersControlOptions(collapsed = FALSE)
        ) |>
        # add legend to leaf_map
        .view_add_legend(
            cube = class_cube,
            legend = legend,
            palette = palette
        )
    return(leaf_map)
}
#' @title  Include leaflet to view vector images
#' @name .view_image_vector
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  cube          Cube to be plotted (vector or raster cube)
#' @param  tiles         Tiles to be plotted (in case of a multi-tile cube).
#' @param  dates         Dates to be plotted.
#' @param  band          For plotting grey images.
#' @param  red           Band for red color.
#' @param  green         Band for green color.
#' @param  blue          Band for blue color.
#' @param  class_cube    Classified cube to be overlayed on top on image
#' @param  legend        Named vector that associates labels to colors.
#' @param  opacity       Opacity of segment fill
#' @param  palette       Palette provided in the configuration file.
#' @param  seg_color     Color for segments
#' @param  line_width    Line width for segments
#'
#' @return               A leaflet object.
#'
.view_image_vector <- function(cube,
                               tiles,
                               dates,
                               band,
                               red,
                               green,
                               blue,
                               class_cube,
                               legend,
                               palette,
                               opacity,
                               seg_color,
                               line_width) {
    # filter the tiles to be processed
    cube <- .view_filter_tiles(cube, tiles)
    # find out if resampling is required (for big images)
    output_size <- .view_resample_size(
        cube = cube,
        ndates = max(length(dates), 1)
    )
    # create a leaflet and add providers
    leaf_map <- .view_add_basic_maps()
    # get names of basic maps
    base_maps <- .view_get_base_maps(leaf_map)
    # add B/W band if required
    # create a leaflet for B/W bands
    if (.has(band)) {
        if (.has_not(dates))
            dates <- .cube_timeline(cube)[[1]][[1]]
        leaf_map <- leaf_map |>
            .view_bw_band(
                cube = cube,
                band = band,
                dates = dates,
                output_size = output_size,
                palette = palette
            )
    }
    # add RGB bands if required
    # create a leaflet for RGB bands
    if (.has(red) && .has(green) && .has(blue)) {
        # update the dates parameter
        if (.has_not(dates))
            dates <- .cube_timeline(cube)[[1]][[1]]
        leaf_map <- leaf_map |>
            .view_rgb_bands(
                cube = cube,
                red = red,
                green = green,
                blue = blue,
                dates = dates,
                output_size = output_size
            )
    }
    # include segments (and class cube if available)
    leaf_map <- leaf_map |>
        # include segments
        .view_segments(
            cube = cube,
            seg_color = seg_color,
            line_width = line_width,
            opacity  = opacity,
            legend = legend,
            palette = palette
        ) |>
        .view_class_cube(
            class_cube = class_cube,
            tiles = tiles,
            legend = legend,
            palette = palette,
            opacity = opacity,
            output_size = output_size
        )
    # have we included base images?

    # get overlay groups
    overlay_groups <- .view_add_overlay_grps(
        cube = cube,
        dates = dates,
        class_cube = class_cube
    )
    # add layers control to leafmap
    leaf_map <- leaf_map |>
        leaflet::addLayersControl(
            baseGroups = base_maps,
            overlayGroups = overlay_groups,
            options = leaflet::layersControlOptions(collapsed = FALSE)
        ) |>
        # add legend to leaf_map
        .view_add_legend(
            cube = cube,
            legend = legend,
            palette = palette
        )
    return(leaf_map)
}
#' @title  Return the size of the imaged to be resamples for visulization
#' @name .view_resample_size
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  cube          Cube with tiles to be merged.
#' @param  ndates        Number of dates to be viewed.
#' @return               Number of rows and cols to be visualized.
#'
#'
.view_resample_size <- function(cube, ndates) {
    # check number of tiles
    ntiles <- nrow(cube)
    # get the compression factor
    comp <- .conf("leaflet_comp_factor")
    # size of data to be read
    max_size <- .conf("view_max_size")
    sizes <- .tile_overview_size(tile = .tile(cube), max_size)
    xsize <- sizes[["xsize"]]
    ysize <- sizes[["ysize"]]
    leaflet_maxbytes <- 4 * xsize * ysize * ndates * ntiles * comp
    return(c(
        xsize = xsize,
        ysize = ysize,
        leaflet_maxbytes = leaflet_maxbytes
    ))
}
#' @title  Visualize a set of samples
#' @name .view_samples
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  samples       Data.frame with columns "longitude", "latitude"
#'                       and "label"
#' @param  legend        Named vector that associates labels to colors.
#' @param  palette       Palette provided in the configuration file.
#' @return               A leaflet object
#'
.view_samples <- function(samples, legend, palette) {
    .check_set_caller(".view_samples")
    # first select unique locations
    samples <- dplyr::distinct(
        samples,
        .data[["longitude"]],
        .data[["latitude"]],
        .data[["label"]]
    )
    # convert tibble to sf
    samples <- sf::st_as_sf(
        samples[c("longitude", "latitude", "label")],
        coords = c("longitude", "latitude"),
        crs = "EPSG:4326"
    )
    # get the bounding box
    samples_bbox <- sf::st_bbox(samples)
    # get the labels
    labels <- sort(unique(samples[["label"]]))

    # if colors are not specified, get them from the configuration file
    if (.has_not(legend)) {
        colors <- .colors_get(
            labels = labels,
            legend = NULL,
            palette = palette,
            rev = TRUE
        )
    } else {
        .check_chr_within(
            labels,
            within = names(legend)
        )
        colors <- unname(legend[labels])
    }
    # create a pallete of colors
    factpal <- leaflet::colorFactor(
        palette = colors,
        domain = labels
    )
    # create a leaflet and add providers
    leaf_map <- .view_add_basic_maps()
    leaf_map <- leaf_map |>
        leaflet::flyToBounds(
            lng1 = samples_bbox[["xmin"]],
            lat1 = samples_bbox[["ymin"]],
            lng2 = samples_bbox[["xmax"]],
            lat2 = samples_bbox[["ymax"]]
        ) |>
        leaflet::addCircleMarkers(
            data = samples,
            color = ~ factpal(label),
            radius = 4,
            stroke = FALSE,
            fillOpacity = 1,
            group = "Samples"
        ) |>
        leaflet::addLayersControl(
            baseGroups = c("ESRI", "GeoPortalFrance", "OSM"),
            overlayGroups = "Samples",
            options = leaflet::layersControlOptions(collapsed = FALSE)
        ) |>
        leaflet::addLegend("topright",
            pal     = factpal,
            values  = samples[["label"]],
            title   = "Training Samples",
            opacity = 1
        )
    return(leaf_map)
}
#' @title  Create a leafmap to view basic background maps
#' @name .view_add_basic_maps
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @return          Leafmap with maps from providers
#'
.view_add_basic_maps <- function() {
    # create a leaflet and add providers
    leaf_map <- leaflet::leaflet() |>
        leaflet::addProviderTiles(
            provider = leaflet::providers[["GeoportailFrance.orthos"]],
            group = "GeoPortalFrance"
        ) |>
        leaflet::addProviderTiles(
            provider = leaflet::providers[["Esri.WorldImagery"]],
            group = "ESRI"
        ) |>
        leaflet::addProviderTiles(
            provider = leaflet::providers[["OpenStreetMap"]],
            group = "OSM"
        ) |>
        leaflet::addWMSTiles(
            baseUrl = "https://tiles.maps.eox.at/wms/",
            layers = "s2cloudless-2020_3857_512",
            group = "Sentinel-2-2020"
        ) |>
        leafem::addMouseCoordinates()
    return(leaf_map)
}
#' @title  Set the maximum megabyte value for leafmaps
#' @name .view_set_max_mb
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#' @param  view_max_mb   Leafmap size set by user
#' @return               Valid leafmap size
#'
.view_set_max_mb <- function(view_max_mb) {
    # get the maximum number of bytes to be displayed (total)
    if (.has_not(view_max_mb)) {
        view_max_mb <- .conf("leaflet_megabytes")
    } else {
        .check_num(
            x = view_max_mb,
            is_integer = TRUE,
            min = .conf("leaflet_min_megabytes"),
            max = .conf("leaflet_max_megabytes"),
            msg = paste(.conf("messages", ".view_set_max_mb"),
                        .conf("leaflet_min_megabytes"), "MB & ",
                        .conf("leaflet_max_megabytes"), "MB")
        )
    }
    return(view_max_mb)
}
#' @title  Include leaflet to view segments
#' @name .view_segments
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  leafmap       Leaflet map
#' @param  cube          Vector cube
#' @param  seg_color     Color for segments boundaries
#' @param  line_width    Line width for segments (in pixels)
#' @param  opacity       Opacity of segment fill
#' @param  legend        Named vector that associates labels to colors.
#' @param  palette       Palette provided in the configuration file.
#'
#' @return               A leaflet object
#
.view_segments <- function(leaf_map,
                           cube,
                           seg_color,
                           line_width,
                           opacity,
                           legend,
                           palette) {
    # retrieve segments on a tile basis
    for (row in seq_len(nrow(cube))) {
        # get tile
        tile <- cube[row, ]
        # retrieve the segments for this tile
        sf_seg <- .segments_read_vec(tile)
        # transform the segments
        sf_seg <- sf::st_transform(
            sf_seg,
            crs = sf::st_crs("EPSG:4326")
        )
        # create a layer with the segment borders
        leaf_map <- leafem::addFeatures(
            leaf_map,
            data = sf_seg,
            color = seg_color,
            opacity = 1,
            fillOpacity = 0,
            weight = line_width,
            group = "segments"
        )
        # have the segments been classified?
        if ("class" %in% colnames(sf_seg)) {
            # dissolve sf_seg
            sf_seg <- sf_seg |>
                dplyr::group_by(.data[["class"]]) |>
                dplyr::summarise()
            labels_seg <- sf_seg |>
                sf::st_drop_geometry() |>
                dplyr::select("class") |>
                dplyr::pull()
            # get the names of the labels
            names(labels_seg) <- seq_along(labels_seg)
            # obtain the colors
            colors <- .colors_get(
                labels = labels_seg,
                legend = legend,
                palette = palette,
                rev = TRUE
            )
            # add a new leafmap to show polygons of segments
            leaf_map <- leafem::addFeatures(
                leaf_map,
                data = sf_seg,
                label = labels_seg,
                color = seg_color,
                stroke = FALSE,
                weight = line_width,
                opacity = 1,
                fillColor = unname(colors),
                fillOpacity = opacity,
                group = "class_segments"
            )
        }
    }
    return(leaf_map)
}
#' @title  Include leaflet to view B/W band
#' @name .view_bw_band
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  leafmap       Leaflet map
#' @param  cube          Data cube
#' @param  band          Band to be shown
#' @param  dates         Dates to be plotted
#' @param  palette       Palette to show false colors
#' @param  output_size   Controls size of leaflet to be visualized
#' @return               A leaflet object
#
.view_bw_band <- function(leaf_map,
                          cube,
                          band,
                          dates,
                          palette,
                          output_size) {

    # adjust palette for SAR images
    palette <- .view_adjust_palette(cube, palette)
    # obtain the raster objects for the dates chosen
    for (i in seq_along(dates)) {
        date <- as.Date(dates[[i]])
        for (row in seq_len(nrow(cube))) {
            # get tile
            tile <- cube[row, ]
            # check if date is inside the timeline
            tile_dates <- sits_timeline(tile)
            if (!date %in% tile_dates) {
                idx_date <- which.min(abs(date - tile_dates))
                date <- tile_dates[idx_date]
            }
            # filter by date and band
            band_file <- .tile_path(tile, band, date)
            # plot a single file
            leaf_map <- .view_add_stars_image(
                leaf_map = leaf_map,
                band_file = band_file,
                tile = tile,
                band = band,
                date = date,
                palette = palette,
                output_size = output_size
            )
        }
    }
    return(leaf_map)
}
#' @title  Include leaflet to view RGB bands
#' @name .view_rgb_bands
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  leafmap       Leaflet map
#' @param  cube          Data cube
#' @param  red           Band to be shown in red color
#' @param  green         Band to be shown in green color
#' @param  blue          Band to be shown in blue color
#' @param  dates         Dates to be plotted
#' @param  output_size   Controls size of leaflet to be visualized
#' @return               A leaflet object
#
.view_rgb_bands <- function(leaf_map,
                            cube,
                            red,
                            green,
                            blue,
                            dates,
                            output_size) {
    # obtain the raster objects for the dates chosen
    for (i in seq_along(dates)) {
        date <- as.Date(dates[[i]])
        for (row in seq_len(nrow(cube))) {
            # get tile
            tile <- cube[row, ]
            # check if date is inside the timeline
            tile_dates <- sits_timeline(tile)
            if (!date %in% tile_dates) {
                idx_date <- which.min(abs(date - tile_dates))
                date <- tile_dates[idx_date]
            }
            # filter by date and band
            # if there is only one band, RGB files will be the same
            red_file <- .tile_path(tile, red, date)
            green_file <- .tile_path(tile, green, date)
            blue_file <- .tile_path(tile, blue, date)

            # do we need to warp the image
            # used for SAR images without tiling system
            if (tile[["tile"]] == "NoTilingSystem")  {
                red_file <- .gdal_warp_grd(red_file, output_size)
                green_file <- .gdal_warp_grd(green_file, output_size)
                blue_file <- .gdal_warp_grd(blue_file, output_size)
            }

            rgb_files <- c(r = red_file, g = green_file, b = blue_file)
            st_obj <- stars::read_stars(
                rgb_files,
                along = "band",
                RasterIO = list(
                    nBufXSize = output_size[["xsize"]],
                    nBufYSize = output_size[["ysize"]]
                ),
                proxy = FALSE
            )
            # resample and warp the image
            st_obj_new <- stars::st_warp(
                src = st_obj,
                crs = sf::st_crs("EPSG:3857")
            )
            # add raster RGB to leaflet
            leaf_map <- leafem::addRasterRGB(
                leaf_map,
                x = st_obj_new,
                r = 1,
                g = 2,
                b = 3,
                quantiles = c(0.1, 0.9),
                project = FALSE,
                group = paste(tile[["tile"]], date),
                maxBytes = output_size[["leaflet_maxbytes"]]
            )
        }
    }
    return(leaf_map)
}

#' @title  Include leaflet to view classified cube
#' @name .view_class_cube
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  leafmap       Leaflet map
#' @param  class_cube    Classified cube to be overlayed on top on image
#' @param  tiles         Tiles to be plotted (in case of a multi-tile cube).
#' @param  legend        Named vector that associates labels to colors.
#' @param  palette       Palette provided as alternative legend.
#' @param  opacity       Fill opacity
#' @param  output_size   Controls size of leaflet to be visualized
#'
.view_class_cube <- function(leaf_map,
                             class_cube,
                             tiles,
                             legend,
                             palette,
                             opacity,
                             output_size) {
    # set caller to show in errors
    .check_set_caller(".view_class_cube")
    # should we overlay a classified image?
    if (.has(class_cube)) {
        # check that class_cube is valid
        .check_that(inherits(class_cube, "class_cube"))
        # get the labels
        labels <- unlist(.cube_labels(class_cube, dissolve = FALSE))
        if (.has_not(names(labels))) {
            names(labels) <- seq_along(labels)
        }
        # obtain the colors
        colors <- .colors_get(
            labels = labels,
            legend = legend,
            palette = palette,
            rev = TRUE
        )
        # select the tiles that will be shown
        if (.has(tiles)) {
            class_cube <- dplyr::filter(
                class_cube,
                .data[["tile"]] %in% tiles
            )
        }

        # create the stars objects that correspond to the tiles
        st_objs <- slider::slide(class_cube, function(tile) {
            # obtain the raster stars object
            st_obj <- stars::read_stars(
                .tile_path(tile),
                RAT = labels,
                RasterIO = list(
                    nBufXSize = output_size[["xsize"]],
                    nBufYSize = output_size[["ysize"]]
                ),
                proxy = FALSE
            )
            return(st_obj)
        })
        # keep the first object
        st_merge <- st_objs[[1]]
        # if there is more than one stars object, merge them
        if (length(st_objs) > 1) {
            st_merge <- stars::st_mosaic(
                st_objs[[1]],
                st_objs[[2:length(st_objs)]]
            )
        }
        # resample and warp the image
        st_obj_new <- stars::st_warp(
            src = st_merge,
            crs = sf::st_crs("EPSG:3857")
        )
        # add the classified image object
        leaf_map <- leaf_map |>
            leafem::addStarsImage(
                x = st_obj_new,
                opacity = opacity,
                colors = colors,
                method = "ngb",
                group = "classification",
                project = FALSE,
                maxBytes = output_size[["leaflet_maxbytes"]]
            )
    }
    return(leaf_map)
}
.view_add_stars_image <- function(leaf_map,
                                  band_file,
                                  tile,
                                  band,
                                  date,
                                  palette,
                                  output_size) {
    # do we need to warp the image
    # used for SAR images without tiling system
    if (inherits(tile, "grd_cube"))  {
        band_file <- .gdal_warp_grd(band_file, output_size)
    }

    # create a stars object
    st_obj <- stars::read_stars(
        band_file,
        along = "band",
        RasterIO = list(
            nBufXSize = output_size[["xsize"]],
            nBufYSize = output_size[["ysize"]]
        ),
        proxy = FALSE
    )
    # clip the image
    if (inherits(tile, "rtc_cube"))
        st_obj <- st_obj[st_obj <= 1.0]
    if (.has(date)) {
        group <- paste(tile[["tile"]], date)
    } else {
        group <- paste(tile[["tile"]], band)
    }
    # add stars to leaflet
    leaf_map <- leafem::addStarsImage(
        leaf_map,
        x = st_obj,
        band = 1,
        colors = palette,
        project = TRUE,
        group = group,
        maxBytes = output_size[["leaflet_maxbytes"]]
    )
    return(leaf_map)
}
#' @title  Set the dates for visualisation
#' @name .view_set_dates
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  cube          Cube.
#' @param  dates         Dates to be viewed.
#' @return               Valid dates
#'
#'
.view_set_dates <- function(cube, dates) {
    # get the timeline
    timeline <- .cube_timeline(cube)[[1]]

    if (.has_not(dates)) {
        dates <- timeline[[1]]
    }
    return(dates)
}
#' @title  Select the tiles to be visualised
#' @name .view_filter_dates
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  cube          Cube
#' @param  tiles         Tiles to be viewed.
#' @return               Cube subset to be viewed
#'
#'
.view_filter_tiles <- function(cube, tiles) {
    .check_set_caller(".view_filter_tiles")
    # try to find tiles in the list of tiles of the cube
    .check_that(all(tiles %in% cube[["tile"]]))
    # filter the tiles to be processed
    cube <- .cube_filter_tiles(cube, tiles)
    return(cube)
}
#' @title  Get the labels for a classified vector cube
#' @name .view_get_labels_raster
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  class_cube    Classified raster cube
#' @return               Labels
#'
#'
.view_get_labels_raster <- function(class_cube) {
    labels <- unlist(.cube_labels(class_cube, dissolve = FALSE))
    return(labels)
}
#' @title  Get the labels for a classified vector cube
#' @name .view_get_labels_vector
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  cube          Classified vector cube
#' @param  legend        Class legend
#' @param  palette       Color palette
#' @return               Leaflet map with legend
#'
#'
.view_get_labels_vector <- function(cube,
                                    legend = NULL,
                                    palette = NULL) {
    # get segments from cube
    labels <- slider::slide(cube, function(tile) {
        # retrieve the segments for this tile
        segments <- .segments_read_vec(tile)
        # dissolve segments
        segments <- segments |>
            dplyr::group_by(.data[["class"]]) |>
            dplyr::summarise()
        # get the labels
        labels_tile <- segments |>
            sf::st_drop_geometry() |>
            dplyr::select("class") |>
            dplyr::pull()
        return(labels_tile)
    })
    labels <- unique(unlist(labels))
    return(labels)
}
#' @title  Add a legend to the leafmap
#' @name .view_add_legend
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  leaf_map      Leaflet map
#' @param  cube          Vector or raster cube
#' @param  legend        Class legend
#' @param  palette       Color palette
#' @return               Leaflet map with legend
#'
#'
.view_add_legend <- function(leaf_map,
                             cube,
                             legend,
                             palette) {
    # initialize labels
    labels <- NULL

    # obtain labels from class cube
    if (.has(cube)) {
        if (inherits(cube, "class_cube")) {
            labels <- .view_get_labels_raster(cube)
        }
        if (inherits(cube, "class_vector_cube")) {
            labels <- .view_get_labels_vector(cube)
        }
    }
    if (.has(labels)) {
        # obtain labels from vector class cube
        labels <- sort(unname(labels))
        colors <- .colors_get(
            labels = labels,
            legend = legend,
            palette = palette,
            rev = TRUE
        )
        # create a palette of colors
        fact_pal <- leaflet::colorFactor(
            palette = colors,
            domain = labels
        )
        leaf_map <- leaflet::addLegend(
            map = leaf_map,
            position = "topright",
            pal = fact_pal,
            values = labels,
            title = "Classes",
            opacity = 1
        )
    }
    return(leaf_map)
}
#' @title  Add overlay groups to leaflet map
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  cube          Raster cube
#' @param  dates         Dates
#' @param  class_cube    Classified cube
#' @return               Leaflet map with with overlay groups
.view_add_overlay_grps <- function(cube, ...,
                                   dates = NULL,
                                   class_cube = NULL) {
    UseMethod(".view_add_overlay_grps", cube)
}
#'
#' @export
.view_add_overlay_grps.raster_cube <- function(cube, ...,
                                               dates = NULL,
                                               class_cube = NULL) {
    # set caller to show in errors
    .check_set_caller(".view_add_overlay_grps_raster_cube")
    overlay_groups <- NULL
    # raster cube needs dates
    .check_that(.has(dates))
    grps <- unlist(purrr::map(cube[["tile"]], function(tile) {
        paste(tile, dates)
    }))
    overlay_groups <- c(overlay_groups, grps)
    # add class_cube
    if (.has(class_cube))
        overlay_groups <- c(overlay_groups, "classification")
    return(overlay_groups)
}
#'
#' @export
.view_add_overlay_grps.derived_cube <- function(cube, ...,
                                                dates = NULL,
                                                class_cube = NULL) {

    overlay_groups <- NULL
    grps <- unlist(purrr::map(cube[["tile"]], function(tile) {
        paste(tile, .cube_bands(cube))
    }))
    overlay_groups <- c(overlay_groups, grps)
    # add class_cube
    if (.has(class_cube))
        overlay_groups <- c(overlay_groups, "classification")
    return(overlay_groups)
}
#'
#' @export
.view_add_overlay_grps.class_cube <- function(cube, ...,
                                                dates = NULL,
                                                class_cube = NULL) {
    overlay_groups <- "classification"
    return(overlay_groups)
}
#'
#' @export
.view_add_overlay_grps.vector_cube <- function(cube, ...,
                                               dates = NULL,
                                               class_cube = NULL) {
    overlay_groups <- NULL
    if (.has(dates)) {
        grps <- unlist(purrr::map(cube[["tile"]], function(tile) {
            paste(tile, dates)
        }))
        overlay_groups <- c(overlay_groups, grps)
    }
    overlay_groups <- c(overlay_groups, "segments")
    if (inherits(cube, "class_vector_cube"))
        overlay_groups <- c(overlay_groups, "class_segments")
    if (.has(class_cube))
        overlay_groups <- c(overlay_groups, "classification")
    return(overlay_groups)
}
#' @title  Add base maps to leaflet map
#' @name .view_get_base_maps
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  leaf_map      Leaflet
#' @return               Base maps used in leaflet map
#'
.view_get_base_maps <- function(leaf_map) {
    base_maps <- purrr::map_chr(leaf_map[["x"]][["calls"]], function(bm) {
        return(bm[["args"]][[3]])
    })
    return(base_maps)
}
#' @title  Adjust palette for SAR maps
#' @name .view_adjust_palette
#' @keywords internal
#' @noRd
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @param  leaf_map      Leaflet
#' @return               Base maps used in leaflet map
#'
.view_adjust_palette <- function(cube, palette){
    UseMethod(".view_adjust_palette", cube)
}
#' @export
.view_adjust_palette.sar_cube <- function(cube, palette) {
    n_grey_colors <- .conf("sar_cube_grey_colors")
    rgb_vals <- log(1:n_grey_colors, n_grey_colors)
    palette <- grDevices::rgb(red = rgb_vals, green = rgb_vals, blue = rgb_vals)
    return(palette)
}
#' @export
.view_adjust_palette.default <- function(cube, palette) {
    return(palette)
}
