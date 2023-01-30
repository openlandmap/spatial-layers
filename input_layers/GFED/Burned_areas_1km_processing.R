## Burned Area global dynamics; data source: http://www.globalfiredata.org/index.html
## Global Fire Emissions Database, Version 5.1 (GFED4s)
## tom.hengl@opengeohub.org

library(rgdal)
library(raster)
library(matrixStats)
library(data.table)
library(parallel)
library(lubridate)
#install.packages("BiocManager")
#BiocManager::install("rhdf5")
library(rhdf5)
#library(Rfast)

## Server:
## OS: Ubuntu 18.04.5 LTS
## RAM: 376,6 GiB
## Processor: Intel® Xeon(R) Gold 6248 CPU @ 2.50GHz × 80

#g20km = raster("/mnt/lacus/raw/ESACCI_fire/GFED/GFED4.1s_1997.hdf5")
hdf.lst = list.files("/mnt/lacus/raw/ESACCI_fire/GFED", glob2rx("*.hdf5$"), full.names = TRUE)
## 25
# https://gis.stackexchange.com/questions/330602/converting-hdf5-to-geotiff-using-gdal
GDALinfo(paste0('HDF5:', hdf.lst[1], '://burned_area/01/burned_fraction'))
get_gfed = function(i){
  m.lst = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")
  out = paste0('./GFED_20km/burned_area_', basename(i), '_', m.lst, '.tif')
  if(any(!file.exists(out))){
    require(rhdf5)
    #h5ls(i)
    ## h_te_mean = Mean terrain height for segment
    ## h_mean_canopy = Mean of individual relative canopy heights within segment
    grid = h5read(i, '/burned_area')
    grid = data.frame(lapply(grid, function(i){as.vector(i$burned_fraction)*100}))
    grid$lon = as.vector(h5read(i, '/lon'))
    grid$lat = as.vector(h5read(i, '/lat'))
    coordinates(grid) = ~ lon + lat
    proj4string(grid) = CRS("EPSG:4326")
    gridded(grid) = TRUE
    for(j in 1:length(out)){
      writeGDAL(grid[j], out[j], type="Byte", mvFlag = 255, options = c("COMPRESS=DEFLATE"))
    }
  }
}
library(snowfall)
sfInit(parallel=TRUE, cpus=length(hdf.lst))
sfExport("get_gfed", "hdf.lst")
sfLibrary(rhdf5)
sfLibrary(rgdal)
out <- sfClusterApplyLB(hdf.lst, function(i){try(get_gfed(i))})
sfStop()
## Did not work:
#df.hdf = expand.grid(basename(hdf.lst), m.lst)
#df.hdf$layername = paste0('://burned_area/', df.hdf$Var2, '/burned_fraction')
#df.hdf$filename = paste0('./GFED_20km/burned_area_', df.hdf$Var1, '_', df.hdf$Var2, '.tif')
#x = parallel::mclapply(1:nrow(df.hdf), function(i){system(paste0('gdal_translate HDF5:\"/mnt/lacus/raw/ESACCI_fire/GFED/', df.hdf$Var1[i], '\"', df.hdf$layername[i], ' ', df.hdf$filename[i], ' -co \"COMPRESS=DEFLATE\" -a_srs "EPSG:4326" -a_ullr -180 -90 180 90'))}, mc.cores = 80)

## GFED_monthly
mon.lst = list.files("/mnt/lacus/raw/ESACCI_fire/monthly", glob2rx("*.hdf$"), full.names = TRUE)
## 259
GDALinfo(paste0('HDF4_SDS:UNKNOWN:', mon.lst[200], ':0'))
read_hdf = function(i, out.dir='./GFED_monthly/'){
  #x = raster::flip(raster(paste0('HDF4_SDS:UNKNOWN:', i, ':0')), direction='x')
  x = raster(paste0('HDF4_SDS:UNKNOWN:', i, ':0'))
  r <- setExtent(x, c(-180, 180, -90, 90))
  ## convert to ha
  r <- r * 0.009999999776 
  proj4string(r) = "EPSG:4326"
  writeRaster(r, paste0(out.dir, gsub('.hdf', '.tif', basename(i))), datatype='INT4S', options='COMPRESS=DEFLATE', overwrite=TRUE)
}
x = parallel::mclapply(mon.lst, read_hdf, mc.cores = 40)
## downscale to 1km ----
m.tifs = list.files("./GFED_monthly", glob2rx("*.tif$"), full.names = TRUE)
m.y = sapply(basename(m.tifs), function(i){strsplit(i, "_")[[1]][3]})
out.tifs = paste0("./GFED_1km/nhz_monthly.burned.ha_gfed_m_1km_s0..0cm_", substr(m.y, 1, 4), ".", substr(m.y, 5, 6), "_epsg4326_v4.tif")
#data.frame(basename(m.tifs[1]), basename(out.tifs[1]))
x = parallel::mclapply(1:length(m.tifs), function(i){system(paste0('gdalwarp ', m.tifs[i], ' ', out.tifs[i], ' --config GDAL_CACHEMAX 9216 -co BLOCKSIZE=1024 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co NUM_THREADS=10 -co LEVEL=9 -of COG -r \"cubicspline\" -ot \"Int32\" -dstnodata -9999 -te -180.00000 -62.00083 180.00000 87.37000 -tr 0.008333333 0.008333333'))}, mc.cores=20)

## resample 500m ----
## Burned areas from https://maps.elie.ucl.ac.be/CCI/viewer/
r1km = raster("/mnt/gaia/tmp/openlandmap/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif")
te = as.vector(extent(r1km))[c(1,3,2,4)]
r500m = raster("/mnt/gaia/tmp/openlandmap/layers500m/clm_snow.prob_esacci.sep_sd_500m_s0..0cm_2000..2012_v2.0.tif")
te2 = as.vector(extent(r500m))[c(1,3,2,4)]

## Convert to COG ----
months.lst = sort(c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"))
in.tifs = list.files("/mnt/landmark/burned", glob2rx("*.tif$"), full.names = TRUE)
out.tifs = paste0("./MODIS_500m_COG/nhz_burned.area.occurrence_esa.modis.", months.lst, "_p90_500m_s0..0cm_2000..2012_epsg4326_v1.tif")
#View(data.frame(in.tifs, out.tifs))
x = parallel::mclapply(1:length(in.tifs), function(i){system(paste0('gdalwarp ', in.tifs[i], ' ', out.tifs[i], ' --config GDAL_CACHEMAX 9216 -co BLOCKSIZE=1024 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co NUM_THREADS=10 -co LEVEL=9 -of COG -r \"bilinear\" -ot \"Byte\" -dstnodata 255 -te -180.00000 -62.00083 180.00000 87.37000 -tr 0.004166667 0.004166667'))}, mc.cores=12)
## Sum / annual burned area derived in QGIS
system(paste0('gdalwarp ESA_burned_p90_sum.tif ./MODIS_500m_COG/nhz_burned.area.occurrence_esa.modis.annual_p90_500m_s0..0cm_2000..2012_epsg4326_v1.tif --config GDAL_CACHEMAX 9216 -co BLOCKSIZE=1024 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co NUM_THREADS=10 -co LEVEL=9 -of COG -r \"bilinear\" -ot \"Int16\" -dstnodata -32768 -te -180.00000 -62.00083 180.00000 87.37000 -tr 0.004166667 0.004166667'))
