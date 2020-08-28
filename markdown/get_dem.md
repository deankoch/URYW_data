get\_dem.R
================
Dean Koch
August 14, 2020

**MITACS UYRW project**

**get\_DEM**: download a DEM and warp to our reference coordinate system

[get\_basins.R](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_basins.md)
and
[get\_weatherstations.R](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_weatherstations.md),
should be run before this script.

## libraries

`FedData` is used to fetch the USGS data. See the [get\_helperfun.R
script](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_helperfun.md),
for other required libraries

``` r
library(here)
source(here('get_helperfun.R'))
library(FedData)
library(raster)
library(gdalUtils)
```

## project data

``` r
# This list describes all of the files created by this script:
files.towrite = list(
  
  # DEM downloaded from the USGS website
  c(name='ned',
    file=file.path(src.subdir, 'UYRW_NED_1.tif'), 
    type='GeoTIFF raster file',
    description='mosaic of elevation tiles from the NED (unchanged)'), 
  
  # DEM after warp and crop
  c(name='dem',
    file=file.path(out.subdir, 'dem.tif'), 
    type='GeoTIFF raster file',
    description='digital elevation map of the UYRW and surrounding area'), 
  
  # aesthetic parameters for plotting
  c(name='tmap.pars',
    file=file.path(data.dir, 'tmap_get_dem.rds'), 
    type='R list object', 
    description='parameters for writing png plots using tmap and tm_save'),
  
  # graphic showing DEM for the UYRW
  c(name='img_dem',
    file=file.path(graphics.dir, 'dem.png'),
    type='png graphic',
    description='image of DEM for the UYRW')

)

# write this information to disk
my_metadata('get_dem', files.towrite, overwrite=TRUE)
```

    ## [1] "writing to data/get_dem_metadata.csv"

    ##                                 file                type                                             description
    ## tmap.pars      data/tmap_get_dem.rds       R list object parameters for writing png plots using tmap and tm_save
    ## ned       data/source/UYRW_NED_1.tif GeoTIFF raster file      mosaic of elevation tiles from the NED (unchanged)
    ## dem            data/prepared/dem.tif GeoTIFF raster file  digital elevation map of the UYRW and surrounding area
    ## img_dem             graphics/dem.png         png graphic                               image of DEM for the UYRW
    ## metadata   data/get_dem_metadata.csv                 CSV                list files of files written by get_dem.R

This list of files and descriptions is now stored as a [.csv
file](https://github.com/deankoch/UYRW_data/blob/master/data/get_dem_metadata.csv)
in the `/data` directory. Load some of the data prepared earlier

``` r
# load metadata csv, CRS info list and watershed polygons from disk
crs.list = readRDS(here(my_metadata('get_basins')['crs', 'file']))
uyrw.poly = readRDS(here(my_metadata('get_basins')['boundary', 'file']))
uyrw.padded.poly = readRDS(here(my_metadata('get_weatherstations')['boundary_padded', 'file']))
```

## Download the DEM raster

The *get\_ned* function from `FedData` retrieves and merge all (12)
required elevation tiles from the USGS NED

``` r
if(!file.exists(here(my_metadata('get_dem')['ned', 'file'])))
{
  # We will downloaded the DEM for an extended UYRW boundary, to allow modeling of nearby weather records 
  boundary.padded.sp = as_Spatial(uyrw.padded.poly)
  
  # This function call downloads tiles to "/RAW", extracts them, and writes the mosaic to "UYRW_NED_1" in "/data/source"
  dem.original.tif = get_ned(template=boundary.padded.sp, label='UYRW', extraction.dir=here(src.subdir))
  
  # remove the temporary files
  unlink(here('RAW'), recursive=TRUE)
  
} else {
  
  # load the NED raster from disk
  dem.original.tif = raster(here(my_metadata('get_dem')['ned', 'file']))
}
```

Warp (gridded CRS transform) and clip the raster to our reference system
and study area

``` r
if(!file.exists(here(my_metadata('get_dem')['dem', 'file'])))
{
  # define a temporary file
  temp.tif = tempfile()
  
  # package 'gdalUtils' performs these kinds of operations much faster than `raster`
  gdalwarp(srcfile=here(my_metadata('get_dem')['ned', 'file']), 
           dstfile=temp.tif,
           s_srs=crs(dem.original.tif), 
           t_srs=paste0('EPSG:', crs.list$epsg),
           overwrite=TRUE,
           verbose=TRUE)
  
  # load the transformed raster (resolution is approx 30m x 30m)
  dem.tif = raster(temp.tif)
  
  # write to output directory
  writeRaster(dem.tif, here(my_metadata('get_dem')['dem', 'file']), overwrite=TRUE)

} else {
  
  # load from disk 
  dem.tif = raster(here(my_metadata('get_dem')['dem', 'file']))
}
```

## visualization

``` r
# load the plotting parameters used in get_basins.R, modify for this plot
```

Set up the aesthetics to use for these types of plots

``` r
if(!file.exists(here(my_metadata('get_dem')['tmap.pars', 'file'])))
{
  # load the plotting parameters used in get_basins.R
  tmap.pars = readRDS(here(my_metadata('get_basins')['tmap.pars', 'file']))
  
  # shrink the vertical length
  tmap.pars$png['h'] = 1800
  
  # the background is too dark for black text
  tmap.pars$layout = tmap.pars$layout + 
    tm_layout(legend.position=c('right', 'top'),
              legend.text.color='white',
              legend.title.color='white')
  
  # save to disk
  saveRDS(tmap.pars, here(my_metadata('get_dem')['tmap.pars', 'file']))
  
} else {
  
  # load from disk
  tmap.pars = readRDS(here(my_metadata('get_dem')['tmap.pars', 'file']))
  
} 

# plot DEM raster as a png file
if(!file.exists(here(my_metadata('get_dem')['img_dem', 'file'])))
{
  tmap.dem = tm_shape(dem.tif, raster.downsample=T, bbox=st_bbox(uyrw.poly)) +
      tm_raster(palette='viridis', title='elevation (m)', style='cont') +
    tm_shape(uyrw.poly) +
      tm_borders(col='white') +
    tmap.pars$layout +
    tm_layout(main.title='Digital elevation map of the UYRW')
              
  # render the plot
  tmap_save(tm=tmap.dem, 
            here(my_metadata('get_dem')['img_dem', 'file']), 
            width=tmap.pars$png['w'], 
            height=tmap.pars$png['h'], 
            pointsize=tmap.pars$png['pt'])
}
```

![elevation map of the
UYRW](https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/dem.png)
