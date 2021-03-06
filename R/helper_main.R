#' ---
#' title: "helper_main.R"
#' author: "Dean Koch"
#' date: "`r format(Sys.Date())`"
#' output: github_document
#' ---
#'
#' **Mitacs UYRW project** 
#' 
#' **helper_main**: general helper functions for all scripts in the UYRW_data repository 
#' 
#' This script is meant to be sourced by all other scripts in the repository. It defines some
#' helper functions and directories for local storage.
#' 
#'
#' ## libraries
#' These CRAN packages are quite useful, and are at many stages in the repository workflow.
#' If any of these are not already installed on your machine, run `install.packages(...)` to
#' get them.

#' [`raster`](https://rspatial.org/raster/) handles raster data such as GeoTIFFs
library(raster)

#' [`sf`](https://r-spatial.github.io/sf/) handles GIS data such as ESRI shapefiles
library(sf)

#' [`ggplot2`](https://ggplot2.tidyverse.org/) popular graphics package with high-level abstraction
library(ggplot2)  

#' [`tmap`](https://github.com/mtennekes/tmap) constructs pretty thematic map graphics
library(tmap)

#' [`dplyr`](https://dplyr.tidyverse.org/R) tidyverse-style manipulation of tabular data
library(dplyr)

#' ['RSQLite'](https://www.r-project.org/nosvn/pandoc/RSQLite.html) connects to SQLite databases
library(RSQLite)

#' ['data.table'](https://cran.r-project.org/web/packages/data.table/index.html) for large I/O files
library(data.table)

#' [`gdalUtilities`](https://cran.r-project.org/web/packages/gdalUtilities/index.html) GDAL wrapper
library(gdalUtilities)

#' [`rvest`](https://cran.r-project.org/web/packages/rvest/rvest.pdf) web scraping
library(rvest) 

#' [`units`](https://cran.r-project.org/web/packages/units/index.html) units for numerics
library(units)

#' [`jsonlite`](https://cran.r-project.org/web/packages/jsonlite) handle JSON I/O
library(jsonlite)


#'
#' ## global variables
#+ results='hide'

#' We start by defining a project directory tree
# TODO: wrap these in a function or make their variable names more unique

# 'graphics', 'markdown', 'data' are top level directories in the RStudio project folder
graphics.dir = 'graphics'
markdown.dir = 'markdown'
data.dir = 'data'

# subdirectories of `data`: source files, pre-processed files, analysis results, demos
src.subdir = 'data/source'
out.subdir = 'data/prepared'
sci.subdir = 'data/analysis'
demo.subdir = 'data/demo'

# missing data field (NA) is coded as "-99.0"
tif.na.val = -99


#'
#' ## project data

#' To avoid downloading things over and over again, we'll use a permanent storage location on
#' disk (/data). This is where we store large data files and R object binaries, which are not
#' suitable for git.
#' 
#' The `if(!file.exists(...))` conditionals preceding each code chunk indicate which files will
#' be written in that section. If the files are detected in the local data storage directory,
#' then that code chunk can be skipped (to avoid redundant downloads, *etc*), and the files are
#' loaded from disk instead. 
#' 


#' Define a helper function for creating folders then create project folders as needed
my_dir = function(path) { if(!dir.exists(path)) {dir.create(path, recursive=TRUE)} }
lapply(here(c(data.dir, src.subdir, out.subdir, graphics.dir, markdown.dir)), my_dir)


