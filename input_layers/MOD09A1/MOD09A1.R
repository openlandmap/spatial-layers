## Extract MOD09A1 7 surface reflectance bands to GeoTiff
## tom.hengl@gmail.com

#library(gdalUtils)
setwd("/data/MODIStiled/MOD09A1")
load(".RData")
library(rgdal)
library(utils)
library(snowfall)
library(raster)
library(RSAGA)
modis.prj <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs"

y.span = c(2001,2017)
# for(i in y.span){
#   dr.lst <- normalizePath(list.dirs(path=paste0("/mnt/nas/MODIS/6/MOD09A1/", i), recursive=FALSE))
#   for(j in 1:length(dr.lst)){
#     setwd(dr.lst[j])
#     x <- strsplit(dr.lst[j], "\\\\")[[1]][6]
#     system(paste0('wget --accept \"*.hdf\" -nd -N -r ftp://anonymous@ladsftp.nascom.nasa.gov/allData/5/MOD09A1/', i ,'/', x)) ## ?cut-dirs=4
#   }
# }

## list per year
hdf.lst <- list.files(path="/mnt/nas/MODIS/6/MOD09A1", pattern=glob2rx("*.hdf$"), full.names=TRUE, recursive=TRUE)
system(paste('gdalinfo', hdf.lst[1]))
hdfy.lst <- data.frame(matrix(unlist(lapply(hdf.lst, strsplit, "/")), ncol=9, byrow=TRUE))
hdfy.lst <- hdfy.lst[,-c(1:6)]
names(hdfy.lst) <- c("Year", "Day", "FileName")
hdfy.lst$YearDay <- as.factor(paste(hdfy.lst$Year, hdfy.lst$Day, sep="_"))
hdfy.lst <- hdfy.lst[hdfy.lst$Year %in% y.span,]
lvs <- levels(as.factor(paste(hdfy.lst$YearDay)))
## 91
str(hdfy.lst)
## 26,500 tiles
save.image()

## run per band:
for(j in 5:7){ ## 1:7
  for(i in 1:length(lvs)){
    sel <- hdfy.lst$YearDay==lvs[i]
    out.n <- paste0("/data/MODIStiled/b0", j, "/", sapply(paste(hdfy.lst[sel,"FileName"]), function(x){strsplit(x, ".hdf")[[1]][1]}), ".tif")
    hddir <- paste0("/mnt/nas/MODIS/6/MOD09A1/", hdfy.lst$Year[sel], "/", hdfy.lst$Day[sel], "/")
    tmp0.lst <- paste0('HDF4_EOS:EOS_GRID:\"', hddir, hdfy.lst[sel,"FileName"], '\":MOD_Grid_500m_Surface_Reflectance:\"sur_refl_b0', j,'\"') 
    sfInit(parallel=TRUE, cpus=8)
    sfExport("tmp0.lst", "out.n")
    t <- sfLapply(1:length(tmp0.lst), function(j){ if(!file.exists(out.n[j])){ try( system(paste('gdal_translate ', tmp0.lst[j], out.n[j], ' -a_nodata \"-32768\" -ot \"Int16\" -co \"COMPRESS=DEFLATE\" -q'), intern = FALSE) ) }})
    sfStop()
  }
}

## mosaic ----
r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
load(file="modis_grid.rda")
str(modis_grid$TILE)
## only 317 cover land
modis_grid$TILEh <- paste0(ifelse(nchar(modis_grid$h)==1, paste0("h0", modis_grid$h), paste0("h", modis_grid$h)), ifelse(nchar(modis_grid$v)==1, paste0("v0", modis_grid$v), paste0("v", modis_grid$v)))
## 8-day period
load("dirs.rda")
days <- as.numeric(format(seq(ISOdate(2015,1,1), ISOdate(2015,12,31), by="month"), "%j"))-1
m.lst <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
dsel <- cut(as.numeric(dirs), breaks=c(days,365), labels = m.lst)

