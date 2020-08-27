get\_weatherstations.R
================
Dean Koch
August 13, 2020

**MITACS UYRW project**

**get\_weatherstations**: finds climatic sensor stations located in the
UYRW

The [`snotelr`](https://github.com/bluegreen-labs/snotelr) package
fetches [SNOTEL network data](https://www.wcc.nrcs.usda.gov/snow/) from
the USDA; and the [`rnoaa`](https://github.com/ropensci/rnoaa) package
fetches [GHCN Daily](https://www.ncdc.noaa.gov/ghcn-daily-description)
data (see documentation
[here](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt)). We
use them to build a map of climatic sensor stations in the UYRW, and to
query historical data for model training.

[get\_basins.R](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_basins.md)
which creates some required directories and project config files, should
be run before this script.

## libraries

`snotelr` and `rnoaa` are used to fetch data. See the [get\_helperfun.R
script](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_basins.md),
for other required libraries

``` r
library(here)
source(here('get_helperfun.R'))
library(snotelr)
library(rnoaa)
```

## project data

``` r
# load metadata csv, CRS info list and watershed geometries from disk
crs.list = readRDS(here(my_metadata('get_basins')['crs', 'file']))
uyrw.poly = readRDS(here(my_metadata('get_basins')['boundary', 'file']))
uyrw.waterbody = readRDS(here(my_metadata('get_basins')['waterbody', 'file']))
uyrw.mainstem = readRDS(here(my_metadata('get_basins')['mainstem', 'file']))
uyrw.flowline = readRDS(here(my_metadata('get_basins')['flowline', 'file']))

# This list describes all of the files created by this script:
files.towrite = list(
  
  # metadata table downloaded from SNOTEL website
  c(name='snotel.csv',
    file=file.path(src.subdir, 'snotel_sites.csv'), 
    type='CSV', 
    description='metadata list for SNOTEL sites (unchanged)'), 
  
  # SNOTEL metadata table as an sfc object
  c(name='snotel',
    file=file.path(out.subdir, 'snotel_sites.rds'), 
    type='R sf object', 
    description='sfc object with SNOTEL sensor locations in UYRW'),
  
  # GHCND metadata table downloaded from NOAA
  c(name='ghcnd.csv',
    file=file.path(src.subdir, 'ghcnd_sites.csv'), 
    type='CSV', 
    description='metadata list for GHCND sites (unchanged)'),
  
  # GHCND metadata table as an sfc object
  c(name='ghcnd',
    file=file.path(out.subdir, 'ghcnd_sites.rds'),
    type='R sf object',
    description='sfc object with GHCN Daily sensor locations in UYRW'),
  
  # sfc object representing a padded (outer buffer) watershed boundary 
  c(name='boundary_padded',
    file=file.path(out.subdir, 'uyrw_boundary_padded.rds'),
    type='R sf object',
    description='padded watershed boundary polygon for querying nearby weather stations'),
  
  # aesthetic parameters for plotting
  c(name='tmap.pars',
    file=file.path(data.dir, 'get_weatherstations_tmap.rds'), 
    type='R list object', 
    description='parameters for writing png plots using tmap and tm_save'),
  
  # graphic showing SNOTEL and GHCND site locations on the UYRW
  c(name='img_weatherstation',
    file=file.path(graphics.dir, 'weatherstation_sites.png'),
    type='png graphic', 
    description='image of SNOTEL and GHCND site locations in the UYRW')
  
)

# write this information to disk
my_metadata('get_weatherstations', files.towrite, overwrite=TRUE)
```

    ## [1] "writing to data/get_weatherstations_metadata.csv"

    ##                                                      file          type                                                            description
    ## tmap.pars               data/get_weatherstations_tmap.rds R list object                parameters for writing png plots using tmap and tm_save
    ## snotel.csv                   data/source/snotel_sites.csv           CSV                             metadata list for SNOTEL sites (unchanged)
    ## snotel                     data/prepared/snotel_sites.rds   R sf object                        sfc object with SNOTEL sensor locations in UYRW
    ## ghcnd.csv                     data/source/ghcnd_sites.csv           CSV                              metadata list for GHCND sites (unchanged)
    ## ghcnd                       data/prepared/ghcnd_sites.rds   R sf object                    sfc object with GHCN Daily sensor locations in UYRW
    ## boundary_padded    data/prepared/uyrw_boundary_padded.rds   R sf object padded watershed boundary polygon for querying nearby weather stations
    ## img_weatherstation      graphics/weatherstation_sites.png   png graphic                   image of SNOTEL and GHCND site locations in the UYRW
    ## metadata            data/get_weatherstations_metadata.csv           CSV                   list files of files written by get_weatherstations.R

This list of files and descriptions is now stored as a [.csv
file](https://github.com/deankoch/UYRW_data/blob/master/data/get_weatherstation_metadata.csv)
in the `/data` directory. Climatic data near the boundaries of the
watershed will be useful for interpolation. Define a padded boundary
polygon to search inside for station data

``` r
if(!file.exists(here(my_metadata('get_weatherstations')['boundary_padded', 'file'])))
{
  # for now I use a 25km buffer
  uyrw.padded.poly = st_buffer(uyrw.poly, dist = 25e3)
  saveRDS(uyrw.padded.poly, here(my_metadata('get_weatherstations')['boundary_padded', 'file']))
  
} else {
  
  # load from disk 
  uyrw.padded.poly = readRDS(here(my_metadata('get_weatherstations')['boundary_padded', 'file']))
  
}
```

## Find SNOTEL sites

the `snotel_info` function in `snotelr` downloads a CSV containing site
IDs and coordinates

``` r
if(!file.exists(here(my_metadata('get_weatherstations')['snotel.csv', 'file'])))
{
  # download the metadata csv to the folder specified in `path`. This writes the file "snotel_metadata.csv"
  snotel_info(path=here(src.subdir))
  
  # rename the csv to avoid confusion with identically-named file in the parent folder (my list of project files)
  file.rename(from=here(src.subdir, 'snotel_metadata.csv'), to=here(my_metadata('get_weatherstations')['snotel.csv', 'file']))
  
}
```

Load this CSV, omit stations not in UYRW, and convert it to a `sf`
object, then save to disk

``` r
if(!file.exists(here(my_metadata('get_weatherstations')['snotel', 'file'])))
{
   # load the site info table into a data frame and extract coordinates
  snotel.df = read.csv(here(my_metadata('get_weatherstations')['snotel.csv', 'file']), header=TRUE)
  sites.coords.matrix = as.matrix(snotel.df[, c('longitude', 'latitude')])
  
  # extract the coordinates and convert to sfc object, adding attribute columns to get sf object
  snotel.sfc = st_sfc(lapply(1:nrow(snotel.df), function(xx) st_point(sites.coords.matrix[xx,])), crs=crs.list$epsg.geo)
  snotel.sf = st_sf(cbind(snotel.df, snotel.sfc))
  
  # transform to UTM and clip to UYRW area (30 stations identified)
  snotel.sf = st_transform(snotel.sf, crs=crs.list$epsg)
  snotel.sf = st_intersection(snotel.sf, uyrw.padded.poly)
  
  # save to disk
  saveRDS(snotel.sf, here(my_metadata('get_weatherstations')['snotel', 'file']))
  
} else {
  
  # load from disk 
  snotel.sf = readRDS(here(my_metadata('get_weatherstations')['snotel', 'file']))
  
}
```

## Find NOAA Global Historical Climatology Network (GHCN) Daily sites

the `ghcnd_stations` function in `rnoaa` downloads a table of site IDs
and coordinates

``` r
if(!file.exists(here(my_metadata('get_weatherstations')['ghcnd.csv', 'file'])))
{
  # download the metadata table and load into R (slow, 1-2min)
  ghcnd.df = ghcnd_stations()

  # save a copy as csv in the /data/source folder
  write.csv(ghcnd.df, here(my_metadata('get_weatherstations')['ghcnd.csv', 'file']))

}
```

Load this CSV. It indexed over 100,000 stations worldwide\! This chunk
transforms the coordinates to UTM, omits stations not in UYRW (leaving
138), converts the result to an `sf` object with one feature per
station, and saves the result to disk

``` r
if(!file.exists(here(my_metadata('get_weatherstations')['ghcnd', 'file'])))
{

  # load the site info table into a data frame
  ghcnd.df = read.csv(here(my_metadata('get_weatherstations')['ghcnd.csv', 'file']), header=TRUE)
  
  # find all unique station IDs, extracting coordinates from the first entry in the table for each station 
  ghcnd.IDs = unique(ghcnd.df$id)
  idx.duplicateID = duplicated(ghcnd.df$id)
  sum(!idx.duplicateID) 
  ghcnd.coords.matrix = as.matrix(ghcnd.df[!idx.duplicateID, c('longitude', 'latitude')])
  
  # create sfc object from points, appending only the id field
  ghcnd.sfc = st_sfc(lapply(1:sum(!idx.duplicateID), function(xx) st_point(ghcnd.coords.matrix[xx,])), crs=crs.list$epsg.geo)
  ghcnd.sf = st_sf(cbind(data.frame(id=ghcnd.df[!idx.duplicateID, 'id']), ghcnd.sfc))
  
  # transform to our reference system
  ghcnd.sf = st_transform(ghcnd.sf, crs=crs.list$epsg)
  
  # some (polar area) points are undefined in the UTM transformation, remove them
  ghcnd.sf = ghcnd.sf[!st_is_empty(ghcnd.sf),]
  
  # clip to UYRW watershed region (95 stations) then join with the other attributes that are constant across "id"
  ghcnd.sf = st_intersection(ghcnd.sf, uyrw.padded.poly)
  idx.ghcnd.uyrw = which(!idx.duplicateID)[ghcnd.df$id[!idx.duplicateID] %in% ghcnd.sf$id]
  ghcnd.sf = cbind(ghcnd.sf, ghcnd.df[idx.ghcnd.uyrw, c('longitude', 'latitude', 'elevation', 'name')])
  nrow(ghcnd.sf)
  
  # "element" attribute varies by site "id". There are 45 possibilities in the UYRW area
  ghcnd.elem = unique(ghcnd.df[ghcnd.df$id %in% ghcnd.sf$id, 'element'])
  length(ghcnd.elem)
  
  # double sapply call to this function builds a table indicating which elements are available in which year
  ghcnd.elem.df = t(sapply(ghcnd.sf$id, function(idval) sapply(ghcnd.elem, function(elemval) my.ghcnd.reshape(idval, elemval))))
  
  # join this data to the sfc object (reordering to emphasize most populated fields)
  ghcnd.sf = cbind(ghcnd.sf, ghcnd.elem.df[,order(apply(ghcnd.elem.df, 2, function(xx) sum(!is.na(xx))), decreasing=TRUE)])
  
  # There is some overlap with SNOTEL. Identify the GHCND sites that are indexed by SNOTEL
  ghcnd.sf$snowtel_id = apply(st_distance(ghcnd.sf, snotel.sf), 1, function(xx) ifelse(!any(xx<1), NA, snotel.sf$site_id[xx<1]))
  
  # save to disk
  saveRDS(ghcnd.sf, here(my_metadata('get_weatherstations')['ghcnd', 'file']))
  
  
} else {
  
  # load from disk
  ghcnd.sf = readRDS(here(my_metadata('get_weatherstations')['ghcnd', 'file']))
  
} 
```

## visualization

Set up the aesthetics to use for these types of plots

``` r
if(!file.exists(here(my_metadata('get_weatherstations')['tmap.pars', 'file'])))
{
  # load the plotting parameters used in get_basins.R
  tmap.pars = readRDS(here(my_metadata('get_basins')['tmap.pars', 'file']))
  
  # adjust them to suit these wider plots (with legends)
  tmap.pars$png['w'] = 1800 
  
  # configuration for plotting the locations of time series data
  tmap.pars$dots = tm_dots(size='duration',
                           col='endyear',
                           shape=16,
                           palette='magma',
                           style='cont',
                           alpha=0.7, 
                           contrast=0.7, 
                           title.size='duration (years)',
                           legend.size.is.portrait=TRUE,
                           shapes.legend.fill='grey20',
                           shapes.legend=1,
                           perceptual=TRUE,
                           sizes.legend=c(5,25,50,75,125),
                           title='decomissioned', 
                           textNA='currently operational',
                           colorNA='red2')
  
  # parameters related to the layout for building legends
  tmap.pars$layout = tmap.pars$layout + 
    tm_layout(legend.format=list(fun=function(x) formatC(x, digits=0, format='d')),
              legend.outside=TRUE,
              legend.outside.position='right',
              legend.text.size=tmap.pars$label.txt.size)
  
  # save to disk
  saveRDS(tmap.pars, here(my_metadata('get_weatherstations')['tmap.pars', 'file']))
  
} else {
  
  # load from disk
  tmap.pars = readRDS(here(my_metadata('get_weatherstations')['tmap.pars', 'file']))
  
} 
```

Start by preparing some data for a plot of precipitation sensors in the
area of the UYRW

``` r
# make a copy of the points datasets, omitting stations with only temperature data
idx.onlytemp = is.na(ghcnd.sf$PRCP) & is.na(ghcnd.sf$SNWD) & is.na(ghcnd.sf$SNOW)
precip.sf = ghcnd.sf[!idx.onlytemp,]

# add columns for duration and end-year of time series for precipitation
years.PRCP = strsplit(precip.sf$PRCP,'-')
endyear.PRCP = sapply(years.PRCP, function(xx) as.numeric(xx[2]))
duration.PRCP = endyear.PRCP - sapply(years.PRCP, function(xx) as.numeric(xx[1]))
precip.sf$duration = duration.PRCP
precip.sf$endyear = endyear.PRCP
precip.sf$endyear[precip.sf$endyear == 2020] = NA

# add a dummy column (containing a plot label) for indicating SNOTEL stations
precip.sf$constant = 'SNOTEL station'
```

build the plot and write to disk

``` r
# plot precipitation sensor station locations as a png file
if(!file.exists(here(my_metadata('get_weatherstations')['img_weatherstation', 'file'])))
{
  # build the tmap plot object
  tmap.precip = tm_shape(uyrw.padded.poly) +
                  tm_polygons(col='gray', border.col=NA) +
                tm_shape(uyrw.poly) +
                  tm_polygons(col='greenyellow', border.col='yellowgreen') +
                tm_shape(uyrw.waterbody) +
                  tm_polygons(col='yellowgreen', border.col='yellowgreen') +
                tm_shape(uyrw.mainstem) +
                  tm_lines(col='yellowgreen', lwd=2) +
                tm_shape(uyrw.flowline) +
                  tm_lines(col='yellowgreen') +
                tm_shape(precip.sf[!is.na(precip.sf$snowtel_id),]) +
                  tm_dots(col='constant', palette='black', size=0.5, shape=6, title='') +
                tm_shape(precip.sf) +
                tmap.pars$dots + 
                tmap.pars$layout +
                tm_layout(main.title='GHCN (daily) precipitation records in the UYRW')
  
  
  # render/write the plot
  tmap_save(tm=tmap.precip, 
            here(my_metadata('get_weatherstations')['img_weatherstation', 'file']), 
            width=tmap.pars$png['w'], 
            height=tmap.pars$png['h'], 
            pointsize=tmap.pars$png['pt'])
}
```

![weather stations in the
UYRW](https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/weatherstation_sites.png)

Data downloads look like this:

``` r
# xx = meteo_pull_monitors('US1MTPK0001')
# yy = snotel_download(site_id = 363, internal=TRUE)
```
