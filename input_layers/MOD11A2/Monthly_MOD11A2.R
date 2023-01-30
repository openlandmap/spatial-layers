## MODIS LST images 1km 
## tom.hengl@opengeohub.org

#library(terra)
library(rgdal)
library(matrixStats)
library(data.table)
library(parallel)
library(lubridate)
library(Rfast)

## input files ----
## 1km resolution 8-day images
tif.lst = list.files("/mnt/DATA/MODIS_work/MOD11A2", pattern=glob2rx("MOD11A2_LST_Day_*_*_ll_1km.tif$"), full.names = TRUE, recursive = TRUE)
#tif.lst = list.files("/mnt/DATA/MODIS_work/MOD11A2", pattern=glob2rx("MOD11A2_LST_Night_*_*_ll_1km.tif$"), full.names = TRUE, recursive = TRUE)
## 959
#s = raster::stack(tif.lst)
## 46 days * 21 year * 2
load("/mnt/DATA/MODIStiled/MOD11A2/dirs.rda")
tif.year = sapply(tif.lst, function(i){ strsplit(basename(i), "_")[[1]][4] })
tif.day = sapply(tif.lst, function(i){ strsplit(basename(i), "_")[[1]][5] })
tif.dates = as.Date(paste0(tif.year, tif.day), format="%Y%j")
## derive quantiles per month:
mn.l = seq.Date(as.Date("2000-02-01"), as.Date("2021-01-01"), by = "month")
## 252
tif.mn = cut.Date(tif.dates, breaks=mn.l, right=FALSE)
## list of files ----
write.csv(data.frame(tif.lst, tif.year, tif.day, tif.dates, tif.mn), "/mnt/DATA/MODIS_work/MOD11A2/LST_Day_filenames.csv")
g1km = readGDAL("/mnt/DATA/LandGIS/layers1km/clm_lst_mod11a2.annual.day_m_1km_s0..0cm_2000..2017_v1.0.tif")
sel.na = which(!is.na(g1km$band1))
#length(sel.na)
## 221,692,466
#saveRDS.gz(g1km, "g1km.rds")

## needs about 200GB or RAM to run
probs = c(0.05, 0.5, 0.95)
seq.r = list(seq.int(1L, 3*length(sel.na), 3L), seq.int(2L, 3*length(sel.na), 3L), seq.int(3L, 3*length(sel.na), 3L))

cl <- makeCluster(mc <- getOption("cl.cores", 80))
for(j in length(levels((tif.mn))):1){
  sel.no = which(tif.mn %in% paste(mn.l[j]))
  if(j==1){
    f.t = c(sel.no, sel.no[length(sel.no)]+1)
  } else {
    if(j==length(levels((tif.mn)))){
      f.t = c(sel.no[1]-1, sel.no)
    } else {
      f.t = c(sel.no[1]-1, sel.no, sel.no[length(sel.no)]+1)
    }
  }
  tif.sel = tif.lst[f.t]
  if(any(!file.exists(paste0("/data/MODIS_work/MOD11A2m/MOD11A2_Day_LST_q", probs, "_", paste(mn.l[j]), "_1km.tif")))){
    x = parallel::mclapply(1:length(tif.sel), function(j){ readGDAL(tif.sel[j], silent=TRUE)$band1[sel.na] }, mc.cores=length(tif.sel))
    v = data.table(data.frame(x))
    x = parRapply(cl, v, quantile, probs=probs, na.rm=TRUE)
    rm(v); gc()
    for(k in 1:length(probs)){
      tif.out = paste0("/data/MODIS_work/MOD11A2m/MOD11A2_Day_LST_q", probs[k], "_", paste(mn.l[j]), "_1km.tif")
      g1km@data[sel.na,"band1"] = x[seq.r[[k]]]
      writeGDAL(g1km["band1"], tif.out, type="Int16", mvFlag = -32768, options = c("COMPRESS=DEFLATE"))
    }
    rm(x); gc()
  }
}
stopCluster(cl)