#' This project will generate many files. To keep track of everything, each script gets a CSV
#' table documenting every file that it creates: its file path, its type, and a short description
#' of the contents. This function handles the construction of the table. To call up the table for
#' a specific script, simply use `my_metadata(script.name)`.
#' 
my_metadata = function(script.name, entries.list=NA, overwrite=FALSE, 
                       use.file=TRUE, data.dir='data', v=TRUE)
{
  # creates and/or adds to a data frame of metadata documenting a given script, and (optionally)
  # writes it to disk as a CSV file 
  #
  # ARGUMENTS:
  #
  # `script.name`: character, filename of the R script to document (without the .R extension)
  # `entries.list`: list of character vectors, with entries 'name', 'file', 'type', 'description'
  # `data.dir`: character, subdirectory for CSV file (/<data.dir>/<scriptname>_metadata.csv) 
  # `use.file`: boolean, indicating whether to read/write the CSV file
  # `overwrite`: boolean, indicating to overwrite existing CSV files 
  # `v`: boolean, indicating to print a console message
  #
  # RETURN VALUE:
  #
  # a data frame containing a table of file info, combining the elements of `entries.list` with
  # data from the CSV corresponding to the script name (if it exists)
  #
  # BEHAVIOUR: 
  #
  # With `use.file==FALSE` the function simply returns `entries.list`, reshaped as a data.frame. 
  #
  # With `use.file==TRUE`, the function looks for an existing CSV file, reads it, and combines it
  # with the elements of `entries.list`. New entries take precedence: ie. any element of
  # `entries.list` whose 'name' field matches an existing row in the CSV will replace that row.
  # Elements with names not appearing the CSV are added to the top of the table in the order they
  # appear in `entries.list`.
  #
  # Existing CSV files are never modified unless `use.file` and `overwrite` are both TRUE. In this
  # case if the CSV file does not already exist on disk it will be created. The default
  # `entries.list==NA`, combined with `overwrite=TRUE` and `use.file=TRUE` will overwrite the CSV
  # with a default placeholder - a table containing only a single row, which describes the CSV file
  # itself.
  
  # define the CSV filename
  csv.relpath = file.path(data.dir, paste0(script.name, '_metadata.csv'))
  
  # flag to wipe CSV replace with a default
  csv.wipe = FALSE
  
  # create the directory if necessary
  my_dir(dirname(here(csv.relpath)))
  
  # prepare the default one-row data.frame 
  entry.names = c('name', 'file', 'type', 'description')
  entry.default = c(name='metadata', 
                    file=csv.relpath, 
                    type='CSV', 
                    description='expected location of this CSV')
  
  # parse `entries.list` to check for wrong syntax or NA input
  if(!is.list(entries.list))
  {
    # if `entries.list` is not a list, it must be a single NA. Stop if it's a vector
    if(length(entries.list) > 1)
    {
      stop('entries.list must be either a list or (length-1) NA value')
      
    } else {
      
      # Catch non-NA, non-list input 
      if(!is.na(entries.list))
      {
        stop('entries.list must be either a list or (length-1) NA value')
      } 
    }
    
    # Recursive call to generate the data frame with default entry
    input.df = my_metadata(script.name, entries.list=list(entry.default), use.file=FALSE)
    
    # set the flag to overwrite with default one-row table, if requested
    if(overwrite) {csv.wipe = TRUE}
    
  } else {
    
    # entries.list is a list. Check for non-character vector inputs
    if(!all(sapply(entries.list, is.character)))
    {
      stop('all elements of entries.list must be character vectors')
    }
    
    # halt on incorrectly named vectors
    if(!all(sapply(entries.list, function(entry) all(names(entry)==entry.names))))
    {
      msg.badnm = paste(entry.names, collapse=', ')
      stop(paste0('each element of entries.list must be a named vector with names: ', msg.badnm))
    }
    
    # entries.list is valid input. Construct the data frame
    input.df = data.frame(do.call(rbind, entries.list), row.names='name')
  }
  
  # data.frame() ignores row.names when nrows==1
  if(!is.null(input.df$name))
  {
    # fix names
    rownames(input.df) = input.df$name
    input.df = input.df[,-which(names(input.df)=='name')]
  }
  
  # if not reading a CSV from disk, we're finished
  if(!use.file)
  {
    return(input.df)
    
  } else {
    
    # create a second data frame to store any data from the csv on disk
    csv.df = my_metadata(script.name, entries.list=list(entry.default), use.file=FALSE)
    
    # look for the file on disk and load it if it exists
    if(file.exists(here(csv.relpath)) & !csv.wipe)
    {
      # load the csv data 
      csv.df = read.csv(here(csv.relpath), header=TRUE, row.names=1)
    }
    
    # identify any entries in csv.df with names matched in entries.list
    names.updating = rownames(csv.df)[rownames(csv.df) %in% rownames(input.df)]
    
    # update them, and delete those rows from input.df
    csv.df[names.updating,] = input.df[names.updating,]
    input.df = input.df[!(rownames(input.df) %in% names.updating),]
    
    # merge the two data frames
    output.df = rbind(input.df, csv.df)
    if(overwrite)
    {
      # CSV file is written to disk
      if(v) print(paste('> writing metadata to:', csv.relpath))
      write.csv(output.df, here(csv.relpath))
      return(output.df)
      
    } 
    
    return(output.df)
    
  }
}

