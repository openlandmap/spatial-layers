## Processing NEO images at 10km resolution https://neo.sci.gsfc.nasa.gov/
## tom.hengl@gmail.com

setwd("/data/NEO")
load(".RData")
library(rgdal)
library(parallel)
library(raster)
library(data.table)

source("/data/OpenLandData/R/OpenLandData_covs_functions.R")
m.lst <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
dsel <- c(paste0("0", 1:9), "10", "11", "12") 

vw.lst = list.files("./MODAL2_M_SKY_WV", ".FLOAT.TIFF", full.names = TRUE)
## TAKES 15 mins
x = parallel::mclapply(1:length(dsel), function(i){ stack_stats_inram(tif.sel=vw.lst[unlist(sapply(paste0("_", 2000:2017, "-", dsel[i]), function(y){ grep(y, vw.lst) }))], out.tifs=paste0("/data/OpenLandData/layers10km/MODAL2_M_SKYWV_", m.lst[i], "_", c("min","med","max"), "_2000_2017_10km.tif"), type="Int16", mvFlag=-32767, na.max.value=1e3, scale.v=100) }, mc.cores = 12)

ln.lst = list.files("./MOD11C1_M_LSTNI", ".FLOAT.TIFF", full.names = TRUE)
x = parallel::mclapply(1:length(dsel), function(i){ stack_stats_inram(tif.sel=ln.lst[unlist(sapply(paste0("_", 2000:2017, "-", dsel[i]), function(y){ grep(y, ln.lst) }))], out.tifs=paste0("/data/OpenLandData/layers10km/MOD11C1_M_LSTNI_", m.lst[i], "_", c("min","med","max"), "_2000_2017_10km.tif"), type="Int16", mvFlag=-32767, na.min.value=-100, na.max.value=100) }, mc.cores = 12)

in.lst = list.files("./CERES_INSOL_M", ".FLOAT.TIFF", full.names = TRUE)
x = parallel::mclapply(1:length(dsel), function(i){ stack_stats_inram(tif.sel=in.lst[unlist(sapply(paste0("_", 2000:2017, "-", dsel[i]), function(y){ grep(y, in.lst) }))], out.tifs=paste0("/data/OpenLandData/layers10km/CERES_INSOL_M_", m.lst[i], "_", c("min","med","max"), "_2000_2017_10km.tif"), type="Int16", mvFlag=-32767, na.min.value=-1, na.max.value=2000) }, mc.cores = 12)

sn.lst = list.files("./MOD10C1_M_SNOW", ".FLOAT.TIFF", full.names = TRUE)
x = parallel::mclapply(1:length(dsel), function(i){ stack_stats_inram(tif.sel=sn.lst[unlist(sapply(paste0("_", 2000:2017, "-", dsel[i]), function(y){ grep(y, sn.lst) }))], out.tifs=paste0("/data/OpenLandData/layers10km/MOD10C1_M_SNOW_", m.lst[i], "_", c("min","med","max"), "_2000_2017_10km.tif"), type="Int16", mvFlag=-32767, na.min.value=0, na.max.value=101) }, mc.cores = 12)

ae.lst = list.files("./MYDAL2_M_AER_OD", ".FLOAT.TIFF", full.names = TRUE)
x = parallel::mclapply(1:length(dsel), function(i){ stack_stats_inram(tif.sel=ae.lst[unlist(sapply(paste0("_", 2000:2017, "-", dsel[i]), function(y){ grep(y, ae.lst) }))], out.tifs=paste0("/data/OpenLandData/layers10km/MYDAL2_M_AER_OD_", m.lst[i], "_", c("min","med","max"), "_2000_2017_10km.tif"), type="Int16", mvFlag=-32767, na.min.value=0, na.max.value=101, scale.v = 100) }, mc.cores = 12)
## too many missing pixels - use sums / std:
Ml <- list.files("/data/OpenLandData/layers10km", pattern=glob2rx("MYDAL2_M_AER_OD_*_med_2000_2017_10km.tif$"), full.names = TRUE)
meanf <- function(x){calc(x, mean, na.rm=TRUE)}
sdf <- function(x){calc(x, sd, na.rm=TRUE)}
beginCluster()
r1 <- clusterR(raster::stack(Ml), fun=meanf, filename="/data/OpenLandData/layers10km/MYDAL2_mean_AER_OD_med_2000_2017_10km.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"))
r2 <- clusterR(raster::stack(Ml), fun=sdf, filename="/data/OpenLandData/layers10km/MYDAL2_sd_AER_OD_med_2000_2017_10km.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"))
endCluster()

## Resample to 1 km resolution:
r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
cellsize = res(r)[1]

in.tif.lst = list.files("/data/OpenLandData/layers10km", glob2rx("*_med_*.tif$"), full.names = TRUE)
x = parallel::mclapply(1:length(in.tif.lst), function(i) { system(paste0('gdalwarp ', in.tif.lst[i], ' ', gsub("10km", "1km", in.tif.lst[i]),' -co \"COMPRESS=DEFLATE\" -r \"cubicspline\" -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "))) }, mc.cores = 58)

in.env.lst = list.files("/data/EarthEnv", glob2rx("*.tif$"), full.names = TRUE)
x = parallel::mclapply(1:length(in.env.lst), function(i) { system(paste0('gdalwarp ', in.env.lst[i], ' /data/OpenLandData/layers1km/', gsub(".tif", "_1km_ll.tif", basename(in.env.lst[i])),' -co \"COMPRESS=DEFLATE\" -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "))) }, mc.cores = length(in.env.lst))

in.1km.lst = c(list.files("/data/stacked1km", glob2rx("*USG5.tif$"), full.names = TRUE), paste0("/data/stacked1km/", c("TWIMRG5","GTDHYS3"),".tif"))
x = parallel::mclapply(1:length(in.1km.lst), function(i) { system(paste0('gdalwarp ', in.1km.lst[i], ' /data/OpenLandData/layers1km/', gsub(".tif", "_1km_ll.tif", basename(in.1km.lst[i])),' -co \"COMPRESS=DEFLATE\" -r \"near\" -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "))) }, mc.cores = length(in.1km.lst))

in.250m.lst = c(list.files("/data/stacked250m", glob2rx("*MOD3.tif$"), full.names = TRUE), paste0("/data/stacked250m/", c("TWIMRG5","GTDHYS3","GIEMSD3"),".tif"))
x = parallel::mclapply(1:length(in.250m.lst), function(i) { system(paste0('gdalwarp ', in.250m.lst[i], ' /data/OpenLandData/layers1km/', gsub(".tif", "_1km_ll.tif", basename(in.250m.lst[i])),' -co \"COMPRESS=DEFLATE\" -r \"average\" -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "))) }, mc.cores = length(in.250m.lst))

in.500m.lst = list.files("/data/ESA_global", glob2rx("ESACCI_snow_prob_*_500m.tif$"), full.names = TRUE)
x = parallel::mclapply(1:length(in.500m.lst), function(i) { system(paste0('gdalwarp ', in.500m.lst[i], ' /data/OpenLandData/layers1km/', gsub("_500m.tif", "_1km_ll.tif", basename(in.500m.lst[i])),' -co \"COMPRESS=DEFLATE\" -r \"near\" -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "))) }, mc.cores = length(in.500m.lst))
