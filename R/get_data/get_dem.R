#' ---
#' title: "get_dem.R"
#' author: "Dean Koch"
#' date: "`r format(Sys.Date())`"
#' output: github_document
#' ---
#'
#' **Mitacs UYRW project**
#' 
#' **get_DEM**: download a DEM and warp to our reference coordinate system, generate a hillshade raster 
#' 
#' [get_basins.R](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_basins.md)
#' should be run before this script.

#'
#' ## libraries
#' Start by sourcing two helper scripts
#' ([helper_main.R](https://github.com/deankoch/UYRW_data/blob/master/markdown/helper_main.md) and
#' [helper_get_data.R](https://github.com/deankoch/UYRW_data/blob/master/markdown/helper_get_data.md))
#' which set up required libraries and directories and define some utility functions.
library(here)
source(here('R/helper_main.R'))
source(here('R/get_data/helper_get_data.R'))

#' [`FedData`](https://cran.r-project.org/web/packages/FedData/index.html) is used to fetch the USGS data
#' and [`colorspace`](https://cran.r-project.org/web/packages/colorspace/vignettes/colorspace.html) provides
#' a palette for the terrain map.
library(FedData)
library(colorspace)

#'
#' ## project data
#+ echo=FALSE
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
  
  # DEM masked to UYRW region, for input to QSWAT+
  c(name='swat_dem',
    file=file.path(out.subdir, 'swat_dem.tif'), 
    type='GeoTIFF raster file',
    description='digital elevation map of the UYRW for QSWAT+ input'), 
  
  # Hillshade raster from DEM
  c(name='hillshade',
    file=file.path(out.subdir, 'hillshade.tif'), 
    type='GeoTIFF raster file',
    description='hillshade map of the UYRW and surrounding area, computed from dem'), 
  
  # graphic showing DEM for the UYRW
  c(name='img_dem',
    file=file.path(graphics.dir, 'dem.png'),
    type='png graphic',
    description='image of DEM for the UYRW')

)

#' A list object definition here (`files.towrite`) has been hidden from the markdown output for
#' brevity. The list itemizes all files written by the script along with a short description.
#' We use a helper function to write this information to disk:
dem.meta = my_metadata('get_dem', files.towrite, overwrite=TRUE)
print(dem.meta[, c('file', 'type')])
 
#' This list of files and descriptions is now stored as a
#' [.csv file](https://github.com/deankoch/UYRW_data/blob/master/data/get_dem_metadata.csv)
#' in the `/data` directory.
#' 
#' Load some of the data prepared earlier 
# load CRS info list and watershed polygon from disk
crs.list = readRDS(here(my_metadata('get_basins')['crs', 'file']))
uyrw.poly = readRDS(here(my_metadata('get_basins')['boundary', 'file']))


#'
#' ## Download DEM raster
#' 
#' The `get_ned` function from `FedData` retrieves and merge all (12) required elevation tiles from the USGS NED
if(!file.exists(here(dem.meta['ned', 'file'])))
{
  # We will downloaded the DEM for an extended UYRW boundary, to allow modeling of nearby weather records 
  boundary.padded.sp = as_Spatial(uyrw.padded.poly)
  
  # This function call downloads tiles to "/RAW", extracts them, and writes the mosaic to "UYRW_NED_1" in "/data/source"
  dem.original.tif = get_ned(template=boundary.padded.sp, label='UYRW', extraction.dir=here(src.subdir))
  
  # remove the temporary files
  unlink(here('RAW'), recursive=TRUE)
  
} else {
  
  # load the NED raster from disk
  dem.original.tif = raster(here(dem.meta['ned', 'file']))
}

#'
#' ## Processing

