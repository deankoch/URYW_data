## about us

We are a team of mathematicians, statisticians, and ecologists, conducting a multi-year research project to develop an operational forecasting system for streamflow and water quality on the [Upper Yellowstone River](http://fwp.mt.gov/mtoutdoors/images/Storyimages/2017/UpperYellowstoneMap.jpg) (UYR) and its tributaries. Our system will be based on [SWAT-MODFLOW](https://www.sciencedirect.com/science/article/abs/pii/S136481521930893X?via%3Dihub), a hybrid of the [SWAT+](https://swatplus.gitbook.io/docs/) (Soil-Water-Assessment Tool) model for surface water dynamics and [MODFLOW](https://www.usgs.gov/mission-areas/water-resources/science/modflow-and-related-programs?qt-science_center_objects=0#qt-science_center_objects) (Modular Finite-Difference Flow) for groundwater dynamics. 

## R code

The URYW_data repository is a staging area for R code that can be used to fetch data on the hydrology of UYR. This repository will be active during the early stages of our project (August-November 2020), as we assemble datasets and build documentation for the model.

Our R data analysis workflow is structured around git and markdown, as outlined in Jennifer Bryan's [Am Stat article](https://amstat.tandfonline.com/doi/abs/10.1080/00031305.2017.1399928) (see also her instructional pages [here](https://happygitwithr.com/)). Our scripts (\*.R) are documented as dynamic reports -- markdown files of the form \*.knit.md. These document our code and methods in human-readable detail, complete with console output and figures. They are compiled automatically by [`rmarkdown` using roxygen2](https://rmarkdown.rstudio.com/articles_report_from_r_script.html):

* [get_basins.R](https://github.com/deankoch/URYW_data/blob/master/get_basins.knit.md)
defines the study area and loads some hydrology info using `NHDPlusR`
* [get_weatherstations.R](https://github.com/deankoch/URYW_data/blob/master/get_weatherstations.knit.md)
finds SNOTEL and NOAA climatic sensor station data

Check back for more scripts and figures as we add to this list in the coming weeks. 

## funding

Our work is funded through a [MITACS](https://www.mitacs.ca/en/about) [Accelerate International](https://www.mitacs.ca/en/programs/accelerate/mitacs-accelerate-international) grant to Dean Koch, partnering the University of Alberta with R2CS LLC in Montana, and the [Yellowstone Ecological Research Center](https://www.yellowstoneresearch.org/yerc-lab). The project began on August 3, 2020.

## gallery

R is a powerful GIS and visualization tool. These figures are generated by the various R scripts in our repository:

<img src="https://raw.githubusercontent.com/deankoch/URYW_data/master/graphics/uyrw_flowlines.png" width="45%"></img> <img src="https://raw.githubusercontent.com/deankoch/URYW_data/master/graphics/uyrw_basins.png" width="45%"></img> <img 
src="https://raw.githubusercontent.com/deankoch/URYW_data/master/graphics/weatherstation_sites.png" width="45%"></img> <img src="https://raw.githubusercontent.com/deankoch/URYW_data/master/graphics/dem.png" width="45%"></img> 