mosaic_MODIS_bands <- function(i, name, out.dir, in.dir, te){
  out.tif = paste0(out.dir, "/", name, "_", i, "_ll_500m.tif")
  if(!file.exists(out.tif)){
    lstD <- list.files(path=in.dir, pattern=glob2rx(paste0("MOD09A1.A", gsub("_", "", i), ".*.006.*.tif$")), full.names=TRUE)
    out.tmp <- tempfile(fileext = ".txt")
    vrt.tmp <- paste0("/data/MODIStiled/vrts/", name, "_", i, ".vrt")
    cat(lstD, sep="\n", file=out.tmp)
    system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
    system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -tr ', 1/240, ' ', 1/240, ' -te ', paste(te, collapse = " "), ' -t_srs \"+proj=longlat +datum=WGS84\" -ot \"Int16\" -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\" -q'))
  }
}

#mosaic_MODIS_bands(i=lvs[20], name="MOD09A1_sur_refl_b01", out.dir="/mnt/nas/MODIS_work/MOD09A1", in.dir = "/data/MODIStiled/b01", te=te)
## run per band
for(j in c(1:2,5:7)){
  sfInit(parallel=TRUE, cpus=3)
  sfExport("mosaic_MODIS_bands", "lvs", "te", "j")
  t <- sfLapply(lvs, function(i){ mosaic_MODIS_bands(i, name=paste0("MOD09A1_sur_refl_b0", j), out.dir="/mnt/nas/MODIS_work/MOD09A1", te=te, in.dir=paste0("/data/MODIStiled/b0", j)) })
  sfStop()
  #t <- lapply(lvs, function(i){mosaic_MODIS_bands(i, name=paste0("MOD09A1_sur_refl_b0", j), out.dir="/mnt/nas/MODIS_work/MOD09A1", te=te, in.dir=paste0("/data/MODIStiled/b0", j)) })
}

## Reduce file size with Byte format:
for(j in c(1,6,7)){ ## c(1:2,5:7)
  b.tif = list.files('/mnt/nas/MODIS_work/MOD09A1', pattern=glob2rx(paste0('MOD09A1_sur_refl_b0',j,'_*_*_ll_500m.tif')), full.names = TRUE)
  sfInit(parallel=TRUE, cpus=3)
  sfExport("b.tif")
  t <- sfLapply(b.tif, function(i){ system(paste0('gdal_translate ', i, ' ', gsub("500m.tif", "500m_b.tif", i), ' -scale -100 16000 0 253 -ot \"Byte\" -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\"')) })
  sfStop()
  unlink(b.tif)
}

## 500 m grid ----
obj <- GDALinfo("/data/LandGIS/layers500m/lcv_landmask_esacci.lc.l4_c_500m_s0..0cm_2000..2015_v1.0.tif")
tile.lst <- GSIF::getSpatialTiles(obj, block.x=2, return.SpatialPolygons=TRUE)
tile.tbl <- GSIF::getSpatialTiles(obj, block.x=2, return.SpatialPolygons=FALSE)
tile.tbl$ID = as.character(1:nrow(tile.tbl))
str(tile.tbl)
tile.pol = SpatialPolygonsDataFrame(tile.lst, tile.tbl)
writeOGR(tile.pol, "/data/MODIStiled/MOD09A1/tiles_ll_200km_500m.shp", "tiles_ll_200km_500m", "ESRI Shapefile")
system(paste('gdal_translate /data/LandGIS/layers500m/lcv_landmask_esacci.lc.l4_c_500m_s0..0cm_2000..2015_v1.0.tif /data/tmp/lcv_landmask_esacci.lc.l4_c_500m_s0..0cm_2000..2015_v1.0.sdat -of \"SAGA\" -ot \"Byte\"'))
system(paste0('saga_cmd -c=24 shapes_grid 2 -GRIDS=\"/data/tmp/lcv_landmask_esacci.lc.l4_c_500m_s0..0cm_2000..2015_v1.0.sgrd\" -POLYGONS=\"/data/MODIStiled/MOD09A1/tiles_ll_200km_500m.shp\" -PARALLELIZED=1 -RESULT=\"/data/MODIStiled/MOD09A1/ov_ADMIN_tiles.shp\"'))
ov_ADMIN = readOGR("/data/MODIStiled/MOD09A1/ov_ADMIN_tiles.shp", "ov_ADMIN_tiles")
summary(sel.t <- !ov_ADMIN@data[,"lcv_landmas.5"]==2)
## 5378
ov_ADMIN = ov_ADMIN[sel.t,]
new.dirs <- paste0("/data/tt/OpenLandData/modis500m/T", ov_ADMIN$ID)
x <- lapply(new.dirs, dir.create, recursive=TRUE, showWarnings=FALSE)
pr.dirs <- paste0("T", ov_ADMIN$ID)