#' My R scripts are commented using a roxygen2 syntax that is interpretable by `rmarkdown`,
#' for conversion to markdown via pandoc. This convenience function renders the markdown file
#' for a given R script and writes to a file of the same name (but with a .md extension).
my_markdown = function(script.name, script.dir='R', markdown.dir='markdown', type='md')
{
  # ARGUMENTS:
  #
  # `script.name`: character, filename of the R script to render (without the .R extension).
  # `script.dir`: character, subfolder of project directory containing the R script.
  # `markdown.dir`: character, subfolder of project directory for output markdown file(s).
  #
  # RETURN VALUE:
  #
  # null
  #
  # BEHAVIOUR: 
  #
  # Writes the file <project directory>/<markdown.dir>/<script.name>.md, overwriting without warning
  
  # set up in/out files
  path.input = here(script.dir, paste0(script.name, '.R'))
  path.output = here(file.path(markdown.dir, paste0(script.name, '.', type)))
  
  # note: run_pandoc=FALSE appears to cause output_dir to be ignored...
  paste('rendering markdown file', path.output, 'from the R script', path.input)
  rmarkdown::render(path.input, 
                    clean=TRUE, 
                    output_file=path.output)
  # ...so this call may generate an unwanted html file
  # TODO: fix this or delete the html 
}


#' R has a built-in library of `map` objects, the geographical coordinates of adminstrative
#' boundaries and point locations (eg states, countries, cities) in list form. Since we are
#' working with the `sf` package in a projected coordinate system it's handy to have a helper
#' function to wrap `maps::map` calls
my_maps = function(db, outcrs=NULL)
{
  # ARGUMENTS:
  #
  # `db`, character, name of geographical database (see `help(package='maps')`)
  # `outcrs`, integer or character, passed to `st_transform`
  #
  # RETURN VALUE:
  #
  # sf object containing all polygons from the maps database
  #
  # DETAILS: 
  #
  # Output sf will have columns 'name' (the polygon name, usually a placename or qualifier)
  # and 'mapsdb' (the name of the maps database it came from).
  #
  # If `db` matches none of the exported databases from `maps`, the function loads the
  # `world` database and does a case insensitive search among its 1000+ names. If this
  # matches nothing, the function returns an empty  
  # 
  
  # default is unprojected lat/long
  crs.geo = 4326
  if( is.null(outcrs)) outcrs = crs.geo
  
  # hack to check if supplied database is a valid name 
  maps.nmspc = get('.__NAMESPACE__.', inherits=FALSE, envir=asNamespace('maps', base.OK=FALSE))
  db.found = paste0(db, 'MapEnv') %in% names(maps.nmspc$lazydata)
  
  # fetch the data if `db` is lazyloaded from maps
  if(db.found)
  {
    # open the database and extract polygon names and coordinates
    maps.out = maps::map(db, plot=F, fill=T)
    db.nm = maps.out$names
    db.xy = do.call(cbind, maps.out[c('x', 'y')])
    
    # distinct polygons are separated by NAs in the coords vectors
    x.isdelim = is.na(db.xy[,1])
    
    # make an indexing vector to split over NA delimiters (omitting them)
    idx.out = split( seq_along(db.xy[,1])[ !x.isdelim ], cumsum( x.isdelim )[ !x.isdelim ] )
    db.list = lapply(setNames(idx.out, db.nm), function(x) db.xy[x,])
    
    # convert this list to a single sf object
    db.sfc = lapply(db.list, function(x) st_sfc(st_polygon(list(x)), crs=crs.geo))
    db.sf = st_sf(data.frame(nm=names(db.sfc), db=db), do.call(c, db.sfc))

    # clean up column names, transform to `outcrs` projection, and finish
    names(db.sf) = c('name', 'mapsdb', 'geometry')
    return( st_transform( st_set_geometry(db.sf, 'geometry'), crs=outcrs ) )
    
  } else {
    
    # otherwise grep for the supplied string in `world` database
    world.result = my_maps('world')
    idx.world = grepl(db, world.result$name, ignore.case=TRUE)
    
    # return any matches, and print a warning if there were none
    if(sum(idx.world) == 0) warning('no matches for supplied `db`')
    return( world.result[idx.world,] )
  }
}


