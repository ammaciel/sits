#' @title Return machine learning model inside a closure
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#'
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           ML model as specified by the original ML function
.ml_model <- function(ml_model) {
    if ("model" %in% ls(environment(ml_model))) {
        environment(ml_model)[["model"]]
    } else if ("torch_model" %in% ls(environment(ml_model))) {
        environment(ml_model)[["torch_model"]]
    } else {
        stop(.conf("messages", ".ml_model"))
    }
}
#' @title Return statistics of ML model inside a closure (old version)
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#'
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           Data statistics contained in the model closure
.ml_stats_0 <- function(ml_model) {
    # Old stats variable
    environment(ml_model)[["stats"]]
}
#' @title Return statistics of ML model inside a closure (new version)
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#'
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           Data statistics contained in the model closure
.ml_stats <- function(ml_model) {
    # New stats variable
    environment(ml_model)[["ml_stats"]]
}
#' @title Return samples of ML model inside a closure
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           Samples used for ML construction
.ml_samples <- function(ml_model) {
    environment(ml_model)[["samples"]]
}
#' @title Return class of ML model inside a closure
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           ML model class
.ml_class <- function(ml_model) {
    class(ml_model)[[1]]
}
#' @title Return names of features used to train ML model
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           Features used to build the model
.ml_features_name <- function(ml_model) {
    # Get feature names from variable used in training
    names(environment(ml_model)[["train_samples"]])[-2:0]
}
#' @title Return names of bands used to train ML model
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           Bands used to build the model
.ml_bands <- function(ml_model) {
    .samples_bands(.ml_samples(ml_model))
}
#' @title Return labels of samples of used to train ML model
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           Sample labels used to build the model
.ml_labels <- function(ml_model) {
    .samples_labels(.ml_samples(ml_model))
}
#' @title Return codes of sample labels of used to train ML model
#' @keywords internal
#' @noRd
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#' @param  ml_model  Closure that contains ML model and its environment
#' @return           Codes of sample labels used to build the model
.ml_labels_code <- function(ml_model) {
    labels <- .ml_labels(ml_model)
    names(labels) <- seq_along(labels)
    labels
}
