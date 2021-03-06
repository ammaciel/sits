context("Accuracy")
test_that("XLS", {
    data(cerrado_2classes)
    pred_ref.tb <- sits_kfold_validate(cerrado_2classes, folds = 2)
    invisible(capture.output(conf.mx <- sits_conf_matrix(pred_ref.tb)))
    results <- list()
    conf.mx$name <- "confusion_matrix"
    results[[length(results) + 1]] <- conf.mx
    sits_to_xlsx(results, file = "confusion_matrix.xlsx")

    expect_true(file.remove("confusion_matrix.xlsx"))
})

test_that("Accuracy - 2 classes", {
    cube_wtss <- sits_cube(service = "WTSS", name = "MOD13Q1")

    data <- sits_get_data(cube_wtss,
                          file = system.file("extdata/samples/samples_matogrosso.csv",
                                 package = "sits"),
                          bands = c("ndvi", "evi"),
                          .n_save = 0)

    data("cerrado_2classes")
    svm_model <- sits_train(cerrado_2classes, ml_method = sits_svm())
    class.tb <- sits_classify(data, svm_model)

    names(class.tb)

    invisible(utils::capture.output(conf.mx <- sits_conf_matrix(class.tb)))

    expect_equal(length(names(conf.mx)), 6)

    # Error when the sum of any row in the error matrix is exactly 1.
    testthat::expect_error(sits_accuracy_area(class.tb))

    # Duplicate the rows to ensure all the rows sum to more than 1.
    acc_ls <- sits_accuracy_area(rbind(class.tb, class.tb))
    expect_true(acc_ls$accuracy$overall <= 1)
    expect_true(all(acc_ls$accuracy$user <= 1))
    expect_true(all(acc_ls$accuracy$producer <= 1))
    expect_true(acc_ls$accuracy$overall >= 0)
    expect_true(all(acc_ls$accuracy$user >= 0))
    expect_true(all(acc_ls$accuracy$producer >= 0))
})

test_that("Accuracy - more than 2 classes", {
    data("prodes_226_064")
    pred_ref.tb <- sits_kfold_validate(prodes_226_064, folds = 2)
    invisible(capture.output(conf.mx <- sits_conf_matrix(pred_ref.tb)))

    expect_true(conf.mx$overall["Accuracy"] > 0.80)
    expect_true(conf.mx$overall["Kappa"] > 0.75)

    conv.lst <-  list(Deforestation_2014 = "NonForest",
                      Deforestation_2015 = "NonForest",
                      Pasture = "NonForest",
                      Forest  = "Forest")

    invisible(capture.output(conf2.mx <- sits_conf_matrix(pred_ref.tb, conv.lst = conv.lst)))

    expect_true(conf2.mx$overall["Accuracy"] > 0.90)
    expect_true(conf2.mx$overall["Kappa"] > 0.80)
})
