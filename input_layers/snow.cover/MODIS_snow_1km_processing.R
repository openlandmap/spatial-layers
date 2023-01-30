## Snow 1-km daily global; data source: https://climate.esa.int/en/odp/#/project/snow
## tom.hengl@opengeohub.org

library(rgdal)
library(raster)
library(matrixStats)
library(data.table)
library(parallel)
library(lubridate)
#library(Rfast)
source('land1km_functions.R')
## Server:
## OS: Ubuntu 18.04.5 LTS
## RAM: 376,6 GiB
## Processor: Intel® Xeon(R) Gold 6248 CPU @ 2.50GHz × 80

## land mask:
r1km = raster("/mnt/gaia/tmp/openlandmap/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif")
te = as.vector(extent(r1km))[c(1,3,2,4)]

## MODIS NC files obtained from: http://catalogue.ceda.ac.uk/uuid/3b3fd2daf3d34c1bb4a09efeaf3b8ea9
nc.lst = list.files("/mnt/lacus/raw/ESACCI_Snow/MODIS", glob2rx("*.nc$"), full.names = TRUE, recursive = TRUE)
## 7190
#GDALinfo(paste0(nc.lst[100], ':sfcg'))
x = parallel::mclapply(nc.lst, function(i){system(paste0('gdal_translate NETCDF:\"', i, '\":scfg ./MODIS/', gsub(".nc", ".tif", basename(i)), ' -ot \"Byte\" -co \"COMPRESS=DEFLATE\"'))}, mc.cores = 20)
#x = parallel::mclapply(tmp0.tif, function(i){system(paste0('gdalwarp \"', i, ':sfcg\" ./MODIS/', gsub(".nc", ".tif", basename(i)), ' -co \"COMPRESS=DEFLATE\" -t_srs \"EPSG:3035\" -tr 1000 1000 -multi -wo \"NUM_THREADS=2\" -te 900000 930010 6540000 5460010'))}, mc.cores = 40)

## Quantiles per month ----
tif.lst = list.files("./MODIS", glob2rx("*.tif$"), full.names = TRUE)
## 7190
#s = raster::stack(tif.lst)
tmp.date = substr(basename(tif.lst), 1, 8)
tif.year = as.numeric(substr(tmp.date, 1, 4))
summary(as.factor(tif.year))
tif.dates = as.Date(tmp.date, format="%Y%m%d")
mn.l = seq.Date(as.Date("2000-01-01"), as.Date("2020-01-01"), by = "month")
## 242
tif.mn = cut.Date(tif.dates, breaks=mn.l, right=FALSE)
#write.csv(data.frame(tif.lst, tif.year, tif.dates, tif.mn), "modis_monthly_files.csv")
## prepare land mask:
system('gdalwarp /mnt/gaia/tmp/openlandmap/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif -r \"near\" ./MODIS_MONTHLY/landmask.tif -tr 0.01 0.01 -te -180 -90 180 90 -co \"COMPRESS=DEFLATE\"')
system('gdalwarp /mnt/gaia/tmp/openlandmap/layers1km/dtm_elevation_glo90.copernicus_m_1km_s0..0cm_2019_epsg.4326_v1.0.tif -r \"average\" ./MODIS_MONTHLY/elevation.tif -tr 0.01 0.01 -te -180 -90 180 90 -co \"COMPRESS=DEFLATE\"')

