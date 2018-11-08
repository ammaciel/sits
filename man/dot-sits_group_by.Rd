% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sits_tibble_utils.R
\name{.sits_group_by}
\alias{.sits_group_by}
\title{Group the contents of a sits tibble by different criteria}
\usage{
.sits_group_by(data.tb, ...)
}
\arguments{
\item{data.tb}{A sits tibble.}

\item{...}{One or more sits tibble field separated by commas that are used to group the data.
See `dplyr::group_by` help for more details.}
}
\value{
A sits tibble with the selected bands.
}
\description{
Returns a sits tibble by compound the sits tibble apply a function to a grouped sits tibble.
}
\author{
Rolf Simoes, \email{rolf.simoes@inpe.br}
}