#' Warp (gridded CRS transform) and clip the raster to our reference system and study area 
if(!file.exists(here(dem.meta['dem', 'file'])))
{
  # define a temporary file
  temp.tif = paste0(tempfile(), '.tif')
  
  # package 'gdalUtils' performs these kinds of operations much faster than `raster`
  gdalwarp(srcfile=here(dem.meta['ned', 'file']), 
           dstfile=temp.tif,
           t_srs=paste0('EPSG:', crs.list$epsg),
           overwrite=TRUE)
  
  # load the transformed raster (resolution is approx 30m x 30m)
  dem.tif = raster(temp.tif)
  
  # write to output directory
  writeRaster(dem.tif, here(dem.meta['dem', 'file']), overwrite=TRUE)

} else {
  
  # load from disk 
  dem.tif = raster(here(dem.meta['dem', 'file']))
}

#' use GDAL to derive hillshade (via slope and aspect) from the DEM
if(!file.exists(here(dem.meta['hillshade', 'file'])))
{
  # define a temporary file
  temp.tif = paste0(tempfile(), '.tif')
  
  # package 'gdalUtils' performs these kinds of operations much faster than `raster`
  gdaldem(mode='hillshade',
          input_dem=here(dem.meta['dem', 'file']),
          output_map=temp.tif,
          z=30)
  
  # load the transformed raster
  hillshade.tif = raster(temp.tif)
  
  # write to output directory
  writeRaster(hillshade.tif, here(dem.meta['hillshade', 'file']), overwrite=TRUE)
  
} else {
  
  # load from disk 
  hillshade.tif = raster(here(dem.meta['hillshade', 'file']))
}

#'
#' ## create SWAT+ readable DEM file
#' 
#' This chunk simply crops/masks the DEM to the UYRW boundary, and writes to disk using a
#' no-data flag that is understood by QSWAT+.
#' 
if(!file.exists(here(dem.meta['swat_dem', 'file'])))
{
  # crop/mask the DEM 
  uyrw.poly.sp = as(uyrw.poly, 'Spatial')
  swat.dem.tif = mask(crop(dem.tif , uyrw.poly.sp), uyrw.poly.sp)
  
  # write the rasters to disk with new NA integer code
  writeRaster(swat.dem.tif, here(dem.meta['swat_dem', 'file']), overwrite=TRUE, NAflag=tif.na.val)
}


#'
#' ## visualization
#' 

#' plot the DEM raster
#' ![elevation map of the UYRW](https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/dem.png)
if(!file.exists(here(dem.meta['img_dem', 'file'])))
{
  # mask/crop both rasters to the uyrw boundary
  uyrw.poly.sp = as(uyrw.poly, 'Spatial')
  dem.clipped.tif = crop(mask(dem.tif, uyrw.poly.sp), uyrw.poly.sp)
  hillshade.clipped.tif = crop(mask(hillshade.tif, uyrw.poly.sp), uyrw.poly.sp)
  
  # load the plotting parameters used in get_basins.R
  tmap.pars = readRDS(here(my_metadata('get_basins')['pars_tmap', 'file']))
  
  # set up two palettes: one for hillshading and one for elevation
  nc = 1e3
  hillshade.palette = gray(0:nc/nc)
  dem.palette = sequential_hcl(nc, palette='Terrain')
  
  # build the tmap object
  tmap.dem = tm_shape(hillshade.clipped.tif, raster.downsample=FALSE, bbox=st_bbox(uyrw.poly)) +
      tm_raster(palette=hillshade.palette, legend.show=FALSE) +
    tm_shape(dem.clipped.tif) +
      tm_raster(palette=dem.palette, title='elevation (m)', style='cont', alpha=0.7) +
    tm_shape(uyrw.poly) +
      tm_borders(col='white') +
    tmap.pars$layout +
    tm_layout(main.title='Digital elevation map of the UYRW',
              legend.position = c('right', 'top'))
              
  # render the plot
  tmap_save(tm=tmap.dem, 
            here(dem.meta['img_dem', 'file']), 
            width=tmap.pars$png['w'], 
            height=tmap.pars$png['h'], 
            pointsize=tmap.pars$png['pt'])
}


#+ include=FALSE
# Development code
#my_markdown('get_dem', 'R/get_data')