## 1km global layer ----
g = readGDAL("./MODIS_MONTHLY/landmask.tif")
g$elev = readGDAL("./MODIS_MONTHLY/elevation.tif")$band1
g$pred = NA
## 18000 rows and 36000 columns
#summary(as.factor(g$band1))
##         1         2         3         4      NA's 
## 123844904 388162101  19100910   6624085 110268000 
sel.na = which(!(g$band1==2 | is.na(g$band1)))
str(sel.na)
## 149,569,899 pixels
saveRDS.gz(sel.na, "mask1km_grid.id.rds")
## Convert to pixels
g.xy = get.xy(g@grid)
dim(g.xy)
#g.xy = g.xy[sel.na,]
dim(g.xy)
doy = strftime(seq.Date(as.Date("2021-01-15"), as.Date("2022-01-14"), by="month"), format = "%j")
itr = plyrChunks(sel.na, n=round(length(sel.na)/80))
## run in parallel:
library(doMC)
for(j in doy){
  t.out = paste0("./MODIS_MONTHLY/t.min_", j, "_1km.tif")
  if(!file.exists(t.out)){
    registerDoMC()
    x = foreach(i=itr) %dopar% { temp.from.geom(fi=g.xy[i,2], day=as.numeric(j), a=30.419375, b=-15.539232, elev=g$elev[i]) }
    g$pred = NA
    g@data[sel.na,"pred"] = unlist(x)*10
    writeGDAL(g["pred"], t.out, type="Int16", mvFlag = -32768, options = c("COMPRESS=DEFLATE"))
    gc()
  }
}
for(j in doy){
  t.out = paste0("./MODIS_MONTHLY/t.max_", j, "_1km.tif")
  if(!file.exists(t.out)){
    registerDoMC()
    x = foreach(i=itr) %dopar% { temp.from.geom(fi=g.xy[i,2], day=as.numeric(j), a=37.03043, b=-15.43029, elev=g$elev[i]) }
    g$pred = NA
    g@data[sel.na,"pred"] = unlist(x)*10
    writeGDAL(g["pred"], t.out, type="Int16", mvFlag = -32768, options = c("COMPRESS=DEFLATE"))
    gc()
  }
}

## 1km probs ----
probs = c(0.05, 0.5, 0.95)
seq.r = list(seq.int(1L, 3*length(sel.na), 3L), seq.int(2L, 3*length(sel.na), 3L), seq.int(3L, 3*length(sel.na), 3L))
## Monthly MODIS values ----
cl <- makeCluster(mc <- getOption("cl.cores", 80))
for(j in length(levels((tif.mn))):1){
  sel.no = which(tif.mn %in% paste(mn.l[j]))
  tif.sel = tif.lst[sel.no]
  if(length(tif.sel)>10){
    out.tif = tif.out = paste0("./MODIS_MONTHLY/scfg.snow_q", probs, "_", gsub("-", "\\.", substr(paste(mn.l[j]), 1, 7)), "_1km.tif")
    if(any(!file.exists(out.tif))){
      x = parallel::mclapply(1:length(tif.sel), function(j){ readGDAL(tif.sel[j], silent=TRUE)$band1[sel.na] }, mc.cores=length(tif.sel))
      v = data.table(data.frame(x))
      ## https://stackoverflow.com/questions/38226323/replace-all-values-in-a-data-table-given-a-condition?rq=1
      ## remove all masked values etc 210 = Water; 215 = Glaciers, icecaps, ice sheets; 205 = Cloud
      for(col in names(v)) set(v, i=which(v[[col]]==215), j=col, value=100)
      ##v[v==215] = 100
      for(col in names(v)) set(v, i=which(v[[col]]>100), j=col, value=NA)
      ##v[v>100] = NA
      x = parRapply(cl, v, quantile, probs=probs, na.rm=TRUE)
      rm(v); gc()
      for(k in 1:length(probs)){
        tif.out = paste0("./MODIS_MONTHLY/scfg.snow_q", probs[k], "_", gsub("-", "\\.", substr(paste(mn.l[j]), 1, 7)), "_1km.tif")
        g@data[sel.na,"pred"] = x[seq.r[[k]]]
        writeGDAL(g["pred"], tif.out, type="Byte", mvFlag = 255, options = c("COMPRESS=DEFLATE"))
      }
      rm(x); gc(); gc()
    }
  }
}
stopCluster(cl)

