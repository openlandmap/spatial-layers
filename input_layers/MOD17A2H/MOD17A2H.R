## Extract MOD17A2H GPP bands to GeoTiff
## https://lpdaac.usgs.gov/dataset_discovery/modis/modis_products_table/mod17a2h_v006
## tom.hengl@gmail.com

#library(gdalUtils)
setwd("/data/MODIStiled/MOD17A2H")
load(".RData")
library(rgdal)
library(utils)
library(snowfall)
library(raster)
library(RSAGA)
modis.prj <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs"

## download all HDF files ----
y.span = 2000:2018
# for(i in y.span){
#   dr.lst <- normalizePath(list.dirs(path=paste0("/data/MODIS/6/MOD17A2H/", i), recursive=FALSE))
#   for(j in 1:length(dr.lst)){
#     setwd(dr.lst[j])
#     x <- strsplit(dr.lst[j], "\\\\")[[1]][6]
#     system(paste0('wget --accept \"*.hdf\" -nd -N -r ftp://anonymous@ladsftp.nascom.nasa.gov/allData/6/MOD17A2H/', i ,'/', x)) ## ?cut-dirs=4
#   }
# }

## list per year ----
hdf.lst <- list.files(path="/data/MODIS/6/MOD17A2H", pattern=glob2rx("*.hdf$"), full.names=TRUE, recursive=TRUE)
system(paste('gdalinfo', hdf.lst[1]))
hdfy.lst <- data.frame(matrix(unlist(lapply(hdf.lst, strsplit, "/")), ncol=9, byrow=TRUE))
hdfy.lst <- hdfy.lst[,-c(1:6)]
names(hdfy.lst) <- c("Year", "Day", "FileName")
hdfy.lst$YearDay <- as.factor(paste(hdfy.lst$Year, hdfy.lst$Day, sep="_"))
hdfy.lst <- hdfy.lst[hdfy.lst$Year %in% y.span,]
lvs <- levels(as.factor(paste(hdfy.lst$YearDay)))
## 834
str(hdfy.lst)
## 240,354 tiles
save.image()

## Gpp_500m ----
## units kg C / m2
for(i in length(lvs):1){
  sel <- hdfy.lst$YearDay==lvs[i]
  out.n <- paste0("/data/MODIStiled/MOD17A2H/tiled/", sapply(paste(hdfy.lst[sel,"FileName"]), function(x){strsplit(x, ".hdf")[[1]][1]}), ".tif")
  hddir <- paste0("/data/MODIS/6/MOD17A2H/", hdfy.lst$Year[sel], "/", hdfy.lst$Day[sel], "/")
  tmp0.lst <- paste0('HDF4_EOS:EOS_GRID:\"', hddir, hdfy.lst[sel,"FileName"], '\":MOD_Grid_MOD17A2H:\"Gpp_500m\"') 
  sfInit(parallel=TRUE, cpus=8)
  sfExport("tmp0.lst", "out.n")
  t <- sfLapply(1:length(tmp0.lst), function(j){ if(!file.exists(out.n[j])){ try( system(paste('gdal_translate ', tmp0.lst[j], out.n[j], ' -a_nodata \"32767\" -ot \"Int16\" -co \"COMPRESS=DEFLATE\" -q'), intern = FALSE) ) }})
  sfStop()
}

## Output is 2 x 230GB
## Make mosaics ----
r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
load(file="/data/LandGIS/models/modis_grid.rda")
str(modis_grid$TILE)
## only 317 cover land
modis_grid$TILEh <- paste0(ifelse(nchar(modis_grid$h)==1, paste0("h0", modis_grid$h), paste0("h", modis_grid$h)), ifelse(nchar(modis_grid$v)==1, paste0("v0", modis_grid$v), paste0("v", modis_grid$v)))
## 8-day period
load("/data/LandGIS/models/dirs.rda")
days <- as.numeric(format(seq(ISOdate(2015,1,1), ISOdate(2015,12,31), by="month"), "%j"))-1
m.lst <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
dsel <- cut(as.numeric(dirs), breaks=c(days,365), labels = m.lst)
system('gdalinfo /data/MODIStiled/MOD17A2H/tiled/MOD17A2H.A2000065.h18v14.006.2015138174814.tif')
library(rgdal)
test = readGDAL('/data/MODIStiled/MOD17A2H/tiled/MOD17A2H.A2000065.h18v14.006.2015138174814.tif')
#spplot(test, at=c(0,0.1))

