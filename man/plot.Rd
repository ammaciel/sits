% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sits_plot.R
\name{plot}
\alias{plot}
\alias{plot.sits}
\title{Generic interface for ploting time series}
\usage{
\method{plot}{sits}(x, y, ..., colors = "Dark2")
}
\arguments{
\item{x}{object of class "sits"}

\item{y}{ignored}

\item{...}{further specifications for \link{plot}.}

\item{colors}{Color pallete to be used (based on Color Brewer
- default is "Dark2").}
}
\value{
Input sits tibble (useful for chaining functions).
}
\description{
Given a sits tibble with a set of time series, plot them.

The plot function produces different plots based on the input data:
\itemize{
 \item{"all years": }{Plot all samples from the same location together}
 \item{"together": }{Plot all samples of the same band and label together}
}
The plot.sits function makes an educated guess of what plot is required,
based on the input data. If the input data has less than 30 samples, it
will default to "all years". If there are more than 30 samples,
it will default to "together".
}
\examples{
\donttest{
# Read a set of samples with 2 classes ("Cerrado" and "Pasture")
# Plot all the samples together
plot(cerrado_2classes)
# Plot the first 20 samples (defaults to "allyears")
plot(cerrado_2classes[1:20,])
}
}
\author{
Gilberto Camara, \email{gilberto.camara@inpe.br}
}