## Gap-filling 1 km ----
## rule #1: use temporal neighbors
## rule #2: t.max < -6.0 degC = 100% snow
## rule #3: t.min > 4.5 degC = 0% snow
bM.lst = c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")
for(p in c(0.05, 0.5, 0.95)){
  for(j in 1:length(levels((tif.mn)))){
    mn.i = gsub("-", "\\.", substr(paste(mn.l[j]), 1, 7))
    tif.g = paste0("./MODIS_MONTHLY/scfg.snow_q", p, "_", mn.i, "_1km.tif")
    ## scfg.snow_q0.5_2018.08_1km.tif
    if(file.exists(tif.g)){
      tif.year = as.numeric(substr(paste(mn.l[j]), 1, 4))
      tif.bm = substr(paste(mn.l[j]), 6, 7)
      w.i = which(bM.lst %in% tif.bm)
      if(w.i==1){ 
        w.lst <- c(paste0(tif.year-1, "-12"), paste0(tif.year, "-02")) 
      } else {
        if(w.i==12){
          w.lst <- c(paste0(tif.year, "-11"), paste0(tif.year+1, "-01"))
        } else {
          w.lst <- c(paste0(tif.year, "-", bM.lst[w.i-1]), paste0(tif.year, "-", bM.lst[w.i+1]))
        }
      }
      mn.f =  c(paste0(c(tif.year-1, tif.year+1), "-", tif.bm), w.lst)
      tif.f = c(paste0("./MODIS_MONTHLY/scfg.snow_q", p, "_", gsub("-", "\\.", mn.f), "_1km.tif"), paste0("./MODIS_MONTHLY/t.", c("min", "max"), "_", doy[as.numeric(tif.bm)], "_1km.tif"))
      ## t.max_288_1km.tif
      tifF.out = paste0("./MODIS_MONTHLY_GF/scfg.snow_q", p, "_", gsub("-", "\\.", substr(paste(mn.l[j]), 1, 7)), "_1km_gf.tif")
      if(!file.exists(tifF.out)){
        g = readGDAL(tif.g)
        na.gf = which(is.na(g$band1[sel.na]))
        if(length(na.gf)>0){
          x = parallel::mclapply(1:length(tif.f), function(j){ try( readGDAL(tif.f[j], silent=TRUE)$band1[sel.na][na.gf] ) }, mc.cores=length(tif.f))
          ## 50GB RAM
          na.tif = !sapply(x, is.integer)
          if(sum(na.tif)>0){
            for(k in which(na.tif)){ x[[k]] <- rep(NA, length(na.gf)) }
          }
          x = data.frame(x)
          names(x) = basename(tif.f)
          ## rule #1: use temporal neighbors
          v = rowMeans(x[,1:4], na.rm=TRUE)
          ## rule #2: t.max < -6.0 degC = 100% snow
          ## rule #3: t.min > 4.5 degC = 0% snow
          if(p == 0.05){ t.min <- -80; t.max <- 20 }
          if(p == 0.5){ t.min <- -45; t.max <- 45 }
          if(p == 0.95){ t.min <- -20; t.max <- 80 }
          v = ifelse(is.na(v) & x[,6]<t.min, 100, ifelse(is.na(v) & x[,5]>t.max, 0, v))
          g@data[sel.na[na.gf],"band1"] = v
          writeGDAL(g["band1"], tifF.out, type="Byte", mvFlag = 255, options = c("COMPRESS=DEFLATE"))
        } else {
          file.copy(tif.g, tifF.out)
        }
      }
    }
  } 
}

## Convert to COG ----
months.lst = c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
#in.tifs = list.files("./MODIS_MONTHLY_GF", glob2rx("*.tif$"), full.names = TRUE)
in.t = list.files("./MODIS_MONTHLY", glob2rx("t.*_*_1km.tif$"), full.names = TRUE)
out.df = expand.grid(probs, levels((tif.mn)))
out.df$in.filename = paste0("./MODIS_MONTHLY_GF/scfg.snow_q", out.df$Var1, "_", substr(gsub("-", "\\.", out.df$Var2), 1, 7), "_1km_gf.tif")
out.df$out.filename = paste0("./MODIS_MONTHLY_COG/clm_snow.cover_esa.modis_p", substr(out.df$Var1, 3, 4), "_1km_s0..0cm_", substr(gsub("-", "\\.", out.df$Var2), 1, 7), "_epsg4326_v1.tif")
out.df = out.df[-as.vector(sapply(c("2000.01", "2000.02"), grep, out.df$in.filename)),]
t.lst = c(paste0("./MODIS_MONTHLY_COG/dtm_temp.max_geom.", months.lst, "_m_1km_s0..0cm_xxxx_epsg4326_v1.tif"),
          paste0("./MODIS_MONTHLY_COG/dtm_temp.min_geom.", months.lst, "_m_1km_s0..0cm_xxxx_epsg4326_v1.tif"))
