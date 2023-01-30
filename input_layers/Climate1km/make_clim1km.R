## Making world precipitation and temperature maps at 1km resolution using multisource data
## tom.hengl@gmail.com

library(rgdal)
library(parallel)
library(raster)
library(data.table)
setwd("/data/clim1km")
load(".RData")

source("/data/OpenLandData/R/OpenLandData_covs_functions.R")
days <- as.numeric(format(seq(ISOdate(2015,1,1), ISOdate(2015,12,31), by="month"), "%j"))-1
m.lst <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")

## Dowload WorldClim v2:
setwd("/data/clim1km/WorldClim")
bil.lst <- c("http://biogeo.ucdavis.edu/data/worldclim/v2.0/tif/base/wc2.0_30s_prec.zip", "http://biogeo.ucdavis.edu/data/worldclim/v2.0/tif/base/wc2.0_30s_tavg.zip", "http://biogeo.ucdavis.edu/data/worldclim/v2.0/tif/base/wc2.0_30s_tmin.zip", "http://biogeo.ucdavis.edu/data/worldclim/v2.0/tif/base/wc2.0_30s_tmax.zip", "http://biogeo.ucdavis.edu/data/worldclim/v2.0/tif/base/wc2.0_30s_srad.zip")
x = mclapply(bil.lst, function(i){system(paste0("wget -nv -q ", i, " /data/clim1km/WorldClim/", basename(i)))}, mc.cores = 5)
system('7z e /data/clim1km/WorldClim/wc2.0_30s_prec.zip')

## Download Chelsa climate:
setwd("/data/clim1km/CHELSA")
z.lst = c(
  paste0("https://www.wsl.ch/lud/chelsa/data/climatologies/prec/CHELSA_prec_", 1:12, "_land.7z"), 
  paste0("https://www.wsl.ch/lud/chelsa/data/climatologies/temp/integer/temp/CHELSA_temp10_0", 1:9, "_land.7z"),
  paste0("https://www.wsl.ch/lud/chelsa/data/climatologies/temp/integer/temp/CHELSA_temp10_", 10:12, "_land.7z"), 
  paste0("https://www.wsl.ch/lud/chelsa/data/climatologies/temp/integer/tmin/CHELSA_tmin10_0", 1:9, "_land.7z"),
  paste0("https://www.wsl.ch/lud/chelsa/data/climatologies/temp/integer/tmin/CHELSA_tmin10_", 10:12, "_land.7z"),
  paste0("https://www.wsl.ch/lud/chelsa/data/climatologies/temp/integer/tmax/CHELSA_tmax10_0", 1:9, "_land.7z"),
  paste0("https://www.wsl.ch/lud/chelsa/data/climatologies/temp/integer/tmax/CHELSA_tmax10_", 10:12, "_land.7z"),
  paste0("https://www.wsl.ch/lud/chelsa/data/bioclim/integer/CHELSA_bio10_", 1:19, "_land.7z"))
x = mclapply(z.lst, function(i){system(paste0("wget -nc -q ", i, " /data/clim1km/CHELSA/", basename(i)))}, mc.cores = 10)
x = mclapply(paste0("/data/clim1km/CHELSA/CHELSA_prec_", 1:12, "_land.7z"), function(i){system(paste0("7z e ", i))})
x = mclapply(paste0("/data/clim1km/CHELSA/CHELSA_bio10_", 1:19, "_land.7z"), function(i){system(paste0("7z e ", i))})
x = mclapply(list.files("/data/clim1km/CHELSA", pattern=glob2rx("CHELSA_t*_*_land.7z"), full.names = TRUE), function(i){system(paste0("7z e ", i, " -y"))}, mc.cores = 64)

