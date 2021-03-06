#' @title Train a model using the a combination of LSTM and CNN
#' @name sits_LSTM_FCN
#'
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#' @author Alexandre Ywata de Carvalho, \email{alexandre.ywata@@ipea.gov.br}
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#'
#' @description Use a combination of an LSTM (Long Short Term Memory) and a
#' cascade of 1D-CNN newtorks to classify data. Users can define the number of
#' convolutional layers, the size of the convolutional
#' kernels, and the activation functions.
#'
#' #' This function is based on the paper by Karim et al. referenced below
#' and the code made available on github (https://github.com/titu1994/LSTM-FCN)
#' If you use this method, please cite the original paper.
#'
#' @references Fazle Karim, Somshubra Majumdar, Houshang Darabi, Sun Chen,
#' "LSTM fully convolutional networks for time series classification",
#' IEEE Access, 6(1662-1669), 2018.
#'
#'
#' @param data              Time series with the training samples.
#' @param lstm_units        Number of cells in the each LSTM layer
#' @param lstm_dropout      Dropout rate of the LSTM module
#' @param cnn_layers        Number of filters for each 1D CNN layer.
#' @param cnn_kernels       Size of the 1D convolutional kernels.
#' @param activation        Activation function for 1D convolution.
#'                          Valid values:  {'relu', 'elu', 'selu', 'sigmoid'}.
#' @param optimizer         Function with a pointer to the optimizer function
#'                          (default is optimization_adam()).
#'                          Options: optimizer_adadelta(), optimizer_adagrad(),
#'                          optimizer_adam(), optimizer_adamax(),
#'                          optimizer_nadam(), optimizer_rmsprop(),
#'                          optimizer_sgd().
#' @param epochs            Number of iterations to train the model.
#' @param batch_size        Number of samples per gradient update.
#' @param validation_split  Number between 0 and 1. Fraction of training data
#'                          to be used as validation data.
#'                          The model will set apart this fraction of the
#'                          training data, will not train on it,
#'                          and will evaluate the loss and any model metrics
#'                          on this data at the end of each epoch.
#'                          The validation data is selected from the last
#'                          samples in the x and y data provided,
#'                          before shuffling.
#' @param verbose           Verbosity mode (0 = silent, 1 = progress bar,
#'                          2 = one line per epoch).
#'
#' @return A fitted model to be passed to \code{\link[sits]{sits_classify}}
#'
#' @examples
#' \donttest{
#' # Retrieve the set of samples for the Mato Grosso (provided by EMBRAPA)
#'
#' # Build a machine learning model based on deep learning
#' lstm_cnn_model <- sits_train (samples_mt_4bands, sits_LSTM_FCN())
#'
#' # plot the model
#' plot(lstm_cnn_model)
#'
#' # get a point and classify the point with the ml_model
#' point.tb <- sits_select_bands(point_mt_6bands, ndvi, evi, nir, mir)
#' class.tb <- sits_classify(point.tb, lstm_cnn_model)
#' plot(class.tb, bands = c("ndvi", "evi"))
#' }
#' @export
sits_LSTM_FCN <- function(data                =  NULL,
                          lstm_units          = 8,
                          lstm_dropout        = 0.80,
                          cnn_layers          = c(128, 256, 128),
                          cnn_kernels         = c(8, 5, 3),
                          activation          = 'relu',
                        optimizer           = keras::optimizer_adam(lr = 0.001),
                          epochs              = 150,
                          batch_size          = 128,
                          validation_split    = 0.2,
                          verbose             = 1) {
    # backward compatibility
    if ("coverage" %in% names(data))
        data <- .sits_tibble_rename(data)

    # function that returns keras model based on a sits sample data.table
    result_fun <- function(data){

        valid_activations <- c("relu", "elu", "selu", "sigmoid")
        # is the input data consistent?

        assertthat::assert_that(length(cnn_layers) == length(cnn_kernels),
                msg = "sits_LSTM_FCN: 1D CNN layers must match 1D kernels")

        assertthat::assert_that(all(activation %in% valid_activations),
                msg = "sits_LSTM_FCN: invalid CNN activation method")

        # get the labels of the data
        labels <- sits_labels(data)$label
        # create a named vector with integers match the class labels
        n_labels <- length(labels)
        int_labels <- c(1:n_labels)
        names(int_labels) <- labels

        # number of bands and number of samples
        n_bands <- length(sits_bands(data))
        n_times <- nrow(sits_time_series(data[1,]))

        # create the train and test datasets for keras
        keras.data <- .sits_keras_prepare_data(data = data,
                                        validation_split = validation_split,
                                        int_labels = int_labels,
                                        n_bands = n_bands,
                                        n_times = n_times)
        train.x <- keras.data$train.x
        train.y <- keras.data$train.y
        test.x  <- keras.data$test.x
        test.y  <- keras.data$test.y

        # build the model step by step
        # create the input_tensor for 1D convolution
        input_tensor  <- keras::layer_input(shape = c(n_times, n_bands))
        output_tensor <- input_tensor

        # build the LSTM node
        lstm_layer <- keras::layer_permute(input_tensor,
                                           dims = c(2,1))
        lstm_layer <- keras::layer_lstm(input_tensor,
                                        units = lstm_units,
                                        dropout = lstm_dropout)

        # build the 1D nodes
        n_layers <- length(cnn_layers)
        for (i in 1:n_layers) {
            # Add a 1D CNN layer
            output_tensor <- keras::layer_conv_1d(output_tensor,
                                                  filters     = cnn_layers[i],
                                                  kernel_size = cnn_kernels[i])

            # batch normalisation
            output_tensor <- keras::layer_batch_normalization(output_tensor)
            # Layer activation
            output_tensor <- keras::layer_activation(output_tensor,
                                                     activation = activation)
        }

        # Apply average pooling
        output_tensor <- keras::layer_global_average_pooling_1d(output_tensor)

        # Concatenate LSTM and CNN
        output_tensor <- keras::layer_concatenate(list(lstm_layer,
                                                       output_tensor))

        # reshape a tensor into a 2D shape
        output_tensor <- keras::layer_flatten(output_tensor)

        # create the final tensor
        model_loss <- "categorical_crossentropy"
        if (n_labels == 2) {
            output_tensor <- keras::layer_dense(output_tensor,
                                                units = 1,
                                                activation = "sigmoid")
            model_loss <- "binary_crossentropy"
        }
        else {
            output_tensor <- keras::layer_dense(output_tensor,
                                                units = n_labels,
                                                activation = "softmax")
            # keras requires categorical data to be put in a matrix
            train.y <- keras::to_categorical(train.y, n_labels)
            test.y  <- keras::to_categorical(test.y, n_labels)
        }
        # create the model
        model.keras <- keras::keras_model(input_tensor, output_tensor)
        # compile the model
        model.keras %>% keras::compile(
            loss = model_loss,
            optimizer = optimizer,
            metrics = "accuracy"
        )

        # fit the model
        history <- model.keras %>% keras::fit(
            train.x, train.y,
            epochs = epochs, batch_size = batch_size,
            validation_data = list(test.x, test.y),
            verbose = verbose, view_metrics = "auto"
        )

        # show training evolution
        graphics::plot(history)

        # construct model predict closure function and returns
        model_predict <- function(values_DT){
            # transform input (data.table) into a 3D tensor
            # (remove first two columns)
            n_samples <- nrow(values_DT)
            n_times   <- nrow(sits_time_series(data[1,]))
            n_bands   <- length(sits_bands(data))
            values.x <- array(data = as.matrix(values_DT[,3:ncol(values_DT)]),
                              dim = c(n_samples, n_times, n_bands))
            # retrieve the prediction probabilities
            predict_DT <- data.table::as.data.table(stats::predict(model.keras,
                                                                   values.x))
            # If binary classification,
            # adjust the prediction values to match two-class classification
            if (n_labels == 2)
                predict_DT <- .sits_keras_binary_class(predict_DT)

            # adjust the names of the columns of the probs
            colnames(predict_DT) <- labels

            return(predict_DT)
        }
        class(model_predict) <- append(class(model_predict),
                                       "keras_model",
                                       after = 0)
        return(model_predict)
    }

    result <- .sits_factory_function(data, result_fun)
    return(result)
}
