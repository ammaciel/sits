#' @title Clustering a set of satellite image time series using SOM
#' @name sits_cluster_som
#' @author Lorena Alves, \email{lorena.santos@@inpe.br}
#' @author Karine Ferreira. \email{karine.ferreira@@inpe.br}
#' @description This function uses self-organized maps to find clusters in
#' satellite image time series for quality control of the  samples.
#' It calls the function \code{\link[sits]{sits_som_map}} to generate the som map and
#' \code{\link[sits]{sits_som_clean_samples}} to produce a cleaned set of samples.
#' The parameters "grid_xdim", "grid_ydim", "rlen", "distance", "alpha", and
#' "iterations are used by \code{\link[sits]{sits_som_map}} to control how the Kohonen map
#' is generated. The parameters "prob_label_change" and "min_cluster_prob" control how the
#' good quality samples are selected, based on the Kohonen map.
#'
#' @references `kohonen` package (https://CRAN.R-project.org/package=kohonen)
#'
#' @param data           A tibble with samples to be clustered.
#' @param grid_xdim      X dimension of the SOM grid (default = 25).
#' @param grid_ydim      Y dimension of the SOM grid.
#' @param alpha          Starting learning rate, which decreases according to number of iterations.
#' @param distance       The similarity measure (distance).
#' @param iterations     The number of time to run the SOM cluster.
#' @param prob_label_change      Threshold of probability to change the label
#' @param min_cluster_prob       Minimum probability for a good sample to belong to a cluster
#' @return Returns a sits tibble with a new subset of samples and a new column
#' presenting the probability of each sample belongs to a class described in column label.
#' @examples
#' \donttest{
#' # Get a new subset of samples evaluated by SOM clustering methods
#' new_samples.tb <- sits_cluster_som(prodes_226_064)
#' }
#' @export

sits_cluster_som <- function(data,  grid_xdim = 10, grid_ydim = 10, alpha = 1.0,
                              distance = "euclidean", iterations = 50,
                              prob_label_change = 0.8, min_cluster_prob = 0.6){

    som_cluster <- sits_som_map(data,  grid_xdim, grid_ydim, alpha,
                                 distance, iterations)

    data_clean <- sits_som_clean_samples(som_cluster,
                                         prob_label_change,
                                         min_cluster_prob)

    return(data_clean)
}