## Aggregate to 1km:
tif.lst = list.files("/data/clim1km/CHELSA", pattern=glob2rx("CHELSA_bio10_*.tif$"), full.names = TRUE)
x = parallel::mclapply(tif.lst, function(i){ system(paste0('gdalwarp ', i, ' /data/OpenLandData/layers1km/', gsub(".tif", "_1km.tif", basename(i)), ' -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "), ' -co \"COMPRESS=DEFLATE\"')) }, mc.cores = length(tif.lst))

## IMERGE images (https://pmm.nasa.gov/gpm/imerg-global-image):
## https://gpm1.gesdisc.eosdis.nasa.gov/
setwd("/data/clim1km")
im.lst <- list.files("./IMERGE", pattern=glob2rx("*.tif$"), full.names = TRUE)
## 44
GDALinfo(im.lst[2])
dsel <- c(paste0("0", 1:9), "10", "11", "12") 
## TAKES 15 mins
x = parallel::mclapply(1:length(dsel), function(i){ stack_stats_inram(tif.sel=im.lst[unlist(sapply(paste0(".", 2014:2017, dsel[i]), function(y){ grep(y, im.lst) }))], out.tifs=paste0("./IMERGEm/IMERG_", m.lst[i], "_", c("min","med","max"), "_2014_2017_10km.tif"), type="Int16", mvFlag=-32767) }, mc.cores = 12)

## Import precipitation station data ----
## ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/v2/
v2.prcp = read.table("v2.prcp", col.names=c("station_id", "Year", m.lst), na.string=c("-8888", "-9999"))
v2.prcp.inv = read.table("v2.prcp.inv", col.names=c("station_id", "station_name", "country", "latitude", "longitude", "elevation"))
## overlay and build a model to predict precipitation

## Simple average using WorldClim, IMERGE and CHELSA:
r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
cellsize = res(r)[1]
p4s = proj4string(r)

x = raster::sampleRandom(raster("/data/clim1km/WorldClim/wc2.0_30s_prec_02.tif"), 300, sp=TRUE)
v.x = lapply(c("/data/clim1km/WorldClim/wc2.0_30s_prec_02.tif", "/data/clim1km/CHELSA/CHELSA_prec_2_V1.2_land.tif","/data/clim1km/IMERGEm/IMERG_Feb_med_2014_2017_10km.tif"), function(i){ raster::extract(raster(i), x) })
sapply(v.x, mean, na.rm=TRUE)
v.x2 = lapply(c("/data/clim1km/WorldClim/wc2.0_30s_prec_06.tif", "/data/clim1km/CHELSA/CHELSA_prec_6_V1.2_land.tif","/data/clim1km/IMERGEm/IMERG_Jun_med_2014_2017_10km.tif"), function(i){ raster::extract(raster(i), x) })
sapply(v.x2, mean, na.rm=TRUE)
v.x3 = lapply(c("/data/clim1km/WorldClim/wc2.0_30s_prec_09.tif", "/data/clim1km/CHELSA/CHELSA_prec_9_V1.2_land.tif","/data/clim1km/IMERGEm/IMERG_Sep_med_2014_2017_10km.tif"), function(i){ raster::extract(raster(i), x) })
sapply(v.x3, mean, na.rm=TRUE)
v.x4 = lapply(c("/data/clim1km/WorldClim/wc2.0_30s_prec_11.tif", "/data/clim1km/CHELSA/CHELSA_prec_11_V1.2_land.tif","/data/clim1km/IMERGEm/IMERG_Nov_med_2014_2017_10km.tif"), function(i){ raster::extract(raster(i), x) })
sapply(v.x4, mean, na.rm=TRUE)
## IMERGE about 10-20% higher values than WorldClim?

for(i in 1:12){
  saga_grid_stats(in.tif.lst=c(paste0("/data/clim1km/WorldClim/wc2.0_30s_prec_", dsel[i], ".tif"), paste0("/data/clim1km/CHELSA/CHELSA_prec_", i, "_V1.2_land.tif"), paste0("/data/clim1km/IMERGEm/IMERG_", m.lst[i], "_med_2014_2017_10km.tif")), out.tif.lst=c(paste0("mPREC_M_", m.lst[i], "_1km_ll.tif"), paste0("mPREC_sd_", m.lst[i], "_1km_ll.tif")), r.lst=c("near","near","cubicspline"), d.lst=c(-32767, -32767, -32767), tr=1/120, te=te, p4s=p4s)
}

## Total annual precipitation:
Ml <- list.files("/data/OpenLandData/layers1km", pattern=glob2rx("mPREC_M_*_1km_ll.tif$"), full.names = TRUE)
sumf <- function(x){calc(x, sum, na.rm=TRUE)}
beginCluster()
r1 <- clusterR(raster::stack(Ml), fun=sumf, filename="/data/OpenLandData/layers1km/mPREC_sum_1km_ll.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"))
endCluster()

## Mean min and max daily temperature as average between WorldClim and CHELSA climate:
in.tif.lst = list.files("/data/clim1km/CHELSA", pattern=glob2rx("CHELSA_t*_*_land.tif$"), full.names = TRUE)
r = raster("/data/clim1km/WorldClim/wc2.0_30s_tmin_07.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
## resample CHELSA images to WorldClim grid:
x = parallel::mclapply(1:length(in.tif.lst), function(i) { system(paste0('gdalwarp ', in.tif.lst[i], ' ', gsub("/data/clim1km/CHELSA", "/data/clim1km/WorldClim", in.tif.lst[i]),' -co \"COMPRESS=DEFLATE\" -r \"near\" -tr ', res(r)[1], ' ', res(r)[2], ' -te ', paste(te, collapse = " "))) }, mc.cores=length(in.tif.lst))

mean_inram <- function(tif.sel, out.tif, type="Int16", mvFlag=-32767){
  if(!file.exists(out.tif)){
    m = readGDAL(fname=tif.sel[1], silent = TRUE)
    m@data[,2] = readGDAL(fname=tif.sel[2], silent = TRUE)$band1 * 10
    m$v = rowMeans(m@data[,1:2], na.rm=TRUE)
    writeGDAL(m["v"], out.tif, type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    gc()
  }
}

m.lst = c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
tif.m = data.frame(tif1 = c(paste0("/data/clim1km/WorldClim/CHELSA_temp10_",1:12,"_1979-2013_V1.2_land.tif"), paste0("/data/clim1km/WorldClim/CHELSA_tmin10_",1:12,"_1979-2013_V1.2_land.tif"), paste0("/data/clim1km/WorldClim/CHELSA_tmax10_",1:12,"_1979-2013_V1.2_land.tif")), tif2 = c(paste0("/data/clim1km/WorldClim/wc2.0_30s_tavg_", c(paste0("0", 1:9),10:12), ".tif"), paste0("/data/clim1km/WorldClim/wc2.0_30s_tmin_",c(paste0("0", 1:9),10:12),".tif"), paste0("/data/clim1km/WorldClim/wc2.0_30s_tmax_",c(paste0("0", 1:9),10:12),".tif")), m=rep(m.lst, 3), x=as.vector(unlist(sapply(c("mean","min","max"), rep, 12))))
#tif.sel = paste0("/data/clim1km/WorldClim/", c("CHELSA_temp10_6_1979-2013_V1.2_land.tif","wc2.0_30s_tavg_06.tif"))
#out.tif = "mTEMP_mean_June_1km_ll.tif"

library(snowfall)
snowfall::sfInit(parallel=TRUE, cpus=5)
snowfall::sfLibrary(rgdal)
snowfall::sfExport("tif.m", "mean_inram")
out <- snowfall::sfClusterApplyLB(1:nrow(tif.m), function(i){ try( mean_inram(tif.sel = c(paste(tif.m$tif1[i]), paste(tif.m$tif2[i])), out.tif = paste0("mTEMP_", tif.m$x[i],"_", tif.m$m[i], "_1km_ll.tif")) ) })
snowfall::sfStop()

