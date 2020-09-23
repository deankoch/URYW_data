## about us

We are a team of mathematicians, statisticians, and ecologists, conducting a multi-year research project to develop an operational forecasting system for streamflow and water quality on the [Upper Yellowstone River](http://fwp.mt.gov/mtoutdoors/images/Storyimages/2017/UpperYellowstoneMap.jpg) (UYR) and its tributaries. Our system will be based on [SWAT-MODFLOW](https://www.sciencedirect.com/science/article/abs/pii/S136481521930893X?via%3Dihub), a hybrid of the [SWAT+](https://swatplus.gitbook.io/docs/) (Soil-Water-Assessment Tool) model for surface water dynamics and [MODFLOW](https://www.usgs.gov/mission-areas/water-resources/science/modflow-and-related-programs?qt-science_center_objects=0#qt-science_center_objects) (Modular Finite-Difference Flow) for groundwater dynamics. 

## R code

The UYRW_data repository is a staging area for R code that can be used to fetch data on the hydrology of UYR. This repository will be active during the early stages of our project (August-November 2020), as we assemble datasets and build documentation for the model:
* [get_basins](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_basins.md)
defines the study area and loads some hydrology info using `nhdplusTools`
* [get_weatherstations](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_weatherstations.md)
finds SNOTEL and NOAA climatic sensor station data using `snotelr` and `rnoaa`
* [get_dem](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_dem.md)
downloads and processes the National Elevation Dataset from USGS using `FedData`
* [get_streamgages](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_streamgages.md)
finds streamflow and groundwater sensor data from the USGS NWIS using `dataRetrieval`
* [get_soils](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_soils.md)
fetches SSURGO/STATSGO2 data from the Soil Data Mart using `FedData`
* [get_landuse](https://github.com/deankoch/UYRW_data/blob/master/markdown/get_landuse.md)
fetches GAP/LANDFIRE data from the USGS

Check back for more scripts and figures as we add to this list in the coming weeks. 

Our R data analysis workflow is structured around git and markdown. Our scripts (\*.R) are documented as dynamic reports -- markdown files of the form \*.knit.md. These document our code and methods in human-readable detail, with console output and figures incorporated automatically using [`rmarkdown` using roxygen2](https://rmarkdown.rstudio.com/articles_report_from_r_script.html). See Jennifer Bryan's [Am Stat article](https://amstat.tandfonline.com/doi/abs/10.1080/00031305.2017.1399928) and [instructional pages](https://happygitwithr.com/) for more on this.

## funding

Our work is funded through a [MITACS](https://www.mitacs.ca/en/about) [Accelerate International](https://www.mitacs.ca/en/programs/accelerate/mitacs-accelerate-international) grant to Dean Koch, partnering the University of Alberta with R2CS LLC in Montana, and the [Yellowstone Ecological Research Center](https://www.yellowstoneresearch.org/yerc-lab). The project began on August 3, 2020.

## gallery

R is a powerful data-retrieval, GIS, and visualization tool. These figures are generated by the scripts in our repo:

<img src="https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/uyrw_flowlines.png" width="45%"></img> <img src="https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/uyrw_basins.png" width="45%"></img> <img 
src="https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/weatherstation_sites.png" width="45%"></img> <img src="https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/streamgage_sites.png" width="45%"> <img
src="https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/dem.png" width="45%"> <img
src="https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/soils.png" width="45%"> <img
src="https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/soils_wstor.png" width="45%"> <img
src="https://raw.githubusercontent.com/deankoch/UYRW_data/master/graphics/landuse.png" width="45%"> </img> 
