% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sits_kohonen.R
\name{.sits_som_bayesian_neighbourhood}
\alias{.sits_som_bayesian_neighbourhood}
\title{Paint neurons}
\usage{
.sits_som_bayesian_neighbourhood(kohonen_obj, neurons_labelled.tb, result)
}
\arguments{
\item{kohonen_obj}{Object Kohonen, this object contains all parameters of SOM provided by package Kohonen}

\item{neurons_labelled.tb}{A tibble containing informations about each neuron.}

\item{result}{A tibble with samples.}
}
\value{
Returns the probability of a sample belongs to a cluster based on class of neuron and its neighborhood.
}
\description{
This function compute the probability of a sample belongs to a cluster using bayesian filter.
}
\author{
Lorena Santos, \email{lorena.santos@inpe.br}
}