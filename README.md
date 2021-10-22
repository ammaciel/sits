SITS - Satellite Image Time Series Analysis for Earth Observation Data
Cubes
================

<!-- README.md is generated from README.Rmd. Please edit that file -->

<img src="inst/extdata/sticker/sits_sticker.png" alt="SITS icon" align="right" height="150" width="150"/>

<!-- badges: start -->
<!-- [![Build Status](https://drone.dpi.inpe.br/api/badges/e-sensing/sits/status.svg)](https://drone.dpi.inpe.br/e-sensing/sits) -->

[![codecov](https://codecov.io/gh/e-sensing/sits/branch/master/graph/badge.svg?token=hZxdJgKGcE)](https://codecov.io/gh/e-sensing/sits)
[![Documentation](https://img.shields.io/badge/docs-online-blueviolet)](https://e-sensing.github.io/sitsbook/)
[![Software Life
Cycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![Software
License](https://img.shields.io/badge/license-GPL--2-green)](https://github.com/e-sensing/sits/blob/master/LICENSE)

<!-- badges: end -->

### Overview

The `sits` R package provides a set of tools for analysis, visualization
and classification of satellite image time series. The main aim of SITS
is to support land cover and land change classification of image data
cubes using machine learning methods. The basic workflow in SITS is:

1.  Create a data cube using image collections available in the cloud or
    in local machines.
2.  Extract time series from the data cube which are used as training
    data.
3.  Perform quality control and filtering on the samples.
4.  Train a machine learning model using the extracted samples.
5.  Classify the data cube using the trained model.
6.  Post-process the classified images.
7.  Evaluate the accuracy of the classification using best practices.

## Installation

### Pre-Requisites

The `sits` package relies on `sf`, `terra` and `raster`, which in turn,
require the installation of the GDAL and PROJ libraries. Please follow
the instructions for installing `sf` together with GDAL available at the
[RSpatial sf github repository](https://github.com/r-spatial/sf).

### Obtaining SITS

SITS is currently available on github, as follows:

``` r
# Please install the `sits` package from github
# and its dependencies
devtools::install_github("e-sensing/sits", dependencies = TRUE)
library(sits)
library(tibble)
library(magrittr)
```

### Data Cubes

SITS has been designed to work with big satellite image data sets
organised as data cubes. Data cubes can be available in the cloud or in
a local machine. Currently, SITS supports data cubes available in the
following cloud services:

1.  Sentinel-2/2A level 2A images in AWS.
2.  Collections of Sentinel, Landsat and CBERS images in the Brazil Data
    Cube (BDC).
3.  Sentinel-2/2A collections available in Digital Earth Africa.
4.  Data cubes produced by the “gdalcubes” package.
5.  Local image collections organized as raster stacks.

SITS relies on STAC services provided by these cloud services. The user
can define a data cube by selecting a collection in a cloud service and
then defining a space-time extent. For example, the following code will
define a data cube of Sentinel-2/2A images using AWS. Users need to
provide AWS credentials using environment variables.

``` r
s2_cube <- sits_cube(source = "AWS",
                     name = "T20LKP_2018_2019",
                     collection = "sentinel-s2-l2a-cogs",
                     tiles = c("20LKP"),
                     start_date = as.Date("2018-07-18"),
                     end_date = as.Date("2018-07-23")
)
```

In the above example, the user has selected the “Sentinel-2 Level 2”
collection in the AWS cloud services. The geographical area of the data
cube is defined by the tile “20LKP”, and the temporal extent by a start
and end date. Access to other cloud services works in similar ways.

Users can derive data cubes from ARD data which have pre-defined
temporal resolutions. For example, a user may want to define the best
Sentinel-2 pixel in a one month period, as shown below. This can be done
in SITS by the `sits_regularize` which use the
[https://github.com/appelmar/gdalcubes](gdalcubes) package. For details
in gdalcubes, please see Reference \[4\].

``` r
gc_cube <- sits_regularize(cube          = s2_cube,
                           name          = "T20LKP_2018_2019_1M",
                           output_dir    = tempdir(),
                           period        = "P1M",
                           agg_method    = "median",
                           cloud_mask    = TRUE,
                           multicores    = 2)
```

### Accessing time series in data cubes

SITS has been designed to use satellite image time series to derive
machine learning models. After the data cube has been created, time
series can be retreived individually or by using CSV or SHP files, as in
the following example.

``` r
library(sits)
#> Using configuration file: /Library/Frameworks/R.framework/Versions/4.1/Resources/library/sits/extdata/config.yml
#> To provide additional configurations, create an YAML file and inform its path to environment variable 'SITS_CONFIG_USER_FILE'.
#> Using raster package: terra
#> SITS - satellite image time series analysis.
#> Loaded sits v0.15.0.
#>         See ?sits for help, citation("sits") for use in publication.
#>         See demo(package = "sits") for examples.
# create a cube from a local file 
data_dir <- system.file("extdata/raster/mod13q1", package = "sits")

raster_cube <- sits_cube(
    source = "BDC",
    collection = "MOD13Q1-6",
    data_dir = data_dir,
    delim = "_",
    parse_info = c("X1", "X2", "tile", "band", "date")
)

# obtain a set of locations defined by a CSV file
csv_raster_file <- system.file("extdata/samples/samples_sinop_crop.csv",
                               package = "sits")

# retrieve the points from the data cube
points <- sits_get_data(raster_cube, file = csv_raster_file)
#> All points have been retrieved

# show the points
points[1:3,]
#> # A tibble: 3 × 7
#>   longitude latitude start_date end_date   label   cube      time_series      
#>       <dbl>    <dbl> <date>     <date>     <chr>   <chr>     <list>           
#> 1     -55.7    -11.8 2013-09-14 2014-08-29 Pasture MOD13Q1-6 <tibble [23 × 3]>
#> 2     -55.6    -11.8 2013-09-14 2014-08-29 Pasture MOD13Q1-6 <tibble [23 × 3]>
#> 3     -55.7    -11.8 2013-09-14 2014-08-29 Forest  MOD13Q1-6 <tibble [23 × 3]>
```

After a time series is imported, it is loaded in a tibble. The first six
columns contain the metadata: spatial and temporal location, label
assigned to the sample, and coverage from where the data has been
extracted. The spatial location is given in longitude and latitude
coordinates. The first sample has been labelled “Pasture”, at location
(-55.65931, -11.76267), and is considered valid for the period
(2013-09-14, 2014-08-29). To display the time series, use the `plot()`
function.

``` r
plot(points[1,])
```

<div class="figure" style="text-align: center">

<img src="man/figures/README-unnamed-chunk-6-1.png" alt="Plot of point at location (-55.65931, -11.76267) labelled as Pasture"  />
<p class="caption">
Plot of point at location (-55.65931, -11.76267) labelled as Pasture
</p>

</div>

For a large number of samples, where the amount of individual plots
would be substantial, the default visualisation combines all samples
together in a single temporal interval.

``` r
# select the "ndvi" band
samples_ndvi <- sits_select(samples_modis_4bands, "NDVI")

# select only the samples with the cerrado label
samples_cerrado <- dplyr::filter(samples_ndvi, 
                  label == "Cerrado")
plot(samples_cerrado)
```

<div class="figure" style="text-align: center">

<img src="./inst/extdata/markdown/figures/samples_cerrado.png" alt="Samples for NDVI band for Cerrado class" width="480" />
<p class="caption">
Samples for NDVI band for Cerrado class
</p>

</div>

### Clustering for sample quality control

Clustering methods in SITS improve the quality of the samples and to
remove those that might have been wrongly labeled or that have low
discriminatory power. Good samples lead to good classification maps.
`sits` provides support for sample quality control using Self-organizing
Maps (SOM).

The process of clustering with SOM is done by `sits_som_map()`, which
creates a self-organizing map and assesses the quality of the samples.
This function uses the “kohonen” R package to compute a SOM grid (see
Reference \[7\] below). Each sample is assigned to a neuron, and neurons
are placed in the grid based on similarity. The second step is the
quality assessment. Each neuron will be associated with a discrete
probability distribution. Homogeneous neurons (those with a single
class) are assumed to be composed of good quality samples. Heterogeneous
neurons (those with two or more classes with significant probability)
are likely to contain noisy samples. See [Chapter 4 of the sits
book](https://e-sensing.github.io/sitsbook/time-series-clustering-to-improve-the-quality-of-training-samples.html).

### Filtering

Satellite image time series are contaminated by atmospheric influence
and directional effects. To make the best use of available satellite
data archives, methods for satellite image time series analysis need to
deal with data sets that are *noisy* and *non-homogeneous*. For data
filtering, `sits` supports Savitzky–Golay (`sits_sgolay()`), Whittaker
(`sits_whittaker()`), and envelope (`sits_envelope()`). As an example,
we show how to apply the Whittaker smoother to a 16-year NDVI time
series. For more details, please see the vignette [“Satellite Image Time
Series Filtering with
SITS”](https://github.com/e-sensing/sits-docs/blob/master/doc/filters.pdf)

``` r
# apply Whitaker filter to a time series sample for the NDVI band from 2000 to 2016
# merge with the original data
# plot the original and the modified series
point_ndvi <- sits_select(point_mt_6bands, bands = "NDVI")
point_ndvi %>% 
    sits_filter(sits_whittaker(lambda = 10)) %>% 
    sits_merge(point_ndvi) %>% 
    plot()
```

<div class="figure" style="text-align: center">

<img src="man/figures/README-unnamed-chunk-9-1.png" alt="Whitaler filter of NDVI time series"  />
<p class="caption">
Whitaler filter of NDVI time series
</p>

</div>

### Time Series classification using machine learning

SITS provides support for the classification of both individual time
series as well as data cubes. The following machine learning methods are
available in SITS:

-   Linear discriminant analysis (`sits_lda`)
-   Quadratic discriminant analysis (`sits_qda`)
-   Multinomial logit and its variants ‘lasso’ and ‘ridge’ (`sits_mlr`)
-   Support vector machines (`sits_svm`)
-   Random forests (`sits_rfor`)
-   Extreme gradient boosting (`sits_xgboost`)
-   Deep learning (DL) using multi-layer perceptrons
    (`sits_deeplearning`)
-   DL using Deep Residual Networks (`sits_ResNet`) (see reference
    \[5\])
-   DL combining 1D convolution neural networks and multi-layer
    perceptrons (`sits_TempCNN`) (See reference \[6\])

The following example illustrate how to train a dataset and classify an
individual time series. First we use the `sits_train` function with two
parameters: the training dataset (described above) and the chosen
machine learning model (in this case, extreme gradient boosting). The
trained model is then used to classify a time series from Mato Grosso
Brazilian state, using `sits_classify`. The results can be shown in text
format using the function `sits_show_prediction` or graphically using
`plot`.

``` r
# training data set
data("samples_modis_4bands")

# point to be classified
data("point_mt_6bands")

# Select the NDVI and EVI bands 
# Filter the band to reduce noise
# Train a deep learning model
tempCNN_model <- samples_modis_4bands %>% 
    sits_select(bands = c("NDVI", "EVI")) %>% 
    sits_whittaker(bands_suffix = "") %>% 
    sits_train(ml_method = sits_TempCNN(verbose = FALSE)) 

# Select NDVI and EVI bands of the  point to be classified
# Filter the point 
# Classify using TempCNN model
# Plot the result
point_mt_6bands %>% 
  sits_select(bands = c("ndvi", "evi")) %>% 
  sits_whittaker(bands_suffix = "") %>% 
  sits_classify(tempCNN_model) %>% 
  plot()
```

<img src="man/figures/README-unnamed-chunk-10-1.png" style="display: block; margin: auto;" />

The following example shows how to classify a data cube organised as a
set of raster images. The result can also be visualised interactively
using `sits_view()`.

``` r
# Retrieve the set of samples for the Mato Grosso region 
# Select the data for classification
# Reduce noise the bands using whittaker filter
# Build an extreme gradient boosting model
xgb_model <- samples_modis_4bands %>% 
    sits_select(bands = c("NDVI", "EVI")) %>% 
    sits_whittaker(bands_suffix = "") %>% 
    sits_train(ml_method = sits_xgboost())

# Create a data cube to be classified
# Cube is composed of MOD13Q1 images from the Sinop region in Mato Grosso (Brazil)
data_dir <- system.file("extdata/raster/mod13q1", package = "sits")
sinop <- sits_cube(
    source = "LOCAL",
    name = "sinop-2014",
    origin = "BDC",
    collection = "MOD13Q1-6",
    data_dir = data_dir,
    delim = "_",
    parse_info = c("X1", "X2", "tile", "band", "date")
)
#> LOCAL value is deprecated
#> Using origin as the source
#> Please see the documentation on sits_cube()
#> name parameter is no longer required

# Classify the raster cube, generating a probability file
# Filter the pixels in the cube to remove noise
probs_cube <- sits_classify(sinop, 
                            ml_model = xgb_model, 
                            filter_fn = sits_whittaker())
# apply a bayesian smoothing to remove outliers
bayes_cube <- sits_smooth(probs_cube)
# generate a thematic map
label_cube <- sits_label_classification(bayes_cube)
# plot the the labelled cube
plot(label_cube, title = "Labelled image")
```

![](man/figures/README-unnamed-chunk-11-1.png)<!-- -->

### Additional information

For more information, please see the on-line book [“SITS: Data analysis
and machine learning for data cubes using satellite image
timeseries”](https://e-sensing.github.io/sitsbook/).

### References

#### Reference paper for sits

If you use sits on academic works, please cite the following paper:

-   \[1\] Rolf Simoes, Gilberto Camara, Gilberto Queiroz, Felipe Souza,
    Pedro R. Andrade, Lorena Santos, Alexandre Carvalho, and Karine
    Ferreira. “Satellite Image Time Series Analysis for Big Earth
    Observation Data”. Remote Sensing, 13, p. 2428, 2021.
    <https://doi.org/10.3390/rs13132428>.

Additionally, the sample quality control methods that use self-organised
maps are described in the following reference:

-   \[2\] Lorena Santos, Karine Ferreira, Gilberto Camara, Michelle
    Picoli, Rolf Simoes, “Quality control and class noise reduction of
    satellite image time series”. ISPRS Journal of Photogrammetry and
    Remote Sensing, vol. 177, pp 75-88, 2021.
    <https://doi.org/10.1016/j.isprsjprs.2021.04.014>.

#### Papers that use sits to produce LUCC maps

-   \[3\] Rolf Simoes, Michelle Picoli, et al., “Land use and cover maps
    for Mato Grosso State in Brazil from 2001 to 2017”. Sci Data 7, 34
    (2020).

-   \[4\] Michelle Picoli, Gilberto Camara, et al., “Big Earth
    Observation Time Series Analysis for Monitoring Brazilian
    Agriculture”. ISPRS Journal of Photogrammetry and Remote
    Sensing, 2018. DOI: 10.1016/j.isprsjprs.2018.08.007

-   \[5\] Karine Ferreira, Gilberto Queiroz et al., Earth Observation
    Data Cubes for Brazil: Requirements, Methodology and Products.
    Remote Sens. 2020, 12, 4033.

#### Papers that describe software used in sits

We thank the authors of these papers for making their code available to
be used in sits.

-   \[6\] Appel, Marius, and Edzer Pebesma, “On-Demand Processing of
    Data Cubes from Satellite Image Collections with the Gdalcubes
    Library.” Data 4 (3): 1–16, 2020.

-   \[7\] Hassan Fawaz, Germain Forestier, Jonathan Weber, Lhassane
    Idoumghar, and Pierre-Alain Muller, “Deep learning for time series
    classification: a review”. Data Mining and Knowledge Discovery,
    33(4): 917–963, 2019.

-   \[8\] Pelletier, Charlotte, Geoffrey I. Webb, and Francois
    Petitjean. “Temporal Convolutional Neural Network for the
    Classification of Satellite Image Time Series.” Remote Sensing 11
    (5), 2019.

-   \[9\] Wehrens, Ron and Kruisselbrink, Johannes. “Flexible
    Self-Organising Maps in kohonen 3.0”. Journal of Statistical
    Software, 87, 7 (2018).

#### R packages used in sits

The authors acknowledge the contributions of Marius Appel, Tim
Appelhans, Henrik Bengtsson, Matt Dowle, Robert Hijmans, Edzer Pebesma,
and Ron Wehrens, respectively chief developers of the packages
“gdalcubes”, “mapview”, “data.table”, “terra/raster”, “sf”/“stars”, and
“kohonen”. The code in “sits” is also much indebted to the work of the
RStudio team, including the “tidyverse” and the “furrr” and “keras”
packages. We also thank Charlotte Pelletier and Hassan Fawaz for sharing
the python code that has been reused for the “TempCNN” and “ResNet”
machine learning models.

## How to contribute

The SITS project is released with a [Contributor Code of
Conduct](https://github.com/e-sensing/sits/blob/master/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.