## Annual mean and stdev ----
#cl <- makeCluster(mc <- getOption("cl.cores", 80))
for(k in probs){
  for(j in 2000:2020){
    #tifA.sel = list.files("/data/MODIS_work/MOD11A2m", pattern=glob2rx(paste0("MOD11A2_LST_q", k, "_", j, "-*-*_1km.tif")), full.names = TRUE)
    tifA.sel = list.files("/data/MODIS_work/MOD11A2m", pattern=glob2rx(paste0("MOD11A2_Day_LST_q", k, "_", j, "-*-*_1km.tif")), full.names = TRUE)
    if(any(!file.exists(paste0("/data/MODIS_work/MOD11A2m/MOD11A2_Daytime_LST_q", k, "_", c("mean", "std"), "_", j, "_1km.tif")))){
      x = parallel::mclapply(1:length(tifA.sel), function(i){ readGDAL(tifA.sel[i], silent=TRUE)$band1[sel.na] }, mc.cores=length(tifA.sel))
      v = data.table(data.frame(x))
      rm(x); gc()
      g1km@data[sel.na,"band1"] = rowMeans(v, na.rm=TRUE)
      tif.out = paste0("/data/MODIS_work/MOD11A2m/MOD11A2_Daytime_LST_q", k, "_", "mean_", j, "_1km.tif")
      writeGDAL(g1km["band1"], tif.out, type="Int16", mvFlag = -32768, options = c("COMPRESS=DEFLATE"))
      g1km@data[sel.na,"band1"] = matrixStats::rowSds(as.matrix(v), na.rm=TRUE)
      tif.out = paste0("/data/MODIS_work/MOD11A2m/MOD11A2_Daytime_LST_q", k, "_", "std_", j, "_1km.tif")
      writeGDAL(g1km["band1"], tif.out, type="Int16", mvFlag = -32768, options = c("COMPRESS=DEFLATE"))
      rm(v); gc()
    }
  }  
}
#stopCluster(cl)
#x.lst = list.files("/data/MODIS_work/MOD11A2m", pattern=glob2rx("MOD11A2_Day_LST_q*_*_*_1km.tif$"), full.names = TRUE)
#file.rename(x.lst, gsub("_Day_", "_Nighttime_", x.lst))

rm(g1km); rm(sel.na); rm(seq.r); gc()
save.image()

## Convert to COG ----
#tmp.tif = list.files("/data/MODIS_work/MOD11A2m", pattern=glob2rx("MOD11A2_Day_LST_q*_*-*-*_1km.tif$"), full.names = TRUE, recursive = TRUE)
tmp.tif = list.files("/data/MODIS_work/MOD11A2m", pattern=glob2rx("MOD11A2_LST_q*_*-*-*_1km.tif$"), full.names = TRUE, recursive = TRUE)
## 753
#tmp.dates = sapply(tmp.tif, function(i){ strsplit(basename(i), "_")[[1]][5] })
tmp.dates = sapply(tmp.tif, function(i){ strsplit(basename(i), "_")[[1]][4] })
date.begin = floor_date(ymd(tmp.dates), 'month')
date.end = ceiling_date(ymd(tmp.dates), 'month') %m-% days(1)
#q.lst = sapply(tmp.tif, function(i){ strsplit(basename(i), "_")[[1]][4] })
q.lst = sapply(tmp.tif, function(i){ strsplit(basename(i), "_")[[1]][3] })
qf.lst = ifelse(q.lst=="q0.05", "l0.05", ifelse(q.lst=="q0.95", "u0.95", "d")) 
write.csv(data.frame(tmp.dates, date.begin, date.end, qf.lst), "/mnt/DATA/MODIS_work/MOD11A2m/LST_Night_monthly_filenames.csv")
#x = parallel::mclapply(1:length(tmp.tif), function(i){out.tif <- paste0('/mnt/DATA/MODIS_work/MOD11A2m/clm_lst_mod11a2.daytime_', qf.lst[i], '_1km_s0..0cm_', gsub("-", ".", date.begin[i]), '..' , gsub("-", ".", date.end[i]), '_v1.1.tif'); if(!file.exists(out.tif)) system(paste0('gdal_translate --config GDAL_CACHEMAX 9216 -co BLOCKSIZE=1024 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co NUM_THREADS=8 -co LEVEL=9 -of COG ', tmp.tif[i], ' ', out.tif))}, mc.cores=8)
x = parallel::mclapply(1:length(tmp.tif), function(i){out.tif <- paste0('/mnt/DATA/MODIS_work/MOD11A2m/clm_lst_mod11a2.nighttime_', qf.lst[i], '_1km_s0..0cm_', gsub("-", ".", date.begin[i]), '..' , gsub("-", ".", date.end[i]), '_v1.1.tif'); if(!file.exists(out.tif)) system(paste0('gdal_translate --config GDAL_CACHEMAX 9216 -co BLOCKSIZE=1024 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co NUM_THREADS=8 -co LEVEL=9 -of COG ', tmp.tif[i], ' ', out.tif))}, mc.cores=8)