mosaic_MODIS <- function(i, name, out.dir, in.dir, te){
  out.tif = paste0(out.dir, "/", name, "_", i, "_ll_500m.tif")
  if(!file.exists(out.tif)){
    lstD <- list.files(path=in.dir, pattern=glob2rx(paste0("MOD17A2H.A", gsub("_", "", i), ".*.006.*.tif$")), full.names=TRUE) ## MOD17A2H.A2000065.h18v14.006.2015138174814.tif
    out.tmp <- tempfile(fileext = ".txt")
    vrt.tmp <- paste0("/data/MODIStiled/vrts/", name, "_", i, ".vrt")
    cat(lstD, sep="\n", file=out.tmp)
    system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
    system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -tr ', 1/240, ' ', 1/240, ' -te ', paste(te, collapse = " "), ' -r \"near\" -t_srs \"+proj=longlat +datum=WGS84\" -ot \"Int16\" -co \"COMPRESS=DEFLATE\"')) ## -srcnodata \"3.2766\"
  }
}

## TAKES 2 days to create all mosaics
#mosaic_MODIS(i=lvs[20], name="MOD17A2H_GPP", out.dir="/data/MODIS_work/MOD17A2H", in.dir="/data/MODIStiled/MOD17A2H/tiled", te=te)
library(snowfall)
sfInit(parallel=TRUE, cpus=6)
sfExport("mosaic_MODIS", "lvs", "te")
t <- sfLapply(lvs, function(i){ mosaic_MODIS(i, name="MOD17A2H_GPP", out.dir="/data/MODIS_work/MOD17A2H", in.dir="/data/MODIStiled/MOD17A2H/tiled", te=te) })
sfStop()

## tiling system 500m ----
obj <- GDALinfo("/data/LandGIS/layers500m/lcv_landmask_esacci.lc.l4_c_500m_s0..0cm_2000..2015_v1.0.tif")
tile.tbl <- GSIF::getSpatialTiles(obj, block.x=2, return.SpatialPolygons=FALSE)
tile.tbl$ID = as.character(1:nrow(tile.tbl))
ov_ADMIN = readOGR("/data/MODIStiled/MOD09A1/ov_ADMIN_tiles.shp", "ov_ADMIN_tiles")
summary(sel.t <- !ov_ADMIN@data[,"lcv_landmas.5"]==2)
## 5378
ov_ADMIN = ov_ADMIN[sel.t,]
new.dirs <- paste0("/data/tt/OpenLandData/modis500m/T", ov_ADMIN$ID)
x <- lapply(new.dirs, dir.create, recursive=TRUE, showWarnings=FALSE)
pr.dirs <- paste0("T", ov_ADMIN$ID)

## Generate long term-averages per month ----
library(snowfall)
#library(greenbrown)

tif.lst <- list.files("/data/MODIS_work/MOD17A2H", pattern=glob2rx("*.tif$"), full.names = TRUE)
## Test if all raster stack to the same grid:
t <- raster::stack(tif.lst)

for(k in 1:length(m.lst)){
  tif.sel = sort(as.vector(unlist(sapply(dirs[which(dsel %in% c(m.lst[k]))], function(i){ list.files("/data/MODIS_work/MOD17A2H", pattern=glob2rx(paste0("MOD17A2H_GPP_*_",i,"_ll_500m.tif$")), full.names = TRUE) }))))
  ## 4 images per month per 18 years = 72 images
  #stack_stats(i="T9638", tile.tbl=tile.tbl, tif.sel=tif.sel, var=paste0("GPP_", m.lst[k]), out=c("min","med","max"), probs=c(.025,.5,.975), out.dir="/data/tt/OpenLandData/modis500m", min=0, max=3000, trend.r=TRUE)
  snowfall::sfInit(parallel=TRUE, cpus=parallel::detectCores())
  sfExport("stack_stats", "tile.tbl", "m.lst", "tif.sel", "k", "pr.dirs")
  sfLibrary(rgdal)
  sfLibrary(data.table)
  x <- sfClusterApplyLB(pr.dirs, function(x){ try( stack_stats(i=x, tile.tbl=tile.tbl, tif.sel=tif.sel, var=paste0("GPP_", m.lst[k]), out=c("min","med","max"), probs=c(.025,.5,.975), out.dir="/data/tt/OpenLandData/modis500m", min=0, max=3000, trend.r=TRUE), silent = TRUE) })
  sfStop()
}