#' Wrapper for ggplot calls to make hydrographs and other time series plots
my_tsplot = function(dat, colors=NULL, alph=0.8, yaxis='flow', 
                     legnm=NULL, legsc=NULL, legp=NULL,
                     yunit=NULL, ysqrt=FALSE)
{
  # ARGUMENTS:
  #
  # `dat`: dataframe with 'date' column and at least one column coercible to numeric 
  # `colors`: character, palette name (see `hcl.pals()` or ...)
  # `alph`: numeric in [0, 1], transparency of (all) lines
  # `yaxis`: y axis label
  # `legnm`: character, optional title for the legend
  # `legsc`: numeric, legend scale - values to map to the non-date columns
  # `legp`: character or length-2 numeric vector, passed as 'legend.position' to `theme`
  #
  # `yunit`: units to use for y-axis
  # `ysqrt`: indicating to plot y-values on square root scale
  #
  # RETURN VALUE:
  #
  # The ggplot grob
  #
  # DETAILS: 
  #
  # non-date columns of `dat` may be `units` objects, in which case the unit is appended
  # to the legend title. Cases of inconsistent units are resolved by converting everything
  # to the units of the first `units`-type column. Mixtures of `units` and `numeric` type
  # columns are accepted and plotted unchanged.
  #
  # when `legsc` is supplied, it should be a numeric vector with one entry per non-date
  # column of `dat`. These values are used to construct a continuous legend colorbar that
  # replaces the default discrete scale
  # 
 
  # identify the date column
  idx.date = which( names(dat) == 'date' )[1]
  if( is.na(idx.date) ) idx.date = which( sapply(dat, class) == 'Date' )[1]
  if( is.na(idx.date) ) stop('dat appears to have no date column') 
  names(dat)[idx.date] = 'date'
    
  # parse the non-date columns, checking for units
  idx.nondate = c( 1:ncol(dat) )[-idx.date]
  ny = length(idx.nondate)
  y.nm = names(dat)[idx.nondate]
  y.hasunits = sapply(y.nm, function(x) inherits(dat[[x]], 'units'))
  
  # handle unit conversions as needed and add units to y axis label
  ysuffix = ''
  if( sum(y.hasunits) > 0 )
  {
    # extract units as strings
    y.units = sapply(y.nm[y.hasunits], function(x) as.character( units(dat[[x]]) ) )
    
    # match to user-supplied units (or first unit in dataframe)
    plot.units = ifelse( is.null(yunit), y.units[1], yunit ) 
    idx.match = y.units == plot.units
    if( !all(idx.match) )
    {
      # unit conversion of mismatches
      for( nm in names(idx.match)[!idx.match] )
      {
        dat[[nm]] = set_units(dat[[nm]], plot.units, mode='standard')
      }
    }
    
    # drop units from df now that everything is matching (non-unit columns not modified!)
    dat = drop_units(dat)
    ysuffix = paste0('(', plot.units, ')')
  }
  
  #transform data for square-root y-axis transform requests
  yprefix = ''
  if( ysqrt ) 
  {
    # take roots and modify y axis label
    dat[,idx.nondate] = sqrt(dat[,idx.nondate])
    yprefix = 'square-root of'
  }

  # set default colours as needed, checking for palette strings
  if( is.null(colors) ) colors = 'Temps'
  if( length(colors) == 1 )
  {
    # assign hcl colour palettes (+ 1 to avoid errors on ny == 1 calls) 
    if( colors %in% hcl.pals() ) { colors = hcl.colors(ny + 1, palette=colors)[-(ny + 1)] }
  }
  
  # set up the axis labels
  ggp.axlab = labs(x = names(dat)[idx.date], y = paste(yprefix, yaxis, ysuffix), color = '')

  # create the ggplot line objects
  colmap = y.nm
  is.continuous = !is.null(legsc)
  if( is.continuous ) colmap = legsc
  ggp.line = lapply(seq_along(y.nm), function(x) {
    geom_line(aes_(y=dat[[y.nm[x]]], color=colmap[x]), alpha=alph) 
    })
 
  # initialize the plot grob
  ggp.out = ggplot(data=dat, aes(date)) +
    geom_line(aes(y=0), color='grey50') + ggp.line +
    theme_minimal() + ggp.axlab  + 
    theme(legend.position=legp)
  
  # add discrete color bar
  if(!is.continuous) ggp.out = ggp.out + 
    scale_color_manual(legnm, values=setNames(colors, y.nm)) +
    guides(color = guide_legend(override.aes = list(size=1, alpha=1)))
  
  # add continuous color bar
  if( is.continuous ) ggp.out = ggp.out + 
    scale_colour_gradientn(legnm, colors=colors, guide='colourbar')

  return(ggp.out)
}


#+ include=FALSE
#my_markdown('helper_main')