#' @title Generate a Kohonen map for quality control of the samples and calculate parameters
#' @name sits_som_map
#' @author Lorena Alves, \email{lorena.santos@@inpe.br}
#' @author Karine Ferreira. \email{karine.ferreira@@inpe.br}
#'
#' @description This function uses package self-organized maps to find clusters in
#' satellite image time series to cluster the  samples. Besides that, this function
#' evaluates the quality of each sample through SOM properties, such as evaluate each
#' sample allocated in aneuron-cluster and its neighbourhood.
#' @references `kohonen` package (https://CRAN.R-project.org/package=kohonen)
#'
#' @param data           A tibble with samples to be clustered.
#' @param grid_xdim      X dimension of the SOM grid (default = 25).
#' @param grid_ydim      Y dimension of the SOM grid.
#' @param alpha          Starting learning rate, which decreases according to number of iterations.
#' @param distance       The type of similarity measure (distance).
#' @param iterations     The number of time to run the SOM cluster.
#' @param  ...           Additional parameters to be passed to kohonen::supersom function.
#' @return               Returns a list of sits tibbles containing statistics about the samples and the neuron in each iteration.
#' Besides that, the data is returned with the columns presenting the probability of a sample belongs to a cluster based on a frequency
#' that a sample was allocated in a neuron, and finally a column presenting the total probability of a sample belongs to a cluster using data of neighbourhood.
#'
#' @examples
#' \donttest{
#' # Produce a cluster map
#' som_cluster <- sits_som_map(prodes_226_064)
#' # Clean the samples to get better quality ones
#' clean_samples <- sits_som_clean_samples(som_cluster)
#' }
#' @export
sits_som_map <- function(data,
                             grid_xdim = 10,
                             grid_ydim = 10,
                             alpha = 1.0,
                             distance = "euclidean",
                             iterations = 50)

    {
    # backward compatibility
    if ("coverage" %in% names(data))
        data <- .sits_tibble_rename(data)
    # does the input data exist?
    .sits_test_tibble(data)
    # is are there more neurons than samples?
    n_samples <- nrow(data)
    assertthat::assert_that(n_samples > grid_xdim*grid_ydim,
        msg = "sits_som_map: number of samples should be
               greater than number of neurons")

    # get the time series
    time_series <- sits_values(data, format = "bands_cases_dates")

    #initialize tibbles
    neurons_info_t.tb <- tibble::as_tibble()
    samples_info_t.tb <- tibble::as_tibble()

    #Create an if here. The user can be enter with only data, then we need
    # to extract the time series here using sits_value
    for (k in seq_len(iterations))
    {
        kohonen_obj <-
            kohonen::supersom(
                time_series,
                grid = kohonen::somgrid(grid_xdim, grid_ydim ,
                                        "rectangular", "gaussian",
                                        toroidal = FALSE),
                rlen = 100,
                alpha = alpha,
                dist.fcts = distance,
                normalizeDataLayers = TRUE,
                mode = "pbatch"
            )

        #put id in samples here, because the labell needs
        data$id_sample <- 1:rep(dim(data)[1])

        # create a tibble to store the results

        result <- data
        #result$id_sample <- 1:(dim(result)[1])

        #add the in sample the id of neuron that the sample was allocated
        result$id_neuron <- kohonen_obj$unit.classif
        #result$neuron_label <- "neuron_label"

        #get the size grid
        grid_size <- dim(kohonen_obj$grid$pts)[1]

        #create an id for vinicity
        neighborhood_neurons <- rep(1:grid_size)

        #get label
        neurons_labelled <- .sits_som_labelling_neurons_frequency(result,
                                                                  kohonen_obj)

        neuron_id_class <-  unique(dplyr::select(neurons_labelled,
                                                 id_neuron,
                                                 neuron_class))
        duplicated_id_neuron <- (neuron_id_class %>%
             dplyr::mutate(dup_neuron = duplicated(id_neuron)) %>%
             dplyr::filter(dup_neuron))$id_neuron

        if (length(duplicated_id_neuron) != 0) {
            neurons_labelled.tb <-
                .sits_som_tie_breaking_neuron_labelling(neurons_labelled,
                                                        kohonen_obj,
                                                        duplicated_id_neuron)
        }
        else {
            neurons_labelled.tb <- neurons_labelled
        }

        #provavelmente alterar a funcao de vizinhança - corrigir_
        neighborhood <- .sits_som_neighbor_neurons(neurons_labelled.tb,
                                                   kohonen_obj,
                                                   duplicated_id_neuron, 1)
        table_neurons <- neighborhood

        #This table contain id and neuron label
        id_neuron_class.tb <- (unique(dplyr::select(neurons_labelled.tb,
                                                    id_neuron,
                                                    neuron_class)))

        #Vector containing only the label of each neuron
        neurons_label.vec <- (unique(dplyr::select(neurons_labelled.tb,
                                                   id_neuron,
                                                   neuron_class)))$neuron_class

        #Create an integer to correspond a class
        class_vector_int <- as.integer(factor(neurons_label.vec))

        # Matrix with label and its correspondent factor
        neuron_label_id.mt <- cbind(neurons_label.vec, class_vector_int)

        #Por euqnaunto nao ta usando pra nada (apagar)
        table_class_matrix_id <- (unique(neuron_label_id.mt))

        #Get the id of neuron of each sample.
        #This vector must have the same lengh of  samples.tb
        neurons_ <- result$id_neuron

        # The neuron(label) where the samples was allocated
        neuron_label_for_each_sample <- neuron_label_id.mt[neurons_]
        result$neuron_label <- neuron_label_for_each_sample

        kohonen_obj$neuron_label <- neurons_label.vec
        kohonen_obj$neuron_label_id.mt <- neuron_label_id.mt
        kohonen_obj$neighborhood_neurons <- neighborhood_neurons

        #Bayesian filter
        samples_probability_i.tb <-
            .sits_som_bayesian_neighbourhood(kohonen_obj,
                                             neurons_labelled.tb,
                                             result)

        #In the last iteration, the neuros will be painted.
        #The map plot will be of the last iteration
        if (iterations == k)
            kohonen_obj <- .sits_som_paint_neurons(kohonen_obj)

        #until here is common sits_kohonen (improve this function)
        table_samples <- tibble::as_tibble(
         list(
          id_sample = as.integer(samples_probability_i.tb$id_sample),
          original_label = as.character(samples_probability_i.tb$label),
          neuron_label = as.character(samples_probability_i.tb$neuron_label),
          id_neuron = as.integer(samples_probability_i.tb$id_neuron),
          probability = as.numeric(samples_probability_i.tb$probability_cluster),
          iteration = as.integer(k)
            )
        )

        table_neurons$iteration <- k

        #These tables contain informtion with all samples over all iterations
        #id_sample, original_label, neuron_label, id_neuron, Iteration
        #id_neuron, neuron_label and iteration_Neuron
        samples_info_t.tb <- rbind(samples_info_t.tb,table_samples)
        neurons_info_t.tb <- rbind(neurons_info_t.tb,table_neurons)
    }

    #Get the median of the samples during all iterations by id
    id_median.tb <- samples_info_t.tb %>%
        dplyr::group_by(id_sample) %>%
        dplyr::summarise(median = median(probability, na.rm = TRUE))

    cluster_som <- NULL
    cluster_som$samples <- samples_info_t.tb
    cluster_som$neuron <- neurons_info_t.tb

    #This table shows the probability of a sample belongs to a class
    # without look neighbourhood
    sample_cluster_probability.tb <- .sits_som_cluster_probability(cluster_som)

    cluster_sample_probability <- sample_cluster_probability.tb %>%
        dplyr::inner_join(id_median.tb, by = "id_sample")
    samples_statistics_overall.tb <- dplyr::select(cluster_sample_probability,
                                             id_sample,
                                             som_label = neuron_label,
                                             cluster_probability = percentage_s,
                                             total_probability = median)

    samples_statistics_overall.tb <- samples_statistics_overall.tb %>%
        dplyr::mutate(total_probability = total_probability*100)
    samples <- data %>%
        dplyr::inner_join(samples_statistics_overall.tb, by = "id_sample")

    cluster_som$cluster_sample_probability <- cluster_sample_probability

    som_map.lst <-
        structure(
            list(
                statistics_samples = cluster_som,
                som_properties = kohonen_obj,
                samples.tb = samples
            ),
            class = "sits"
        )
    class(som_map.lst) <- append(class(som_map.lst), "som_map", after = 0)
    return(som_map.lst)
}

#' @title Clean samples
#' @name sits_som_clean_samples
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#' @author Karine Ferreira. \email{karine.ferreira@@inpe.br}
#'
#' @description This function remove sample that do not have good quality based
#' on the statistics of the result of the clustering using SOM.
#'
#' @param som_cluster            Result of \code{\link[sits]{sits_som_map}}
#' @param prob_label_change      Threshold of probability to change the label
#' @param min_cluster_prob       Minimum probability for a good sample
#'                               to belong to a cluster
#' @return                       Returns a sits tibble with a
#'                               new subset of samples and a new column
#'                               with the probability that each sample belongs
#'                               to the class described in label.
#'
#' @examples
#' \donttest{
#' # Read a set of samples
#' # Get a new subset of samples evaluated by clustering methods
#' som_cluster <- sits_som_map(prodes_226_064, grid_xdim = 10, grid_ydim = 10,
#'        distance = "euclidean", iterations = 50)
#' new_samples <- sits_som_clean_samples(som_cluster)
#' }
#' @export

sits_som_clean_samples <- function(som_cluster,
                                   prob_label_change = 0.8,
                                   min_cluster_prob = 0.6) {

    data <-
        unique(
            dplyr::select(
                som_cluster$samples.tb,
                id_sample,
                longitude,
                latitude,
                start_date,
                end_date,
                label,
                cube,
                time_series
            )
        )
    data$id_sample <- 1:rep(dim(data)[1])

    #Get samples that have different original_label and majority cluster
    confused_samples <-
        dplyr::filter(
        som_cluster$statistics_samples$cluster_sample_probability,
        som_cluster$statistics_samples$cluster_sample_probability$original_label
            != som_cluster$statistics_samples$cluster_sample_probability$cluster
        )

    #Get sample with high value of probability to change the label
    samples_to_change_label <- dplyr::filter(confused_samples,
                                  confused_samples$median > prob_label_change)
    id_change_samples <- unique(samples_to_change_label$id_sample)

    #Get the "good samples"
    matching_samples.tb <-
    dplyr::filter(
      som_cluster$statistics_samples$cluster_sample_probability,
      (som_cluster$statistics_samples$cluster_sample_probability$original_label
         == som_cluster$statistics_samples$cluster_sample_probability$cluster)
      & som_cluster$statistics_samples$cluster_sample_probability$percentage_s >
            min_cluster_prob
    )

    id_matching_samples.tb <- unique(matching_samples.tb$id_sample)
    samples_cleaned.tb <- dplyr::filter(data,
                               data$id_sample %in% id_matching_samples.tb)
    samples_median.tb <- unique(dplyr::select(
        som_cluster$statistics_samples$cluster_sample_probability,
        id_sample,
        probability = median)
        )

    if ( length(id_change_samples) != 0)
    {
        samples_to_change_id_cluster <- dplyr::arrange(unique(dplyr::select(
                                                        samples_to_change_label,
                                                        id_sample, cluster)),
                                        id_sample)

        samples_label_changed.tb <- dplyr::arrange(dplyr::filter(data,
                                         data$id_sample %in% id_change_samples),
                                    id_sample)

        samples_temp.tb <- dplyr::arrange(rbind(samples_cleaned.tb,
                                                samples_label_changed.tb ),
                           id_sample)
    } else {
        samples_temp.tb <- dplyr::arrange((samples_cleaned.tb), id_sample)
    }
    samples.tb <- samples_temp.tb %>%
        dplyr::inner_join(samples_median.tb, by = "id_sample")

    return(samples.tb)

}

#' @title Labelling neurons
#' @name .sits_som_labelling_neurons_frequency
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#'
#' @description Compute the probability of a neuron belongs to a class.
#' However the neuron is labelled using the majority voting.
#' If the neuron is empty, it will labeled as "NoClass".
#'
#' @param data      A SITS tibble with info of samples and kohonen.obj.
#' @param kohonen_obj  The kohonen object returned by kohonen package.
#' @return Returns the probability that a neuron belongs
#'         to each class and a majority label which is the neuron is labelled.
#'
.sits_som_labelling_neurons_frequency <- function(data, kohonen_obj)
{
    neuron_label.tb <- tibble::as_tibble()
    grid_size <- dim(kohonen_obj$grid$pts)[1]

    #class_vector <- vector()
    for (i in seq_len(grid_size))
    {
        #Get the id of samples that were allocated in neuron i
        neuron_i <- dplyr::filter(data, data$id_neuron == i)$id_sample
        vb <- neuron_i

        #Check if the neuron is empty or full
        if (length(vb) != 0)
        {
            alloc_neurons_i <- data[neuron_i, ]
            data.vec <- table(alloc_neurons_i$label)

            result <- tibble::as_tibble(list(
                id_neuron = as.numeric(i),
                label_samples = names(data.vec),
                count = as.integer(data.vec),
                freq  = as.numeric(prop.table(data.vec))
            ))

            max_class <- dplyr::summarize(result, max.pt = max(count))

            neuron_class <- dplyr::filter(result,
                        result$count == as.integer(max_class))$label_samples

        } else if (length(vb) == 0){
            neuron_class <- 'Noclass'
            result <- tibble::as_tibble(list(
                id_neuron = as.numeric(i),
                label_samples = "NoSamples",
                count = 0,
                freq  = 0
            ))
        }

        if ((length(neuron_class) != 1 ) &
            (length(neuron_class) < dim(result)[1]))
        {
            neuron_class <- append(neuron_class, neuron_class,
                                   after = length(neuron_class) + 1)
            neuron_class <- neuron_class[1:dim(result)[1]]
        }
        result$neuron_class <- neuron_class
        neuron_label.tb <- rbind(neuron_label.tb,result)
    }

    return(neuron_label.tb)
}

#' @title Tie breaking neuron labelling
#' @name .sits_som_tie_breaking_neuron_labelling
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#'
#' @description This function does tie breaking for neurons
#'              that have the same rate to belong a class.
#'
#' @param class_vector          A vector contained the labels of each neuron.
#' @param kohonen_obj           The kohonen object returned by kohonen package.
#' @param duplicated_id_neuron  A vector containing the id of each neuron
#'                              that has two majority labels.
#'
#' @return Return a new majority label of a neuron based on its neighbourhood
#'
.sits_som_tie_breaking_neuron_labelling <- function(class_vector,
                                                    kohonen_obj,
                                                    duplicated_id_neuron)
{
    for (i in seq_along(duplicated_id_neuron))
    {
        neurons_neighbors <- which(kohonen::unit.distances(
                           kohonen_obj$grid)[, duplicated_id_neuron[i]] == 1)
        neuron <- dplyr::filter(class_vector,
                           class_vector$id_neuron == duplicated_id_neuron[i])

        #tiebreaker
        viz_neu <- which(kohonen::unit.distances(
                           kohonen_obj$grid)[, duplicated_id_neuron[i]] == 1)

        #remove duplicate neigbour
        datvec <- viz_neu[!(viz_neu %in% duplicated_id_neuron)]

        #What is the class of this neihgbour?
        class_neighbors.tb <- dplyr::filter(class_vector,
                                            class_vector$id_neuron %in% datvec)
        class_neighbors.tb <- unique(dplyr::select(class_neighbors.tb,
                                                   id_neuron, neuron_class))

        label_samples_current_neuron <- dplyr::filter(class_vector,
            class_vector$id_neuron == duplicated_id_neuron[i])$neuron_class
        summary_frequency <- table(class_neighbors.tb$neuron_class)

        majority_vincinity <- sort(summary_frequency, decreasing = TRUE)[1]

        #Is the majority neighbourhood the same of the label that chosen?
        verify_labels <- (label_samples_current_neuron %in%
                              names(summary_frequency))
        verify_labels <- all(verify_labels)

        neuron_label <- names(majority_vincinity)
        if (verify_labels == FALSE)
            neuron_label <- label_samples_current_neuron[1]

        if(neuron_label == "Noclass")
            neuron_label <- unique(neuron$label_samples)[1]

        class_vector$neuron_class[class_vector$id_neuron ==
                                      duplicated_id_neuron[i]] <- neuron_label
    }
    return(class_vector)
}

#' @title Get the neighbor of neurons
#' @name .sits_som_neighbor_neurons
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#'
#' @description This function create a table contained the information about all
#' neighbor of one neuron of radius 1.
#'
#' @param class_vector          A vector contained the labels of each neuron.
#' @param kohonen_obj           The kohonen object returned by kohonen package.
#' @param duplicated_id_neuron  A vector containing all the id of each neuron
#'                              that has two majority labels.
#' @param radius radius of neigbourhood of each neuron.
#'
#' @return Tibble with informations about the neighbourhood of each neuron.
.sits_som_neighbor_neurons <- function(class_vector, kohonen_obj,
                                       duplicated_id_neuron, radius = 1)
{
    neuron_vicinity.tb <- tibble::as_tibble()
    grid_size <- dim(kohonen_obj$grid$pts)[1]

    for (neuron in seq_len(grid_size))
    {
        neurons_neighbors <-
            which(kohonen::unit.distances(kohonen_obj$grid)[, neuron] == radius)

        #Get the neigbourhood classes
        current_class_neighbors.tb <-
            dplyr::filter(class_vector,
                          class_vector$id_neuron %in% neurons_neighbors)
        current_class_neighbors2.tb <-
            unique(dplyr::select(current_class_neighbors.tb,
                                 id_neuron, neuron_class))

        current_neuron.tb <- dplyr::filter(class_vector,
                                           class_vector$id_neuron == neuron)
        count_neighbors <- table(current_class_neighbors2.tb$neuron_class)

        vicinity_temp.tb <- tibble::as_tibble(
            list(
                id_neuron = as.integer(neuron),
                neuron_label = as.character(unique(current_neuron.tb$neuron_class)),
                label_neighbor_neuron = names(count_neighbors),
                f_Neighbor = as.integer(count_neighbors),
                p_Neighbor  = as.numeric(prop.table(count_neighbors)),
                total_Neighbor = as.integer(sum(count_neighbors))
            )
        )
        neuron_vicinity.tb <- rbind(neuron_vicinity.tb, vicinity_temp.tb)
    }

    return(neuron_vicinity.tb)
}



#' @title Cluster evaluation
#' @name sits_som_evaluate_cluster
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#'
#' @description This function extracts metrics about the clusters calculating
#' the percentage of mixture between a cluster and others.
#'
#' @param som_cluster Kohonen map and associated information
#'                    created by \code{\link[sits]{sits_som_map}}
#' @return            Confusion matrix and a table with percentage
#'                    of mixture between the clusters.
#'
#' @examples
#' \donttest{
#' # Produce a Kohonen map for the time series samples
#' som_cluster <- sits_som_map(prodes_226_064)
#' # Extract metrics about the clusters
#' confusion_by_cluster <- sits_som_evaluate_cluster(som_cluster)
#' # Show confusion matrix
#' confusion_matrix <- confusion_by_cluster$confusion_matrix
#' }
#' @export
sits_som_evaluate_cluster <- function(som_cluster)
{
    data <- som_cluster$statistics_samples$cluster_sample_probability
    #id_sample original_label neuron_label percentage_s cluster
    #Initialize variables
    id_sample <- NULL
    neuron_label <- NULL

    #get only id, label and neuron_label
    temp.data <- unique(dplyr::select(data, id_sample, original_label, cluster))

    #get label that no have cluster
    no_cluster <- dplyr::setdiff(temp.data$original_label, temp.data$cluster)

    confusion.matrix <- table(temp.data$original_label, temp.data$cluster)

    #get the names of classes (original labels from samples)
    label_table <- rownames(confusion.matrix)

    if (length(no_cluster) > 0) {
        #number of class that dont have cluster
        size_vector <- length(no_cluster)

        #Add columns in confusion matrix
        for (sv in seq_len(size_vector))
        {
            #position to add column in confusion matrix
            positon_to_add <- which(label_table == no_cluster[sv])

            #trasform in df.array to add a column
            cf <- as.data.frame.array(confusion.matrix)

            #add a column in same position of line
            cf <- tibble::add_column(cf, d = 0, .after = positon_to_add - 1)

            #rename de column to name of cluster
            names(cf)[positon_to_add] <- no_cluster[sv]
            confusion.matrix <- as.table(as.matrix(cf))
        }
    }

    #Add the total number of samples in table
    confusion.matrix.tb <- stats::addmargins(confusion.matrix,
                                        FUN = list(Total = sum), quiet = TRUE)

    #get dimensions (rows and col)
    #represents the original classes of samples
    dim_row <- dim(confusion.matrix.tb)[1]

    #represents clusters
    dim_col <- dim(confusion.matrix.tb)[2]

    #get the names of classes (original labels from samples)
    label_table <- rownames(confusion.matrix.tb)[1:dim_row - 1]

    mix_class <- dplyr::tibble()
    for (d in seq_len(dim_row - 1))
    {
        #sum the samples of label "d" by cluster.
        #each column represents the cluster where the sample was allocated
        current_row <- confusion.matrix.tb[d, 1:dim_col - 1]
        current_col <- confusion.matrix.tb[1:dim_row - 1, d]

        #get the value total
        current_row_Total <- confusion.matrix.tb[d, dim_col]
        current_col_Total <- confusion.matrix.tb[dim_row, d]

        current_class_ambiguity <-
            tibble::as_tibble(
                list(
                    id_class = as.integer(d),
                    cluster = label_table[d],
                    original_class = names(current_col),
                    mixture_percentage =
                        as.numeric((current_col / current_col_Total) * 100)
                )
            )

        #sort the table in decending order
        current_class_ambiguity <-
            dplyr::arrange(current_class_ambiguity,
                        dplyr::desc(current_class_ambiguity$mixture_percentage))

        #remove lines that mix_percentege is zero
        current_class_ambiguity <-
            dplyr::filter(current_class_ambiguity,
                          current_class_ambiguity$mixture_percentage > 0)

        mix_class <- rbind(mix_class, current_class_ambiguity)
    }

    #Remove the row and column toal and get the confusion matrix from caret,
    info_confusion_matrix <-
       caret::confusionMatrix(confusion.matrix.tb[1:dim_row - 1, 1:dim_col - 1])

    metrics_by_cluster <-  structure(list(mixture_cluster = mix_class,
                                     confusion_matrix = info_confusion_matrix),
                                     class = "sits")
    return(metrics_by_cluster)
}

#' @title Get cluster probability
#' @name .sits_som_cluster_probability
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#'
#' @description This function summarizes the probability
#' that a sample belongs to a cluster from the label of the neuron
#' of several iterations.
#'
#' @param data       Tibble with info of samples provided by sits_cluster_som.
#' @return           Tibble with a new column indicating the
#'                   probability of a sample belongs to a cluster and
#'                   the majority cluster of a sample
#'
.sits_som_cluster_probability <- function(data)
{

    #Count samples to extract the percentage of a sample belong to a cluster
    samples_probability.tb <- tibble::as_tibble(unique(data$samples) %>%
                    dplyr::group_by(id_sample,original_label,neuron_label) %>%
                    dplyr::summarise(count = dplyr::n()) %>%
                    dplyr::mutate(percentage_s = (count / sum(count))*100))

    samples_probability.tb <- dplyr::select(samples_probability.tb,
                                            id_sample, original_label,
                                            neuron_label, percentage_s)

    cluster.temp.tb <- dplyr::group_by(samples_probability.tb, id_sample)

    cluster_majority.tb <- unique(dplyr::filter(cluster.temp.tb,
                                        percentage_s == max(percentage_s)))

    cluster.tb <- dplyr::select(cluster_majority.tb, id_sample,
                                cluster = neuron_label)

    cluster_probability <- samples_probability.tb %>%
        dplyr::inner_join(cluster.tb, by = "id_sample")

    return(cluster_probability)

}


#' @title SOM neighbourhood
#' @name .sits_som_cluster_neighbourhood
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#'
#' @description Overall statistics of neigbourhoods for each sample
#'
#' @param som_cluster     Kohonen map and associated information
#'                        created by \code{\link[sits]{sits_som_map}}
#' @return                Tibble with a overall percentage of the majority
#'                        neighbourhood of each sample of all iterations.
.sits_som_cluster_neighbourhood <- function(som_cluster)
{
    s_samples <- som_cluster$statistics_samples
    #number of iterations
    k <- length(unique(s_samples$samples$iteration))

    table_sample_neuron <- s_samples$sample %>%
        dplyr::inner_join(s_samples$neuron)
    # Table with the % of neighbourhood of a sample
    # id_sample, label_neighbor_neuron, % vincinity
    info_neighbourhood.tb <- tibble::as_tibble(
        dplyr::arrange(
            table_sample_neuron %>%
                dplyr::group_by(id_sample, label_neighbor_neuron) %>%
                dplyr::summarize(percentage_n = (sum(p_Neighbor) / k) * 100),
            id_sample,
            desc(percentage_n)
        )
    )
    return(info_neighbourhood.tb)
}




#' @title Paint neurons
#' @name .sits_som_paint_neurons
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#'
#' @description          Paints all neurons of the last iteration of SOM
#' @param kohonen_obj    SOM provided by package Kohonen
#' @return               SOM object with the colour of the neuron.
#'
.sits_som_paint_neurons <- function(kohonen_obj)
{
    #set colors to paint neurons
    pallete1 <- .sits_brewerRGB[[.sits_color_name("Set1")]]
    set1 <- utils::head(unique(unlist(pallete1, use.names = FALSE)), -1)

    pallete2 <- .sits_brewerRGB[[.sits_color_name("Accent")]]
    accent <- utils::head(unique(unlist(pallete2, use.names = FALSE)), -1)

    pallete3 <- .sits_brewerRGB[[.sits_color_name("Pastel1")]]
    pastel1 <- utils::head(unique(unlist(pallete3, use.names = FALSE)), -1)

    pallete_neighbors <- c(pastel1, set1, accent)

    #Paint
    for (j in seq_along(unique(kohonen_obj$neuron_label)))
    {
        paint_neurons <- which(kohonen_obj$neuron_label_id.mt[, 2] == j)
        kohonen_obj$neighborhood_neurons[paint_neurons] <- pallete_neighbors [j]
    }

    empty_neuron <- which(kohonen_obj$neuron_label == "No_class")
    kohonen_obj$neighborhood_neurons[empty_neuron] <- " White"
    kohonen_obj$paint_map <-  kohonen_obj$neighborhood_neurons
    kohonen_obj$neuron_label <- kohonen_obj$neuron_label

    return(kohonen_obj)
}


#' @title Paint neurons
#' @name .sits_som_bayesian_neighbourhood
#' @author Lorena Santos, \email{lorena.santos@@inpe.br}
#'
#' @description          Compute the probability that a sample belongs to
#'                       a cluster using bayesian filter.
#' @param kohonen_obj         SOM object from package "kohonen"
#' @param neurons_labelled.tb Tibble containing informations about each neuron.
#' @param result              A tibble with samples.
#' @return                    Returns the probability that a sample belongs to a
#'                            cluster based on the class of neuron
#'                            and its neighborhood.

.sits_som_bayesian_neighbourhood <- function(kohonen_obj,
                                             neurons_labelled.tb,
                                             result)
{
    grid_size <- dim(kohonen_obj$grid$pts)[1]
    samples_probability_i.tb <- tibble::as_tibble()


    for (neuron_i in seq_len(grid_size))
    {
        #get general information about each neuron
        current_id_neighbourhood.tb <-
            which(kohonen::unit.distances(kohonen_obj$grid)[, neuron_i] == 1)

        #amount of neighourhood
        size_neighbourhood <- length(current_id_neighbourhood.tb)

        data_neuron_i.tb <- dplyr::filter(neurons_labelled.tb,
                                     neurons_labelled.tb$id_neuron == neuron_i)

        #if ((data_neuron_i.tb$count[1]) != 0)
        if ((data_neuron_i.tb$neuron_class[1]) != "Noclass")
        {
            for (i in seq_len(dim(data_neuron_i.tb)[1]))
            {
                current_class_neuron.tb <- data_neuron_i.tb[i,]
                #get sample with the same label of current class of neuron
                samples_inside_neuron.tb <-
                    dplyr::filter(
                        result,
                        result$id_neuron == neuron_i &
                          result$label == current_class_neuron.tb$label_samples
                    )

                get_data_neighbouhood_current_class.tb <-
                    dplyr::filter(neurons_labelled.tb,
                    neurons_labelled.tb$id_neuron %in% current_id_neighbourhood.tb &
                    neurons_labelled.tb$label_samples == current_class_neuron.tb$label_samples )

                #vector of probability about the neigbourhood of current neuron
                get_freq <- get_data_neighbouhood_current_class.tb$freq

                #amount of zero probabilites in this neigbourhood for class k
                get_amount_zeros <- size_neighbourhood - length(get_freq)

                neighbourhood_probability.vec <- c(get_freq, rep(0, get_amount_zeros))
                variance_neighbourhood.vec <- stats::var(neighbourhood_probability.vec)

                #Bayesian Filter equations
                probability_sample_k <- current_class_neuron.tb$freq

                w1 <- (variance_neighbourhood.vec/(1+variance_neighbourhood.vec))*probability_sample_k
                w2 <- (1/(1+variance_neighbourhood.vec))*mean(neighbourhood_probability.vec)
                probality_samples <- w1 + w2

                #add this value in samples that belongs to this neuron
                samples_inside_neuron.tb$probability_cluster <- probality_samples
                samples_probability_i.tb <- rbind(samples_probability_i.tb,samples_inside_neuron.tb)
            }
        }
    }
    return(samples_probability_i.tb)
}
#' @title  Plot information about clusters
#' @name   sits_som_plot_clusters
#' @author Lorena Santos \email{lorena.santos@@inpe.br}
#'
#' @description Plot a bar graph with informations about each cluster.
#' The percentage of mixture between the clusters.
#'
#' @param data       Percentage of mixture between the clusters
#'                   (produced by \code{\link[sits]{sits_som_evaluate_cluster}})
#' @param text_title Title of plot. Default is "Cluster".
#'
#' @examples
#' \donttest{
#' # Produce a cluster map
#' som_cluster <- sits_som_map(prodes_226_064)
#' # Evaluate the clusters
#' cluster_overall <- sits_som_evaluate_cluster(som_cluster)
#' # Plot confusion between the clusters
#' sits_som_plot_clusters(cluster_overall, "Confusion by cluster")
#' }
#' @export
sits_som_plot_clusters <- function(data, text_title = " Cluster ")
{
    data <- data$mixture_cluster
    labels <- data$original_class

    p <-
        ggplot2::ggplot() + ggplot2::geom_bar(
            ggplot2::aes(
                y = data$mixture_percentage,
                x = data$cluster,
                fill = labels
            ),
            data = data,
            stat = "identity",
            position = ggplot2::position_dodge()
        )  +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 60,
                                                           hjust = 1)) +
        ggplot2::labs(x = "Clusters", y = "Percentage of mixture",
                      colour = "cluster") +
        ggplot2::ggtitle(text_title)

    return(p)
}
