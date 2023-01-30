## Intact areas / protected planet:
## 2014, IFL Mapping Team: Greenpeace, University of Maryland, Transparent World, World Resource Institute, WWF Russia. Results/reports can be viewed at www.intactforests.org
## Protected planet WPDA Data (http://www.protectedplanet.net/)
## tom.hengl@gmail.com

setwd("/data/protectedplanet")
load(".RData")
library(raster)
library(rgdal)
source("/data/OpenLandData/R/OpenLandData_covs_functions.R")

r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
xllcorner = te[1]
yllcorner = te[2]
xurcorner = te[3]
yurcorner = te[4]
cellsize = res(r)[1]

pp.zip.lst <- list.files(pattern = glob2rx("*.zip$"), full.names = TRUE)
sapply(pp.zip.lst, function(x){system(paste("7za x ", x," -r -y"))})
ogrInfo("WDPA_Dec2017-shapefile-polygons.shp", "WDPA_Dec2017-shapefile-polygons")
ogrInfo("ifl_2013.shp", "ifl_2013")
## rasterize:
shp.lst = c("WDPA_Dec2017-shapefile-polygons.shp", "ifl_2013.shp", "ifl_2000.shp")
field.lst = c("STATUS_YR","IFL_ID","IFL_ID")
x = sapply(1:length(shp.lst), function(x){rasterize_pol(INPUT=shp.lst[x], FIELD=field.lst[x], cellsize, xllcorner, yllcorner, xurcorner, yurcorner)})
system('gdal_translate WDPA_Dec2017-shapefile-polygons.sdat WDPA_Dec2017-shapefile-polygons.tif -ot \"Int16\" -co \"COMPRESS=DEFLATE\"')
system('gdal_translate ifl_2013.sdat ifl_2013.tif -ot \"Int16\" -co \"COMPRESS=DEFLATE\"')
system('gdal_translate ifl_2000.sdat ifl_2000.tif -ot \"Int16\" -co \"COMPRESS=DEFLATE\"')
tif.lst = gsub(".shp", ".tif", shp.lst)
parallel::mclapply(tif.lst, function(i){ system(paste0('gdalwarp ', i, ' /data/OpenLandData/layers1km/', gsub(".tif", "_1km_ll.tif", i), ' -tr ', 1/120, ' ', 1/120, ' -co \"COMPRESS=DEFLATE\" -r \"near\" -te ', paste(te, collapse = " "))) }, mc.cores=3)
GDALinfo("/data/OpenLandData/layers1km/ifl_2013_1km_ll.tif")
GDALinfo("/data/OpenLandData/layers1km/GAUL_ADMIN0_landmask_1km_ll.tif")
save.image()