in.tifs = c(out.df$in.filename, in.t)
out.tifs = c(out.df$out.filename, t.lst)
#View(data.frame(in.tifs, out.tifs))
x = parallel::mclapply(1:length(in.tifs), function(i){system(paste0('gdalwarp ', in.tifs[i], ' ', out.tifs[i], ' --config GDAL_CACHEMAX 9216 -co BLOCKSIZE=1024 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co NUM_THREADS=2 -co LEVEL=9 -of COG -r \"cubicspline\" -ot \"Byte\" -dstnodata 255 -te -180.00000 -61.99667 180.00000 87.37000 -tr 0.008333333 0.008333333'))}, mc.cores=40)

## 5-km resolution ----
## world 1980-2020
## http://catalogue.ceda.ac.uk/uuid/5484dc1392bc43c1ace73ba38a22ac56
nc5.lst = list.files("/mnt/lacus/raw/ESACCI_Snow/AVHRR_MERGED", glob2rx("*.nc$"), full.names = TRUE, recursive = TRUE)
## 13769
#GDALinfo(paste0(nc.lst[100], ':sfcg'))
x = parallel::mclapply(nc5.lst, function(i){system(paste0('gdal_translate NETCDF:\"', i, '\":scfg ./AVHRR_MERGED/', gsub(".nc", ".tif", basename(i)), ' -ot \"Byte\" -co \"COMPRESS=DEFLATE\"'))}, mc.cores = 40)

## Derive quantiles bimonthly ----
tif.lst = list.files("./AVHRR_MERGED", pattern=glob2rx("*.tif$"), full.names = TRUE)
## 13769
s = raster::stack(tif.lst)
## 365 days * 40 year
tmp.date = sapply(tif.lst, function(i){ strsplit(basename(i), "-")[[1]][1] })
tif.year = as.numeric(substr(tmp.date, 1, 4))
tif.dates = as.Date(tmp.date, format="%Y%m%d")
## derive quantiles per month:
mn.l = seq.Date(as.Date("1982-01-01"), as.Date("2020-03-01"), by = "2 month")
## 230
tif.mn = cut.Date(tif.dates, breaks=mn.l, right=FALSE)
write.csv(data.frame(tif.lst, tif.year, tif.dates, tif.mn), "avhrr_monthly_files.csv")
probs = c(0.1, 0.5, 0.9)
g = readGDAL(tif.lst[100])
seq.r = list(seq.int(1L, 3*length(g), 3L), seq.int(2L, 3*length(g), 3L), seq.int(3L, 3*length(g), 3L))

## Bimonthly AVHRR ----
cl <- makeCluster(mc <- getOption("cl.cores", 80))
for(j in 1:length(levels((tif.mn)))){
  sel.no = which(tif.mn %in% paste(mn.l[j]))
  tif.sel = tif.lst[sel.no]
  if(length(tif.sel)>1){
    out.tif = paste0("./AVHRR_BIMONTHLY/snow_q", probs, "_", gsub("-", "\\.", substr(paste(mn.l[j]), 1, 7)), "_5km.tif")
    if(any(!file.exists(out.tif))){
      x = parallel::mclapply(1:length(tif.sel), function(j){ readGDAL(tif.sel[j], silent=TRUE)$band1 }, mc.cores=length(tif.sel))
      v = data.table(data.frame(x))
      ## https://stackoverflow.com/questions/38226323/replace-all-values-in-a-data-table-given-a-condition?rq=1
      ## remove all masked values etc 210 = Water; 215 = Glaciers, icecaps, ice sheets; 205 = Cloud
      for(col in names(v)) set(v, i=which(v[[col]]==215), j=col, value=100)
      ##v[v==215] = 100
      for(col in names(v)) set(v, i=which(v[[col]]>100), j=col, value=NA)
      ##v[v>100] = NA
      x = parRapply(cl, v, quantile, probs=probs, na.rm=TRUE)
      rm(v); gc()
      for(k in 1:length(probs)){
        tif.out = paste0("./AVHRR_BIMONTHLY/snow_q", probs[k], "_", gsub("-", "\\.", substr(paste(mn.l[j]), 1, 7)), "_5km.tif")
        g$band1 = x[seq.r[[k]]]
        writeGDAL(g["band1"], tif.out, type="Byte", mvFlag = 255, options = c("COMPRESS=DEFLATE"))
      }
      rm(x); gc()
    }
  }
}
stopCluster(cl)