## annual averages
tmp.tif = list.files("/data/MODIS_work/MOD11A2m", pattern=glob2rx("MOD11A2_*time_LST_q*_*_*_1km.tif$"), full.names = TRUE, recursive = TRUE)
## 252
# 21*2*3*2
year.lst = sapply(tmp.tif, function(i){ strsplit(basename(i), "_")[[1]][6] })
day.lst = tolower(sapply(tmp.tif, function(i){ strsplit(basename(i), "_")[[1]][2] }))
q.lst = sapply(tmp.tif, function(i){ strsplit(basename(i), "_")[[1]][4] })
qf.lst = ifelse(q.lst=="q0.05", "l0.05", ifelse(q.lst=="q0.95", "u0.95", "d"))
typ.lst = sapply(tmp.tif, function(i){ strsplit(basename(i), "_")[[1]][5] })
typ.lst = ifelse(typ.lst=="mean", "m", "sd")
x = parallel::mclapply(1:length(tmp.tif), function(i){out.tif <- paste0('/mnt/DATA/MODIS_work/MOD11A2a/clm_lst_mod11a2.annual.', qf.lst[i], ".", day.lst[i], '_', typ.lst[i], '_1km_s0..0cm_', year.lst[i], '..', year.lst[i], '_v1.1.tif'); if(!file.exists(out.tif)) system(paste0('gdal_translate --config GDAL_CACHEMAX 9216 -co BLOCKSIZE=1024 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co NUM_THREADS=8 -co LEVEL=9 -of COG ', tmp.tif[i], ' ', out.tif))}, mc.cores=8)
## clean-up ----
#rm.lst = list.files("/mnt/DATA/MODIS_work/MOD11A2m", pattern=glob2rx("MOD11A2_*.tif$"), full.names = TRUE, recursive = TRUE)
#unlink(rm.lst)
#rm.lst = list.files("/mnt/DATA/MODIS_work/MOD11A2m", pattern=glob2rx("**_2000.02.01..*.tif$"), full.names = TRUE, recursive = TRUE)

## clip EU ----
tmp0.tif = list.files("/mnt/DATA/MODIS_work/MOD11A2a", pattern=glob2rx("*.tif$"), full.names = TRUE, recursive = TRUE)
## 1752
x = parallel::mclapply(tmp0.tif, function(i){system(paste0('gdalwarp ', i, ' /mnt/GeoHarmonizer/EU_LST/MOD11A2a/', gsub("_v1.1.tif", "_eumap_epsg3035_v1.1.tif", basename(i)), ' -co \"COMPRESS=DEFLATE\" -t_srs \"+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs\" -tr 1000 1000 -multi -wo \"NUM_THREADS=2\" -te 900000 900010 6540000 5460010'))}, mc.cores = 40)

## Add metadata ----
## Note - corrupts COG
out.tif = list.files("/mnt/DATA/MODIS_work/MOD11A2m", pattern=glob2rx("clm_lst_mod11a2.daytime_*.tif$"), full.names = TRUE, recursive = TRUE)
md.Fields = c("SERIES_NAME", "ATTRIBUTE_UNITS_OF_MEASURE", "CITATION_URL", "CITATION_ORIGINATOR", "CITATION_ORIGINATOR_URL", "CITATION_ADDRESS", "PUBLICATION_DATE", "PROJECT_URL", "DATA_LICENSE_URL")
md.Values = c("Land Surface Temperature monthly 0.05, 0.50 and 0.95 quantiles at 1-km spatial resolution", "0.02 x Kelvin", "https://gitlab.com/openlandmap/global-layers/", "NASA MODIS: Land Surface Temperature/Emissivity 8-Day L3 Global 1km (MOD11A2 Version 6)", "https://lpdaac.usgs.gov/products/mod11a2v006/", "tom.hengl@opengeohub.org", "January, 2021", "https://openlandmap.org", "https://creativecommons.org/licenses/by/4.0/")
m = paste('-mo ', '\"', md.Fields, "=", md.Values, '\"', sep="", collapse = " ")
#command = paste0('gdal_edit.py ', m,' ', out.tif[1])
#system(command, intern=TRUE)
#system(paste0('python validate_cloud_optimized_geotiff.py ', out.tif[1]))