## Derive 2-month mean values and remove all missing values
stack_MODIS_refl <- function(i, tile.tbl, tif.sel, var, out, out.dir="/data/tt/OpenLandData/modis500m", type="Byte", mvFlag=255, t.val=950/((16000+100)/253), lc.tif="/data/LandGIS/layers500m/lcv_landmask_esacci.lc.l4_c_500m_s0..0cm_2000..2015_v1.0.tif"){
  out.tif = paste0(out.dir, "/", i,"/", var, "_",  out, "_", i, ".tif")
  require(rgdal)
  if(any(!file.exists(out.tif))){
    i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
    m = readGDAL(fname=tif.sel[1], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    for(j in 2:length(tif.sel)){
      m@data[,j] = readGDAL(fname=tif.sel[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    }
    names(m) = basename(tif.sel)
    ## northern latitudes and winter months can lead to problems and need to be manually fixed:
    mn = as.numeric(sapply(names(m), function(i){strsplit(i, "_")[[1]][6]}))
    m$lc = readGDAL(fname=lc.tif, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    m = as(m, "SpatialPixelsDataFrame")
    m = m[!m$lc==2,]
    if( (m@bbox[2,1]>61 & any(mn > 300 | mn < 40)) | (m@bbox[2,1]>72 & any(mn > 280 | mn < 50)) | (m@bbox[2,1]>81 & any(mn > 275 | mn < 70)) ){
      for(j in 1:length(tif.sel)){
        m@data[,j] = ifelse(m@data[,j]<t.val & (mn[j] >265 | mn[j] < 65), NA, m@data[,j])
      }
    }
    ## Mean:
    v = rowMeans(m@data[,1:length(tif.sel)], na.rm = TRUE)
    m$D_mean = round(ifelse(v < 0 | v > 253, NA, v))
    writeGDAL(m["D_mean"], paste0(out.dir, "/", i,"/", var, "_",  out, "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
  }
}
save.image()

#stack_MODIS_refl(i="T11271", tif.sel = as.vector(unlist(sapply(dirs[which(dsel %in% c("Oct","Nov"))], function(i){ list.files("/data/MODIS_work/MOD09A1", pattern=glob2rx(paste0("MOD09A1_sur_refl_b01_2001_",i,"_ll_500m.tif$")), full.names = TRUE) }))), var="MOD09A1_surf.refl_2001_b01", out="OctNov_M", tile.tbl=tile.tbl)
#stack_MODIS_refl(i="T12519", tif.sel = as.vector(unlist(sapply(dirs[which(dsel %in% c("Aug","Sep"))], function(i){ list.files("/data/MODIS_work/MOD09A1", pattern=glob2rx(paste0("MOD09A1_sur_refl_b01_2001_",i,"_ll_500m.tif$")), full.names = TRUE) }))), var="MOD09A1_surf.refl_2001_b01", out="AugSep_M", tile.tbl=tile.tbl)

## clean up:
#del.lst = list.files("/data/tt/OpenLandData/modis500m", pattern="AugSep", full.names = TRUE, recursive = TRUE)
#del.lst.t = sapply(basename(del.lst), function(i){ as.numeric(tools::file_path_sans_ext(strsplit(strsplit(basename(i), "_")[[1]][7], "T")[[1]][2])) })
#summary(del.lst.t>11160)
#unlink(del.lst[del.lst.t>11160])

mD.lst = list(c("Dec","Jan"), c("Feb","Mar"), c("Apr","May"), c("Jun","Jul"), c("Aug","Sep"), c("Oct","Nov"))
library(snowfall)
for(band in c(5,7,6)){ ## c(1,2,5,6,7)
  for(p in c(2001,2017)){
    for(k in 1:length(mD.lst)){
      snowfall::sfInit(parallel=TRUE, cpus=24)
      snowfall::sfLibrary(rgdal)
      snowfall::sfExport("stack_MODIS_refl", "tile.tbl", "dirs", "dsel", "mD.lst", "pr.dirs", "k", "p", "band")
      out <- snowfall::sfClusterApplyLB(pr.dirs, function(x){ stack_MODIS_refl(x, tif.sel = as.vector(unlist(sapply(dirs[which(dsel %in% mD.lst[[k]])], function(i){ list.files("/data/MODIS_work/MOD09A1", pattern=glob2rx(paste0("MOD09A1_sur_refl_b0", band, "_",p,"_",i,"_ll_500m_b.tif$")), full.names = TRUE) }))), var=paste0("MOD09A1_surf.refl_", p, "_b0", band), out=paste0(paste(mD.lst[[k]], collapse = ""), "_M"), tile.tbl=tile.tbl) })
      snowfall::sfStop()
    }
  }
}

## filter missing values ----
## important for PCA
filter_NA = function(i, tile.tbl, band, mD.lst, out.dir="/data/tt/OpenLandData/modis500m", type="Byte", mvFlag=255, lc.tif="/data/LandGIS/layers500m/lcv_landmask_esacci.lc.l4_c_500m_s0..0cm_2000..2015_v1.0.tif"){
  tile.lst = c(paste0(out.dir, "/", i, "/MOD09A1_surf.refl_2001_b0", band, "_", unlist(lapply(mD.lst, function(k){paste(k, collapse = "")})), "_M_", i, ".tif"), paste0(out.dir, "/", i, "/MOD09A1_surf.refl_2017_b0", band, "_", unlist(lapply(mD.lst, function(k){paste(k, collapse = "")})), "_M_", i, ".tif"))
  if(all(file.exists(tile.lst))){
    s1 = raster::stack(tile.lst)
    s1 = as(s1, "SpatialGridDataFrame")
    i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
    s1$lc = readGDAL(fname=lc.tif, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    for(j in 1:length(tile.lst)){
      j1 = ifelse(j==1, length(tile.lst), j-1)
      j2 = ifelse(j==length(tile.lst), 1, j+1)
      ch <- !s1$lc==2 & is.na(s1@data[,j])
      if(sum(ch)>0){
        ch.rep = rowMeans(s1@data[,c(j1,j2)], na.rm = TRUE)
        ch.med = quantile(ch.rep, probs=.5, na.rm=TRUE)
        s1@data[,j] <- round(ifelse(ch, ifelse(is.na(ch.rep), ch.med, ch.rep), s1@data[,j]))
        writeGDAL(s1[j], tile.lst[j], type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
      }
    }
  }
}

for(band in c(5,6,7)){
  snowfall::sfInit(parallel=TRUE, cpus=24)
  snowfall::sfLibrary(rgdal)
  snowfall::sfLibrary(raster)
  snowfall::sfExport("filter_NA", "tile.tbl", "dirs", "mD.lst", "band")
  out <- snowfall::sfClusterApplyLB(pr.dirs, function(x){ filter_NA(x, tile.tbl=tile.tbl, band=band, mD.lst=mD.lst) })
  snowfall::sfStop()
}

mosaic_ll_500m <- function(varn, i, out.tif, in.path="/data/tt/OpenLandData/modis500m", out.path="/data/MODIS_work/MOD09A1/layers500m", tr=1/240, te=paste(te, collapse = " "), ot="Byte", dstnodata=255){
  out.tif = paste0(out.path, "/", out.tif)
  if(!file.exists(out.tif)){
    tmp.lst <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_", i, "_T*.tif$")), full.names=TRUE, recursive=TRUE)
    ## MOD09A1_surf.refl_2017_b01_AprMay_M_T13040.tif
    out.tmp <- tempfile(fileext = ".txt")
    vrt.tmp <- tempfile(fileext = ".vrt")
    cat(tmp.lst, sep="\n", file=out.tmp)
    system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
    system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -ot \"', paste(ot), '\" -dstnodata \"',  paste(dstnodata), '\" -r \"near\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -wm 2000 -tr ', tr, ' ', tr, ' -te ', te))
    #system(paste0('gdaladdo ', out.tif, ' 2 4 8 16 32 64 128'))
  }
}

## global mosiacs (filtered) ----
for(band in c(5,6,7)){
  t.c = expand.grid(x=sapply(mD.lst, function(i){paste(i, collapse = "")}), y=c(2001,2017))
  ## 12 layers in total
  tif.names = paste0("lcv_surf.refl.b0", band, "_mod09a1.", tolower(t.c$x), "_m_500m_s0..0cm_", t.c$y, "_v1.0.tif")
  t.c$v = paste0("MOD09A1_surf.refl_", t.c$y, "_b0", band)
  library(snowfall)
  sfInit(parallel=TRUE, cpus=nrow(t.c))
  sfExport("t.c", "mosaic_ll_500m", "tif.names", "te")
  out <- sfClusterApplyLB(1:nrow(t.c), function(j){ try( mosaic_ll_500m(varn=t.c$v[j], i=paste0(t.c$x[j], "_M"), out.tif=tif.names[j], te=paste(te, collapse = " ")) )})
  sfStop()
  save.image()
}

## Principal component analysis:
saga_grid_pca = function(in.tif.lst, out.tif.lst, cleanup=TRUE){
  if(all(file.exists(in.tif.lst)) & any(!file.exists(out.tif.lst))){
    sgrd.lst = gsub(".tif", ".sgrd", in.tif.lst)
    message("Translating to SAGA GIS grids...")
    sfInit(parallel=TRUE, cpus=length(in.tif.lst))
    sfExport("in.tif.lst")
    out <- sfClusterApplyLB(1:length(in.tif.lst), function(i) { system(paste0('gdal_translate ', in.tif.lst[i], ' ', gsub(".tif", ".sdat", in.tif.lst[i]),' -of \"SAGA" -ot \"Byte\" -a_nodata \"255\"')) })
    sfStop()
    system(paste0('saga_cmd -c=24 statistics_grid 8 -GRIDS \"', paste(sgrd.lst, collapse=";"), '\" -PCA \"', paste(gsub(".tif", ".sgrd", out.tif.lst), collapse=";"), '\" -METHOD 1 -NFIRST ', length(out.tif.lst)))
    message("Generating GeoTiffs...")
    sfInit(parallel=TRUE, cpus=length(out.tif.lst))
    sfExport("in.tif.lst")
    out <- sfClusterApplyLB(1:length(out.tif.lst), function(i) { system(paste0('gdal_translate ', gsub(".tif", ".sdat", out.tif.lst[i]),' ', out.tif.lst[i], ' -co \"COMPRESS=DEFLATE\" -ot \"Int16\" -a_nodata \"-32768\"')) })
    sfStop()
    if(cleanup==TRUE){
      unlink(gsub(".tif", ".sdat", out.tif.lst)); unlink(gsub(".tif", ".prj", out.tif.lst)); unlink(gsub(".tif", ".sgrd", out.tif.lst)); unlink(gsub(".tif", ".sdat.aux.xml", out.tif.lst)); unlink(gsub(".tif", ".mgrd", out.tif.lst))
      unlink(gsub(".tif", ".sdat", in.tif.lst)); unlink(gsub(".tif", ".prj", in.tif.lst)); unlink(gsub(".tif", ".sgrd", in.tif.lst)); unlink(gsub(".tif", ".sdat.aux.xml", in.tif.lst)) 
    }
  }
}

## Conversion is fast but takes times till all images are loaded to memory (SAGA GIS)
for(band in c(2,5,6,7)){
  library(snowfall)
  library(rgdal)
  saga_grid_pca(in.tif.lst=list.files("/data/MODIS_work/MOD09A1/layers500m", pattern=glob2rx(paste0("lcv_surf.refl.b0", band, "_mod09a1.*_m_500m_s0..0cm_*_v1.0.tif$")), full.names = TRUE), out.tif.lst=paste0("/data/LandGIS/layers500m/lcv_surf.refl.b0", band, "_mod09a1.pc", 1:6, "_m_500m_s0..0cm_2001_v1.0.tif"))
}

## b01
# explained variance, explained cumulative variance, Eigenvalue
# 1.	79.13	79.13	4752996202139.265625
# 2.	12.55	91.68	753979888813.948242
# 3.	3.11	94.79	186766160019.850250
# 4.	1.26	96.06	75816678674.996887
# 5.	0.92	96.97	55082403542.108749
# 6.	0.70	97.67	42035332855.853127
# 7.	0.61	98.29	36830799353.827606
# 8.	0.49	98.78	29523276837.071468