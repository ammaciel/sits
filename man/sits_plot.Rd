% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sits_plot.R
\name{sits_plot}
\alias{sits_plot}
\title{Plot a set of satellite image time series (deprecated)}
\usage{
sits_plot(data, bands = c("ndvi"), colors = "Dark2")
}
\arguments{
\item{data}{Data to be plotted}

\item{bands}{Bands used for visualisation}

\item{colors}{Color pallete to be used}
}
\value{
Input sits tibble (useful for chaining functions).
}
\description{
Given a sits tibble with a set of time series, plot them.

The plot function produces different plots based on the input data:
\itemize{
 \item{"all years": }{Plot all samples from the same location together}
 \item{"patterns": }{Plot the patterns for a given set of classes}
 \item{"together": }{Plot all samples of the same band and label together}
 \item{"classification": }{Plot the results of a classification}
}
The sits_plot function makes an educated guess of what plot is required,
based on the input data. If the input data has less than 30 samples, it
will default to "all years". If there is only one sample per class, it will
default to "patterns". If there are more than 30 samples, it will default to
"together". If the input data has predicted values resulting from a classification, it will
plot the classification.

WARNING: This function is deprecated. Please use plot() instead.
}
\examples{
\donttest{
# Read a set of samples with 2 classes ("Cerrado" and "Pasture")
data ("cerrado_2classes")
# Plot all the samples together
sits_plot (cerrado_2classes)
# Plot the first 20 samples (defaults to "allyears")
sits_plot (cerrado_2classes[1:20,])
# Plot the patterns
sits_plot (sits_patterns(cerrado_2classes))
# Retrieve the set of samples for Mato Grosso
data(samples_mt_4bands)
samples_mt_ndvi <- sits_select_bands(samples_mt_4bands, bands = ndvi)
model_svm <- sits_train(samples_mt_ndvi, ml_method = sits_svm())
# Retrieve a point
data(point_ndvi)
# classify the point
class_ndvi.tb <-  sits_classify (point_ndvi, model_svm)
# plot the classification
sits_plot (class_ndvi.tb)
}
}
\author{
Gilberto Camara, \email{gilberto.camara@inpe.br}
}