## Make mosaics ----
d.lst = expand.grid(m.lst, c("min","med","max", "diff", "Y2001", "Y2017"))
d.lst$n = ifelse(d.lst$Var2=="min", "l.025", ifelse(d.lst$Var2=="max", "u.975", "d"))
filename = paste0(ifelse(d.lst$Var2=="diff", "veg_gpp.diff_mod17a2h.", "veg_gpp_mod17a2h."), tolower(d.lst$Var1), "_", tolower(d.lst$n), ifelse(d.lst$Var2=="Y2001", "_500m_s0..0cm_2001..2001_v1.0.tif", ifelse(d.lst$Var2=="Y2017", "_500m_s0..0cm_2017..2017_v1.0.tif", "_500m_s0..0cm_2000..2018_v1.0.tif")))
#View(cbind(d.lst, filename))
r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]

mosaic_ll_500m <- function(varn, i, out.tif, in.path="/data/tt/OpenLandData/modis500m", out.path="/data/LandGIS/layers500m", tr, te, ot="Int16", dstnodata=-32767){
  out.tif = paste0(out.path, "/", out.tif)
  if(!file.exists(out.tif)){
    tmp.lst <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_", i, "_T*.tif$")), full.names=TRUE, recursive=TRUE)
    out.tmp <- tempfile(fileext = ".txt")
    vrt.tmp <- tempfile(fileext = ".vrt")
    cat(tmp.lst, sep="\n", file=out.tmp)
    system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
    system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -ot \"', paste(ot), '\" -dstnodata \"',  paste(dstnodata), '\" -r \"near\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -wm 2000 -tr ', tr, ' ', tr, ' -te ', te))
  }
}

library(snowfall)
sfInit(parallel=TRUE, cpus=36)
sfExport("d.lst", "mosaic_ll_500m", "filename", "te")
out <- sfClusterApplyLB(1:nrow(d.lst), function(x){ try( mosaic_ll_500m(varn="GPP", i=paste(d.lst$Var1[x], d.lst$Var2[x], sep="_"), out.tif=filename[x], tr=1/240, te=paste(te, collapse = " ")) )})
sfStop()
save.image()

## Mean GPP
meanf <- function(x){calc(x, mean, na.rm=TRUE)}
o.l = raster::stack(list.files("/data/LandGIS/layers500m", glob2rx("veg_gpp.diff_mod17a2h.*_d_500m_s0..0cm_2000..2018_v1.0.tif$"), full.names = TRUE))
o2.l = raster::stack(list.files("/data/LandGIS/layers500m", glob2rx("veg_gpp_mod17a2h.*_d_500m_s0..0cm_2000..2018_v1.0.tif$"), full.names = TRUE))
o3.l = raster::stack(list.files("/data/LandGIS/layers500m", glob2rx("veg_gpp_mod17a2h.*_d_500m_s0..0cm_2001..2001_v1.0.tif$"), full.names = TRUE))
o4.l = raster::stack(list.files("/data/LandGIS/layers500m", glob2rx("veg_gpp_mod17a2h.*_d_500m_s0..0cm_2017..2017_v1.0.tif$"), full.names = TRUE))

## run in parallel:
beginCluster()
r1 <- clusterR(o.l, fun=meanf, filename="/data/LandGIS/layers500m/veg_gpp.diff_mod17a2h.annual_d_500m_s0..0cm_2000..2018_v0.1.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"))
r2 <- clusterR(o2.l, fun=meanf, filename="/data/LandGIS/layers500m/veg_gpp_mod17a2h.annual_d_500m_s0..0cm_2000..2018_v0.1.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"))
r3 <- clusterR(o3.l, fun=meanf, filename="/data/LandGIS/layers500m/veg_gpp_mod17a2h.annual_d_500m_s0..0cm_2001..2001_v0.1.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"))
r4 <- clusterR(o4.l, fun=meanf, filename="/data/LandGIS/layers500m/veg_gpp_mod17a2h.annual_d_500m_s0..0cm_2017..2017_v0.1.tif", datatype="INT2S", options=c("COMPRESS=DEFLATE"))
endCluster()
