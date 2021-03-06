% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sits_classification.R
\name{.sits_classify_eocubes}
\alias{.sits_classify_eocubes}
\title{Classify a data cube created with the EOCUBES service}
\usage{
.sits_classify_eocubes(cube, ml_model, interval, filter, memsize, multicores)
}
\arguments{
\item{cube}{Tibble with information about a data cube.}

\item{ml_model}{An R model trained by \code{\link[sits]{sits_train}}.}

\item{interval}{Interval between two sucessive classifications,
expressed in months.}

\item{filter}{Smoothing filter to be applied (if desired).}

\item{memsize}{Memory available for classification (in GB).}

\item{multicores}{Number of cores to be used for classification.}
}
\value{
A tibble with the metadata for the vector of classified RasterLayers.
}
\description{
Takes a set of spatio-temporal raster bricks, whose metadata is
 described by tibble (created by \code{\link[sits]{sits_cube}}),
 a set of samples used for training a classification model,
 a prediction model (created by \code{\link[sits]{sits_train}}),
 and produces a classified set of RasterLayers. This function is similar to
 \code{\link[sits]{sits_classify}} which is applied to time series.
 There are two parameters for optimizing processing of large data sets:
 "memsize" and "multicores". The "multicores" parameter defines the
 number of cores used for processing. The "memsize" parameter  controls
 the amount of memory available for classification.
}
\author{
Rolf Simoes, \email{rolf.simoes@inpe.br}
}