## Gap-filling ----
## Filter missing values / focus on the 90% snow as this is usually most important
g.tif = list.files("./AVHRR_BIMONTHLY", pattern=glob2rx("snow_q0.9_*_5km.tif$"), full.names = TRUE)
## some dates missing
gt.tif = paste0("./AVHRR_BIMONTHLY/snow_q0.9_", gsub("-", "\\.", substr(paste(mn.l), 1, 7)), "_5km.tif")
x = gt.tif[which(!gt.tif %in% g.tif)]
## snow_q0.9_1994.11_5km.tif
for(p in probs){
  g = readGDAL(paste0("./AVHRR_BIMONTHLY/snow_q", p, "_1994.09_5km.tif"))
  g$band2 = readGDAL(paste0("./AVHRR_BIMONTHLY/snow_q", p, "_1995.01_5km.tif"))$band1
  g$avg = rowMeans(g@data, na.rm=TRUE)
  writeGDAL(g["avg"], paste0("./AVHRR_BIMONTHLY/snow_q", p, "_1994.11_5km.tif"), type="Byte", mvFlag = 255, options = c("COMPRESS=DEFLATE"))
}
## Try to gap-fill ALL missing values using temporal neighbours
bm.lst = c("01", "03", "05", "07", "09", "11")
w.tifs = c(1, 1, 0.2, 0.2, 0.5, 0.5)

cl <- makeCluster(mc <- getOption("cl.cores", 80))
for(p in c(0.1, 0.9)){
  for(j in 1:length(levels((tif.mn)))){
    mn.i = gsub("-", "\\.", substr(paste(mn.l[j]), 1, 7))
    tif.g = paste0("./AVHRR_BIMONTHLY/snow_q", p, "_", mn.i, "_5km.tif")
    tif.year = as.numeric(substr(paste(mn.l[j]), 1, 4))
    tif.bm = substr(paste(mn.l[j]), 6, 7)
    w.i = which(bm.lst %in% tif.bm)
    if(w.i==1){ 
      w.lst <- c(paste0(tif.year-1, "-11"), paste0(tif.year, "-03")) 
    } else {
      if(w.i==6){
        w.lst <- c(paste0(tif.year, "-09"), paste0(tif.year+1, "-01"))
      } else {
        w.lst <- c(paste0(tif.year, "-", bm.lst[w.i-1]), paste0(tif.year, "-", bm.lst[w.i+1]))
      }
    }
    mn.f =  c(paste0(c(tif.year-1, tif.year+1, tif.year-2, tif.year+2), "-", tif.bm), w.lst)
    tif.f = paste0("./AVHRR_BIMONTHLY/snow_q", p, "_", gsub("-", "\\.", mn.f), "_5km.tif")
    tifF.out = paste0("./AVHRR_BIMONTHLY_GF/snow_q", p, "_", gsub("-", "\\.", substr(paste(mn.l[j]), 1, 7)), "_5km_gf.tif")
    if(!file.exists(tifF.out) & file.exists(tif.g)){
      g = readGDAL(tif.g)
      x = parallel::mclapply(1:length(tif.f), function(j){ try( readGDAL(tif.f[j], silent=TRUE)$band1 ) }, mc.cores=length(tif.f))
      na.tif = !sapply(x, is.integer)
      if(sum(na.tif)>0){
        for(k in which(na.tif)){ x[[k]] <- rep(NA, length(g)) }
      }
      x = data.frame(x)
      ## https://stackoverflow.com/questions/9864631/weighted-mean-by-row
      v = parRapply(cl, x, weighted.mean, w=w.tifs, na.rm=TRUE)
      g$avg = ifelse(is.na(g$band1), v, g$band1)
      writeGDAL(g["avg"], tifF.out, type="Byte", mvFlag = 255, options = c("COMPRESS=DEFLATE"))
    }
  } 
}
stopCluster(cl)
