## Land mask at 250m and 1 km based on ESA Land cover time series (https://www.esa-landcover-cci.org/?q=node/175)
## tom.hengl@gmail.com

setwd("/data/ESA_global")
load(".RData")
library(raster)
library(rgdal)

r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
GDALinfo("/data/LDN/ESA_landcover/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992_2015-v2.0.7.tif")

## resample to 250m resolution and bounding box:
snowfall::sfInit(parallel=TRUE, cpus=16)
snowfall::sfLibrary(rgdal)
snowfall::sfLibrary(raster)
snowfall::sfExport("r", "te")
out <- snowfall::sfClusterApplyLB(2000:2015, function(i){ system(paste0('gdalwarp /data/LDN/300m_ll/ESACCI-LC-L4-LCCS-Map-300m-P1Y-', i, '-v2.0.7_ll.tif /data/LandGIS/layers250m/lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_', i,'_v1.0.tif -r \"near\" -tr ', res(r)[1], ' ', res(r)[2], ' -te ', paste(te, collapse = " "), ' -co \"COMPRESS=DEFLATE\"')) })
snowfall::sfStop()

## 1km
snowfall::sfInit(parallel=TRUE, cpus=16)
snowfall::sfLibrary(rgdal)
snowfall::sfLibrary(raster)
snowfall::sfExport("te")
out <- snowfall::sfClusterApplyLB(2000:2015, function(i){ system(paste0('gdalwarp /data/LDN/300m_ll/ESACCI-LC-L4-LCCS-Map-300m-P1Y-', i, '-v2.0.7_ll.tif /data/LandGIS/upscaled1km/lcv_land.cover_esacci.lc.l4_c_1km_s0..0cm_', i,'_v1.0.tif -r \"near\" -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "), ' -co \"COMPRESS=DEFLATE\"')) })
snowfall::sfStop()

tile.tbl = readRDS("/data/LandGIS/models/stacked250m_tiles.rds")
#pr.dirs = readRDS("/data/LandGIS/models/prediction_dirs.rds")
new.dirs <- paste0("/data/tt/OpenLandData/covs250m/T", tile.tbl$ID)
x <- lapply(new.dirs, dir.create, recursive=TRUE, showWarnings=FALSE)
pr.dirs <- paste0("T", tile.tbl$ID)
save.image()

## land mask function
land_mask = function(i, tile.tbl, in.dir="/data/LandGIS/layers250m/", out.path="/data/tt/OpenLandData/covs250m"){
  out.tif = paste0(out.path, "/", i, "/LandMask_CL_", i, ".tif")
  if(!file.exists(out.tif)){
    i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
    m = readGDAL(fname=paste0(in.dir, "lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_2000_v1.0.tif"), offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    for(j in 1:15){
      m@data[,j+1] = readGDAL(fname=paste0(in.dir, "lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_",2000+j,"_v1.0.tif"), offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1  
    }
    names(m) = paste0("LC", 2000:2015)
    ## Long-term water bodies, permenanet ice, deserts:
    m$mask = ifelse(apply(m@data[,paste0("LC", 2000:2015)], 1, FUN=function(x){all(x==210)}), 2,  ifelse(apply(m@data[,paste0("LC", 2000:2015)], 1, FUN=function(x){all(x==200)}), 3, ifelse(apply(m@data[,paste0("LC", 2000:2015)], 1, FUN=function(x){all(x==220)}), 4, 1)))
    #plot(m["mask"])
    writeGDAL(m["mask"], out.tif, type="Byte", mvFlag=255, options=c("COMPRESS=DEFLATE"))
    ## 1 = land
    ## 2 = water bodies
    ## 3 = bare areas
    ## 4 = permanent ice
  }
}

sfInit(parallel=TRUE, cpus=24)
sfExport("land_mask", "tile.tbl", "pr.dirs")
sfLibrary(rgdal)
out.lst <- sfClusterApplyLB(pr.dirs, function(x){ land_mask(x, tile.tbl=tile.tbl) })
sfStop()

## Prepare landmask maps at various resolutions:
lstD <- list.files(path="/data/tt/OpenLandData/covs250m", pattern=glob2rx("LandMask_CL_*.tif$"), full.names=TRUE, recursive = TRUE)
out.tmp <- tempfile(fileext = ".txt")
cat(lstD, sep="\n", file=out.tmp)
system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' LandMask_CL.vrt'))
system(paste0('gdalwarp LandMask_CL.vrt /data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif -tr ', res(r)[1], ' ', res(r)[2], ' -te ', paste(te, collapse = " "), ' -r \"near\" -t_srs \"+proj=longlat +datum=WGS84\" -ot \"Byte\" -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\" -overwrite'))
system(paste0('gdalwarp /data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif /data/LandGIS/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "), ' -r \"near\" -ot \"Byte\" -co \"COMPRESS=DEFLATE\" -overwrite'))
system(paste0('gdalwarp /data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif /data/LandGIS/layers500m/lcv_landmask_esacci.lc.l4_c_500m_s0..0cm_2000..2015_v1.0.tif -tr ', 1/240, ' ', 1/240, ' -te ', paste(te, collapse = " "), ' -r \"near\" -ot \"Byte\" -co \"COMPRESS=DEFLATE\" -overwrite'))
save.image()