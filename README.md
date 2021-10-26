SITS - Satellite Image Time Series Analysis for Earth Observation Data
Cubes
================

<!-- README.md is generated from README.Rmd. Please edit that file -->

<img src="inst/extdata/sticker/sits_sticker.png" alt="SITS icon" align="right" height="150" width="150"/>

<!-- badges: start -->
<!-- [![Build Status](https://drone.dpi.inpe.br/api/badges/e-sensing/sits/status.svg)](https://drone.dpi.inpe.br/e-sensing/sits) -->

[![Build
Status](https://cloud.drone.io/api/badges/e-sensing/sits/status.svg)](https://cloud.drone.io/e-sensing/sits)
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
```

### Data Cubes and ARD Image Collections

SITS works best with regular *data cube* that meet the following
definition:

1.  A data cube is a four-dimensional structure with dimensions x
    (longitude or easting), y (latitude or northing), time, and bands.
2.  Its spatial dimensions refer to a single spatial reference system
    (SRS). Cells of a data cube have a constant spatial size with
    respect to the cube’s SRS.
3.  The temporal dimension is composed of a set of continuous and
    equally-spaced intervals.
4.  For every combination of dimensions, a cell has a single value.

Not all data cubes are regular. Currently, most cloud providers (such as
AWS and Microsoft) provide images organised as analysis-ready data (ARD)
image collections, which meet the following definitions:

1.  An ARD image collection is a set of files from a given sensor (or a
    combined set of sensors) that has been corrected to ensure
    comparability of measurements between different dates.
2.  All images are reprojected to a cartographic projection following
    well-established standards.
3.  Image collections are cropped into a tiling system.  
4.  In general, the timelines of the images that are part of one tile
    are not regular. Also, these timelines are not the same as those
    associated to a different tile.
5.  ARD image collections do not guarantee that every pixel of an image
    has a valid value, since its images still contains cloudy or missing
    pixels.

### Transforming ARD Image Collections into Data Cubes

SITS has been designed to work with big satellite image data sets
organised as data cubes. Data cubes can be available in the cloud or in
a local machine. Currently, SITS supports analysis ready data
collections available in the services provided by Amazon Web Services
(AWS), Brazil Data Cube (BDC), Digital Earth Africa (DEAFRICA), and
United States Geological Survey (USGS). We are working to include
collections available in Microsoft’s Planetary Computer. Most of these
collections are open data and require no payment to access them.
However, in general these collections are not regular and require
further processing before they can be used in SITS.

The ARD collections accessible with SITS version 0.15.0 are:

1.  Sentinel-2/2A level 2A collections in AWS, including
    “SENTINEL-S2-L2A-COGS” (open data) and “SENTINEL-S2-L2A” (non open
    data). These collections are not regular.
2.  Collections of Sentinel-2, Landsat-8 and CBERS-4 images in BDC
    (opendata). The BDC collections are regular and openly accessible.
3.  Sentinel-2/2A and Landsat-8 collections available in Digital Earth
    Africa. These collections are openly acessible but not regular;
4.  Landsat-4/5/7/8 collections made available by USGS. These
    collections are neither openly acessible nor regular.

SITS relies on STAC services to access these collections. The user
defines a generic data cube by selecting a collection in a cloud service
and then specifying a space-time extent. For example, the following code
will define a data cube of Sentinel-2/2A images using AWS.

``` r
s2_cube <- sits_cube(source = "AWS",
                     collection = "sentinel-s2-l2a-cogs",
                     tiles = c("20LKP", "20LLP"),
                     bands = c("B02", "B03", "B04", "B08", "B8A", "B11")
                     start_date = as.Date("2018-07-01"),
                     end_date = as.Date("2018-10-30")
)
```

In the above example, the user has selected the “Sentinel-2 Level 2”
collection in the AWS cloud services which is open data. The
geographical area of the data cube is defined by the tiles “20LKP” and
“20LLKP”, and the temporal extent by a start and end date. Access to
other cloud services works in similar ways.

The data cube defined by the above command not regular, since the chosen
Sentinel-2 bands have different resolutions. Also, tiles “20LKP” and
“20LLP” have different timelines. Users can derive regular data cubes
from ARD data which have pre-defined temporal resolutions. This is dones
by `sits_regularize()` which uses the
[https://github.com/appelmar/gdalcubes](gdalcubes) package \[4\].

``` r
gc_cube <- sits_regularize(cube          = s2_cube,
                           output_dir    = tempdir(),
                           period        = "P15D",
                           agg_method    = "median",
                           res           = 10, 
                           cloud_mask    = TRUE,
                           multicores    = 2)
```

The above command builds a regular data cube with all bands interpolated
to 10 meter spatial resolution and 15 days temporal resolution.

### Accessing time series in data cubes

In the example below, we will work with a local data cubes, whose data
has been obtained from the “MOD13Q1-6” collecion of the Brazil Data
Cube. SITS has been designed to use satellite image time series to
derive machine learning models. After the data cube has been created,
time series can be retrieved individually or by using CSV or SHP files,
as in the following example.

``` r
library(sits)
#> Using configuration file: /home/sits/R/x86_64-pc-linux-gnu-library/4.1/sits/extdata/config.yml
#> To provide additional configurations, create an YAML file and inform its path to environment variable 'SITS_CONFIG_USER_FILE'.
#> Using raster package: terra
#> SITS - satellite image time series analysis.
#> Loaded sits v0.15.0-1.
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
    source = "BDC",
    collection = "MOD13Q1-6",
    data_dir = data_dir,
    delim = "_",
    parse_info = c("X1", "X2", "tile", "band", "date")
)

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
