## Extract MOD11A2 LST bands to GeoTiff
## tom.hengl@gmail.com

#library(gdalUtils)
#setwd("/mnt/DATA/MODIStiled/MOD11A2")
load(".RData")
library(rgdal)
library(utils)
library(snowfall)
library(raster)
library(RSAGA)
modis.prj <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs"

## download all HDF files ----
y.span = 2000:2020
for(i in y.span){
  system(paste0('wget -e robots=off -m -np -R .html,.tmp -nH --accept \"*.hdf\" --cut-dirs=4 "https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MOD11A2/', i , '/" --header "Authorization: Bearer xxx" -P "/mnt/DATA/MODIS/6/MOD11A2/"'))
}

## list per year ----
hdf.lst <- list.files(path="/mnt/DATA/MODIS/6/MOD11A2", pattern=glob2rx("*.hdf$"), full.names=TRUE, recursive=TRUE)
str(hdfy.lst)
## 303,877 tiles
length(hdf.lst)/14582
#system(paste('gdalinfo', hdf.lst[1]))
hdfy.lst <- data.frame(matrix(unlist(lapply(hdf.lst, strsplit, "/")), ncol=9, byrow=TRUE))
hdfy.lst <- hdfy.lst[,-c(1:6)]
names(hdfy.lst) <- c("Year", "Day", "FileName")
head(hdfy.lst)
hdfy.lst$YearDay <- as.factor(paste(hdfy.lst$Year, hdfy.lst$Day, sep="_"))
hdfy.lst <- hdfy.lst[hdfy.lst$Year %in% y.span,]
lvs <- levels(as.factor(paste(hdfy.lst$YearDay)))
length(lvs)
## 959
save.image()

## Daytime LST ----
for(i in length(lvs):1){
  sel <- hdfy.lst$YearDay==lvs[i]
  out.n <- paste0("/mnt/DATA/MODIStiled/MOD11A2/tiledD/", sapply(paste(hdfy.lst[sel,"FileName"]), function(x){strsplit(x, ".hdf")[[1]][1]}), ".tif")
  hddir <- paste0("/mnt/DATA/MODIS/6/MOD11A2/", hdfy.lst$Year[sel], "/", hdfy.lst$Day[sel], "/")
  tmp0.lst <- paste0('HDF4_EOS:EOS_GRID:\"', hddir, hdfy.lst[sel,"FileName"], '\":MODIS_Grid_8Day_1km_LST:\"LST_Day_1km\"') 
  sfInit(parallel=TRUE, cpus=16)
  sfExport("tmp0.lst", "out.n")
  t <- sfLapply(1:length(tmp0.lst), function(j){ if(!file.exists(out.n[j])){ try( system(paste('gdal_translate ', tmp0.lst[j], out.n[j], ' -a_nodata \"0\" -ot \"Int16\" -co \"COMPRESS=DEFLATE\" -q'), intern = FALSE) ) }})
  sfStop()
}

## Nightime LST ----
for(i in length(lvs):1){
  sel <- hdfy.lst$YearDay==lvs[i]
  out.n <- paste0("/mnt/DATA/MODIStiled/MOD11A2/tiledN/", sapply(paste(hdfy.lst[sel,"FileName"]), function(x){strsplit(x, ".hdf")[[1]][1]}), ".tif")
  hddir <- paste0("/mnt/DATA/MODIS/6/MOD11A2/", hdfy.lst$Year[sel], "/", hdfy.lst$Day[sel], "/")
  tmp0.lst <- paste0('HDF4_EOS:EOS_GRID:\"', hddir, hdfy.lst[sel,"FileName"], '\":MODIS_Grid_8Day_1km_LST:\"LST_Night_1km\"') 
  sfInit(parallel=TRUE, cpus=16)
  sfExport("tmp0.lst", "out.n")
  t <- sfLapply(1:length(tmp0.lst), function(j){ if(!file.exists(out.n[j])){ try( system(paste('gdal_translate ', tmp0.lst[j], out.n[j], ' -a_nodata \"0\" -ot \"Int16\" -co \"COMPRESS=DEFLATE\" -q'), intern = FALSE) ) }})
  sfStop()
}
# ERROR 4: HDF4_EOS:EOS_GRID:/mnt/DATA/MODIS/6/MOD11A2/2018/209/MOD11A2.A2018209.h19v07.006.2018330170435.hdf:MODIS_Grid_8Day_1km_LST:LST_Night_1km: No such file or directory

