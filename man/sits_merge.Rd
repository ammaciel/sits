% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sits_merge.R
\name{sits_merge}
\alias{sits_merge}
\alias{sits_merge.sits}
\alias{sits_merge.sar_cube}
\alias{sits_merge.raster_cube}
\alias{sits_merge.default}
\title{Merge two data sets (time series or cubes)}
\usage{
sits_merge(data1, data2, ...)

\method{sits_merge}{sits}(data1, data2, ..., suffix = c(".1", ".2"))

\method{sits_merge}{sar_cube}(data1, data2, ...)

\method{sits_merge}{raster_cube}(data1, data2, ...)

\method{sits_merge}{default}(data1, data2, ...)
}
\arguments{
\item{data1}{Time series (tibble of class "sits")
or data cube (tibble of class "raster_cube") .}

\item{data2}{Time series (tibble of class "sits")
or data cube (tibble of class "raster_cube") .}

\item{...}{Additional parameters}

\item{suffix}{If there are duplicate bands in data1 and data2
these suffixes will be added
(character vector).}
}
\value{
merged data sets (tibble of class "sits" or
        tibble of class "raster_cube")
}
\description{
To merge two series, we consider that they contain different
attributes but refer to the same data cube, and spatiotemporal location.
This function is useful to merge different bands of the same locations.
For example, one may want to put the raw and smoothed bands
for the same set of locations in the same tibble.

To merge data cubes, they should share the same sensor, resolution,
bounding box, timeline, and have different bands.
}
\examples{
if (sits_run_examples()) {
    # Retrieve a time series with values of NDVI
    point_ndvi <- sits_select(point_mt_6bands, bands = "NDVI")

    # Filter the point using the Whittaker smoother
    point_whit <- sits_filter(point_ndvi, sits_whittaker(lambda = 3.0))
    # Merge time series
    point_ndvi <- sits_merge(point_ndvi, point_whit, suffix = c("", ".WHIT"))

    # Plot the two points to see the smoothing effect
    plot(point_ndvi)
}
}
\author{
Gilberto Camara, \email{gilberto.camara@inpe.br}
}
