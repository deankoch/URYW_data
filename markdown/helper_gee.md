helper\_GEE.R
================
Dean Koch
2021-07-13

**Mitacs UYRW project**

**helper\_gee**: helper functions for google earth engine downloads

This uses the `rgee` package, which depends on `reticulate`, an R
wrapper for python calls. We use the native python API for GEE, so a
working python installation is required.

``` r
# relative paths for working directory
library(here)

# `googledrive` and `future` are required by `rgee` to download raster collections via gdrive
library(googledrive)
library(future)

# define directories for dependencies
gee.dir = here('rgee')
conda.dir = file.path(gee.dir, 'conda')
conda.env = file.path(conda.dir, 'envs/r-reticulate')

# set an environmental variable to ensure reticulate finds the right environment
Sys.setenv(RETICULATE_PYTHON = conda.env)
library('reticulate')
library('rgee')
```
