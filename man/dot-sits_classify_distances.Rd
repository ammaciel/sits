% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sits_classification.R
\name{.sits_classify_distances}
\alias{.sits_classify_distances}
\title{Classify a distances tibble using machine learning models}
\usage{
.sits_classify_distances(distances_DT, class_info.tb, ml_model, multicores)
}
\arguments{
\item{distances_DT}{data.table with distances.}

\item{class_info.tb}{classification information.}

\item{ml_model}{model trained by \code{\link[sits]{sits_train}}.}

\item{multicores}{number of threads to process the time series.}
}
\value{
A vector with the predicted labels.
}
\description{
Returns a sits tibble with the results of the ML classifier.
}
\author{
Gilberto Camara, \email{gilberto.camara@inpe.br}
}