## Output is 2 x 230GB
## Make mosaics ----
#r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
r = raster("/mnt/DATA/MODIS_work/MOD11A2/MOD11A2_LST_Night_2017_081_ll_1km.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
load(file="modis_grid.rda")
str(modis_grid$TILE)
## only 317 cover land
modis_grid$TILEh <- paste0(ifelse(nchar(modis_grid$h)==1, paste0("h0", modis_grid$h), paste0("h", modis_grid$h)), ifelse(nchar(modis_grid$v)==1, paste0("v0", modis_grid$v), paste0("v", modis_grid$v)))
## 8-day period
#load("dirs.rda")
days <- as.numeric(format(seq(ISOdate(2015,1,1), ISOdate(2015,12,31), by="month"), "%j"))-1
m.lst <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
dsel <- cut(as.numeric(dirs), breaks=c(days,365), labels = m.lst)

mosaic_MODIS <- function(i, name, out.dir, in.dir, te){
  out.tif = paste0(out.dir, "/", name, "_", i, "_ll_1km.tif")
  if(!file.exists(out.tif)){
    lstD <- list.files(path=in.dir, pattern=glob2rx(paste0("MOD11A2.A", gsub("_", "", i), ".*.006.*.tif$")), full.names=TRUE) ## MOD11A2.A2000049.h01v07.006.2015058135045
    out.tmp <- tempfile(fileext = ".txt")
    vrt.tmp <- paste0("/mnt/DATA/MODIStiled/MOD11A2/vrts/", name, "_", i, ".vrt")
    cat(lstD, sep="\n", file=out.tmp)
    system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
    system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -tr ', 1/120, ' ', 1/120, ' -te ', paste(te, collapse = " "), ' -t_srs \"+proj=longlat +datum=WGS84\" -ot \"Int16\" -co \"COMPRESS=DEFLATE\"'))
  }
}

#mosaic_MODIS(i=lvs[length(lvs)], name="MOD11A2_LST_Day", out.dir="/mnt/DATA/MODIS_work/MOD11A2", in.dir = "/mnt/DATA/MODIStiled/MOD11A2/tiledD", te=te)
sfInit(parallel=TRUE, cpus=16)
sfExport("mosaic_MODIS", "lvs", "te")
t <- sfLapply(lvs, function(i){ mosaic_MODIS(i, name="MOD11A2_LST_Day", out.dir="/mnt/DATA/MODIS_work/MOD11A2", in.dir="/mnt/DATA/MODIStiled/MOD11A2/tiledD", te=te) })
sfStop()

sfInit(parallel=TRUE, cpus=16)
sfExport("mosaic_MODIS", "lvs", "te")
t <- sfLapply(lvs, function(i){ mosaic_MODIS(i, name="MOD11A2_LST_Night", out.dir="/mnt/DATA/MODIS_work/MOD11A2", in.dir="/mnt/DATA/MODIStiled/MOD11A2/tiledN", te=te) })
sfStop()

## NL 1km ----
nl1km = readGDAL("/data/NL1km/MODIS_353.grd")
#nl.prj = "+init=epsg:28992 +proj=sterea +lat_0=52.15616055555555 +lon_0=5.38763888888889 +k=0.9999079 +x_0=155000 +y_0=463000 +ellps=bessel +towgs84=565.4171,50.3319,465.5524,-0.398957388243134,0.343987817378283,-1.87740163998045,4.0725 +units=m +no_defs "
nl.prj = proj4string(nl1km)
te.nl = as.vector(nl1km@bbox)
vrt.lst = list.files("/mnt/DATA/MODIStiled/vrts", pattern = ".vrt", full.names = TRUE)
## 1642
sfInit(parallel=TRUE, cpus=8)
sfExport("nl.prj", "vrt.lst", "te.nl")
t <- sfLapply(vrt.lst, function(i){ system(paste0('gdalwarp ', i, ' /data/NL1km/', gsub(".vrt", ".tif", basename(i)), ' -tr ', 1000, ' ', 1000, ' -te ', paste(te.nl, collapse = " "), ' -t_srs \"', nl.prj, '\" -ot \"Int16\" -co \"COMPRESS=DEFLATE\" -overwrite')) })
sfStop()
## compress to a single file:
tif.lst = list.files("/data/NL1km", pattern = ".tif", full.names = TRUE)
x = file.rename(tif.lst, gsub("MOD11A2_Day", "MOD11A2_LST_Day", tif.lst))
library(utils)
zip(zipfile = "/home/tomislav/Dropbox/HRclim/MOD11A2_LST_2000__2017_NL1km.zip", files = list.files("/data/NL1km", pattern = ".tif", full.names = TRUE))

## check mosaics:
#s = raster::stack(list.files("/data/MODIS_work/MOD11A2", pattern=glob2rx("*.tif$"), full.names = TRUE))
t = list.files("/data/MODIS_work/MOD11A2", pattern=glob2rx("*.tif$"), full.names = TRUE)
mn.t = data.frame(x1=sort(basename(t)[grep("_Day_", basename(t))]), x2=sort(basename(t)[grep("_Night_", basename(t))]), stringsAsFactors = FALSE)

## tiling system ----
obj <- GDALinfo("/data/MODIS_work/MOD11A2/MOD11A2_LST_Day_2007_161_ll_1km.tif")
obj2 = GDALinfo("/data/OpenLandData/layers1km/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2015-v2.0.7_1km_ll.tif")
tile.lst <- GSIF::getSpatialTiles(obj, block.x=1, return.SpatialPolygons=TRUE)
tile.tbl <- GSIF::getSpatialTiles(obj, block.x=1, return.SpatialPolygons=FALSE)
tile.tbl$ID = as.character(1:nrow(tile.tbl))
str(tile.tbl)
tile.pol = SpatialPolygonsDataFrame(tile.lst, tile.tbl)
writeOGR(tile.pol, "/mnt/DATA/MODIStiled/tiles_ll_100km.shp", "tiles_ll_100km", "ESRI Shapefile")
#system(paste('gdal_translate /data/OpenLandData/layers1km/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2015-v2.0.7_1km_ll.tif /data/tmp/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2015-v2.0.7_1km_ll.sdat -of \"SAGA\" -ot \"Byte\"'))
system(paste0('saga_cmd -c=24 shapes_grid 2 -GRIDS=\"/data/tmp/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2015-v2.0.7_1km_ll.sgrd\" -POLYGONS=\"/mnt/DATA/MODIStiled/tiles_ll_100km.shp\" -PARALLELIZED=1 -RESULT=\"/mnt/DATA/MODIStiled/ov_ADMIN_tiles.shp\"'))
ov_ADMIN = readOGR("/mnt/DATA/MODIStiled/ov_ADMIN_tiles.shp", "ov_ADMIN_tiles")
summary(sel.t <- !ov_ADMIN@data[,"ESACCI.LC.L.5"]==210)
ov_ADMIN = ov_ADMIN[sel.t,]
new.dirs <- paste0("/data/tt/OpenLandData/modis/T", ov_ADMIN$ID)
x <- lapply(new.dirs, dir.create, recursive=TRUE, showWarnings=FALSE)
pr.dirs <- paste0("T", ov_ADMIN$ID)
## 18,929

## Lower, mean, upper and difference day-night ----
stack_MODIS_LST <- function(i, tile.tbl, tif.sel, var, out=c("Day_min","Day_max","Day_mean","DayNight_diff","Night_min","Night_max","Night_mean","Day_sd"), out.dir="/data/tt/OpenLandData/modis", type="Int16", mvFlag=-32767){
  out.tif = paste0(out.dir, "/", i,"/", var, "_",  out, "_", i, ".tif")
  require(data.table)
  require(rgdal)
  if(any(!file.exists(out.tif))){
    i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
    m = readGDAL(fname=tif.sel[1], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    for(j in 2:length(tif.sel)){
      m@data[,j] = readGDAL(fname=tif.sel[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    }
    names(m) = basename(tif.sel)
    mn = data.frame(x1=sort(names(m)[grep("_Day_", names(m))]), x2=sort(names(m)[grep("_Night_", names(m))]), stringsAsFactors = FALSE)
    ## Mean:
    m$D_mean = rowMeans(m@data[,mn$x1], na.rm = TRUE)
    writeGDAL(m["D_mean"], paste0(out.dir, "/", i,"/", var, "_",  out[3], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    m$N_mean = rowMeans(m@data[,mn$x2], na.rm = TRUE)
    writeGDAL(m["N_mean"], paste0(out.dir, "/", i,"/", var, "_",  out[7], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    ## SD:
    m$D_sd = transform(m@data[,mn$x1], SD=apply(m@data[,mn$x1], 1, sd, na.rm = TRUE))$SD
    writeGDAL(m["D_sd"], paste0(out.dir, "/", i,"/", var, "_",  out[8], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    ## mean difference between day time and night time temps:
    m$DN_diff = rowMeans(data.frame(lapply(1:nrow(mn), function(j){ m@data[,mn$x1[j]]-m@data[,mn$x2[j]] })), na.rm = TRUE)
    writeGDAL(m["DN_diff"], paste0(out.dir, "/", i,"/", var, "_",  out[4], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    ## Fastest way to derive stats is via the data.table package:
    v = data.table(m@data[,mn$x1])
    m@data[,c("D_min","D_max")] = t(v[, apply(v, 1, quantile, probs=c(.025,.975), na.rm=TRUE)])
    writeGDAL(m["D_min"], paste0(out.dir, "/", i,"/", var, "_",  out[1], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    writeGDAL(m["D_max"], paste0(out.dir, "/", i,"/", var, "_",  out[2], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    n = data.table(m@data[,mn$x2])
    m@data[,c("N_min","N_max")] = t(n[, apply(n, 1, quantile, probs=c(.025,.975), na.rm=TRUE)])
    writeGDAL(m["N_min"], paste0(out.dir, "/", i,"/", var, "_",  out[5], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    writeGDAL(m["N_max"], paste0(out.dir, "/", i,"/", var, "_",  out[6], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
  }
}

## test
#stack_MODIS_LST(i="T38715", tif.sel = as.vector(unlist(sapply(dirs[dsel=="Jan"], function(i){ list.files("/data/MODIS_work/MOD11A2", pattern=glob2rx(paste0("MOD11A2_LST_*_*_",i,"_ll_1km.tif$")), full.names = TRUE) }))), var="MOD11A2_LST_Jan", tile.tbl=tile.tbl)
library(snowfall)
for(k in 1:length(m.lst)){
  snowfall::sfInit(parallel=TRUE, cpus=24)
  snowfall::sfLibrary(rgdal)
  snowfall::sfLibrary(data.table)
  snowfall::sfExport("stack_MODIS_LST", "tile.tbl", "dirs", "dsel", "m.lst", "pr.dirs", "k")
  out <- snowfall::sfClusterApplyLB(pr.dirs, function(i){ stack_MODIS_LST(i, tif.sel = as.vector(unlist(sapply(dirs[dsel==m.lst[k]], function(i){ list.files("/data/MODIS_work/MOD11A2", pattern=glob2rx(paste0("MOD11A2_LST_*_*_",i,"_ll_1km.tif$")), full.names = TRUE) }))), var=paste0("MOD11A2_LST_", m.lst[k]), tile.tbl=tile.tbl) })
  snowfall::sfStop()
}

## Mosaick:
t.c = expand.grid(x=m.lst, y=c("Day_min","Day_max","Day_mean","DayNight_diff","Night_min","Night_max","Night_mean","Day_sd"))
t.c$z = as.vector(sapply(c("l.025","u.975","m","m","l.025","u.975","m","sd"), function(i){rep(i, times=length(m.lst))}))
t.c$f = tolower(sapply(t.c$y, function(i){strsplit(split = "_", paste(i))[[1]][1]}))
## 96 layers in total
tif.names = paste0("clm_lst_mod11a2.", tolower(t.c$x), ".", t.c$f, "_", t.c$z, "_1km_s0..0cm_2000..2017_v1.0.tif")


mosaic_ll_1km <- function(varn="MOD11A2_LST", i, out.tif, in.path="/data/tt/OpenLandData/modis", out.path="/data/LandGIS/layers1km", tr=1/120, te=paste(te, collapse = " "), ot="Int16", dstnodata=-32767){
  out.tif = paste0(out.path, "/", out.tif)
  if(!file.exists(out.tif)){
    tmp.lst <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_", i, "_T*.tif$")), full.names=TRUE, recursive=TRUE)
    out.tmp <- tempfile(fileext = ".txt")
    vrt.tmp <- tempfile(fileext = ".vrt")
    cat(tmp.lst, sep="\n", file=out.tmp)
    system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
    system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -ot \"', paste(ot), '\" -dstnodata \"',  paste(dstnodata), '\" -r \"near\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -wm 2000 -tr ', tr, ' ', tr, ' -te ', te))
    system(paste0('gdaladdo ', out.tif, ' 2 4 8 16 32 64 128'))
  }
}

library(snowfall)
sfInit(parallel=TRUE, cpus=24)
sfExport("t.c", "mosaic_ll_1km", "tif.names", "te")
out <- sfClusterApplyLB(1:nrow(t.c), function(j){ try( mosaic_ll_1km(varn="MOD11A2_LST", i=paste0(t.c$x[j], "_", t.c$y[j]), out.tif=tif.names[j], in.path="/data/tt/OpenLandData/modis", out.path="/data/LandGIS/layers1km", tr=1/120, te=paste(te, collapse = " "), ot="Int16", dstnodata=-32767) )})
sfStop()
save.image()

## Mean annual temperature and s.d. ----
library(raster)
meanf <- function(x){calc(x, mean, na.rm=TRUE)}
s <- raster::stack(paste0("/data/LandGIS/layers1km/clm_lst_mod11a2.",tolower(m.lst),".day_m_1km_s0..0cm_2000..2017_v1.0.tif"))
beginCluster()
r <- clusterR(s, fun=meanf, filename="/data/LandGIS/layers1km/clm_lst_mod11a2.annual.day_m_1km_s0..0cm_2000..2017_v1.0.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"), NAflag=-32767, overwrite=TRUE)
endCluster()
s2 <- raster::stack(paste0("/data/LandGIS/layers1km/clm_lst_mod11a2.",tolower(m.lst),".night_m_1km_s0..0cm_2000..2017_v1.0.tif"))
beginCluster()
r2 <- clusterR(s2, fun=meanf, filename="/data/LandGIS/layers1km/clm_lst_mod11a2.annual.night_m_1km_s0..0cm_2000..2017_v1.0.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"), NAflag=-32767, overwrite=TRUE)
endCluster()
s3 <- raster::stack(paste0("/data/LandGIS/layers1km/clm_lst_mod11a2.",tolower(m.lst),".day_sd_1km_s0..0cm_2000..2017_v1.0.tif"))
beginCluster()
r3 <- clusterR(s3, fun=meanf, filename="/data/LandGIS/layers1km/clm_lst_mod11a2.annual.day_sd_1km_s0..0cm_2000..2017_v1.0.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"), NAflag=-32767, overwrite=TRUE)
endCluster()
