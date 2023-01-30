## Donwscale SM2RAIN dataset using WorldClim / CHELSA Climate
## Tom.hengl@opengeohub.org

## derive mean precipitation per month ----
library(raster)
library(rgdal)
r = raster("/mnt/gaia/tmp/openlandmap/layers1km/lcv_landmask_esacci.lc.l4_c_1km_s0..0cm_2000..2015_v1.0.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
nrow(r)
ncol(r)
cellsize = res(r)[1]
p4s = proj4string(r)

## SAGA GIS function
## r.lst = rep("near", length(in.tif.lst)); d.lst=c(-32767, -32767, -32767); out.ot="Int16"; a_nodata=-32768; tr=1/120; te=te; p4s="+proj=longlat +datum=WGS84 +no_defs"
saga_prec_stats = function(in.tif.lst, out.tif.lst, cleanup=TRUE, r.lst, d.lst, tr, te, out.ot="Byte", a_nodata=255, NFIRST, tif.convert=TRUE, p4s, tmp.dir="./tmp/"){
  if(all(file.exists(in.tif.lst)) & any(!file.exists(out.tif.lst))){
    require(parallel)
    #sgrd.lst = paste0(tmp.dir, gsub(".tif", ".sgrd", basename(in.tif.lst)))
    message("Stacking rasters to the same grid...")
    if(missing(r.lst)){ r.lst = rep("near", length(in.tif.lst)) }
    if(missing(d.lst)){ d.lst = rep(a_nodata, length(in.tif.lst)) }
    if(missing(tr)){ tr = res(raster::raster(in.tif.lst[1]))[1] }
    if(missing(te)){ te = extent(raster::raster(in.tif.lst[1]))[c(1,3,2,4)] }
    if(missing(p4s)){ p4s = proj4string(raster::raster(in.tif.lst[1])) }
    in.wc = paste0(tmp.dir, gsub(".tif", ".sdat", basename(in.tif.lst[1])))
    system(paste0('gdalwarp ', in.tif.lst[1], ' ', in.wc, ' -multi -wo NUM_THREADS=ALL_CPUS -of \"SAGA" -t_srs \"', p4s, '\" -dstnodata \"', d.lst[1], '\" -co \"BIGTIFF=YES\" -ot \"Int16\" -wm 2000 -overwrite -r \"', r.lst[1], '\" -tr ', tr, ' ', tr, ' -te ', paste(te, collapse = " ")))
    out.chelsa = paste0(tmp.dir, gsub(".tif", ".sdat", basename(in.tif.lst[2])))
    system(paste0('gdalwarp ', in.tif.lst[2], ' ', out.chelsa, ' -multi -wo NUM_THREADS=ALL_CPUS -of \"SAGA" -t_srs \"', p4s, '\" -dstnodata \"', d.lst[2], '\" -co \"BIGTIFF=YES\" -ot \"Int16\" -wm 2000 -overwrite -r \"', r.lst[2], '\" -tr ', tr, ' ', tr, ' -te ', paste(te, collapse = " ")))
    out.sm2rain = paste0(tmp.dir, gsub(".tif", ".sdat", basename(in.tif.lst[3])))
    system(paste0('gdalwarp ', in.tif.lst[3], ' ', out.sm2rain, ' -multi -wo NUM_THREADS=ALL_CPUS -of \"SAGA" -t_srs \"', p4s, '\" -r \"', r.lst[3], '\" -tr ', 0.1, ' ', 0.1, ' -dstnodata \"', d.lst[3], '\" -co \"BIGTIFF=YES\" -ot \"Int16\" -wm 2000 -overwrite -te ', paste(te, collapse = " ")))
    ## Convert CHELSA rainfall to mm
    system(paste0('saga_cmd grid_calculus 1 -GRIDS \"', tmp.dir, gsub(".tif", ".sgrd", basename(in.tif.lst[2])), '\" -RESULT \"', tmp.dir, gsub(".tif", "_.sgrd", basename(in.tif.lst[2])), '\" -FORMULA \"g1/10\" -TYPE 4'))
    system(paste0('saga_cmd grid_calculus 1 -GRIDS \"', tmp.dir, gsub(".tif", ".sgrd", basename(in.tif.lst[3])), '\" -RESULT \"', tmp.dir, gsub(".tif", "_.sgrd", basename(in.tif.lst[3])), '\" -FORMULA \"g1/10\" -TYPE 4'))
    ## Expand grid for SM2RAIN
    system(paste0('saga_cmd grid_tools 28 -INPUT \"', gsub(".sdat", "_.sgrd", out.sm2rain), '\" -RESULT \"', gsub(".sdat", "_expand.sgrd", out.sm2rain), '\" -OPERATION 1 -CIRCLE 1 -EXPAND 2 -RADIUS 2'))
    ## Downscale SM2RAIN using Cubic spline
    system(paste0('saga_cmd grid_tools 0 -INPUT \"', gsub(".sdat", "_expand.sgrd", out.sm2rain), '\" -OUTPUT \"', gsub(".sdat", "_d.sgrd", out.sm2rain), '\" -SCALE_DOWN 4 -TARGET_DEFINITION 1 -TARGET_TEMPLATE \"', gsub(".sdat", ".sgrd", in.wc), '\"')) # -TARGET_USER_XMIN ', te[1]+tr/2, ' -TARGET_USER_XMAX ', te[3]-1.1*tr/2, ' -TARGET_USER_YMIN ', te[2]+tr/2, ' -TARGET_USER_YMAX ', te[4]-tr/2, ' -TARGET_USER_COLS ', ncol(r),' -TARGET_USER_ROWS ', nrow(r), ' -TARGET_USER_FITS 1 -TARGET_USER_SIZE ', tr))
    ## Mask downscaled grid
    system(paste0('saga_cmd grid_tools 24 -GRID \"', gsub(".sdat", "_d.sgrd", out.sm2rain), '\" -MASK \"', gsub(".sdat", ".sgrd", in.wc), '\" -MASKED \"', gsub(".sdat", "_masked.sgrd", out.sm2rain), '\"'))
    message("Deriving mean and stdev...")
    system(paste0('saga_cmd statistics_grid 4 -GRIDS \"', paste(c(gsub(".sdat", ".sgrd", in.wc), gsub(".sdat", "_.sgrd", out.chelsa), gsub(".sdat", "_masked.sgrd", out.sm2rain)), collapse=";"), '\" -MEAN \"', gsub(".tif", ".sgrd", out.tif.lst[1]), '\" -STDDEV \"', gsub(".tif", ".sgrd", out.tif.lst[2]), '\"'))
    if(tif.convert==TRUE){
      message("Generaring GeoTiffs...")
      x = parallel::mclapply(out.tif.lst, function(i) { system(paste0('gdal_translate ', gsub(".tif", ".sdat", i),' ', i, ' -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\" -of COG --config GDAL_CACHEMAX 9216 -co BLOCKSIZE=1024 -co NUM_THREADS=20 -co LEVEL=9 -ot \"', out.ot,'\" -a_nodata \"', a_nodata,'\"')) }, mc.cores=length(out.tif.lst))
    }
    if(cleanup==TRUE){
      unlink(gsub(".tif", ".sdat", out.tif.lst)); unlink(gsub(".tif", ".prj", out.tif.lst)); unlink(gsub(".tif", ".sgrd", out.tif.lst)); unlink(gsub(".tif", ".sdat.aux.xml", out.tif.lst)); unlink(gsub(".tif", ".mgrd", out.tif.lst))
      unlink(paste0(tmp.dir, gsub(".tif", ".sdat", basename(in.tif.lst)))); unlink(paste0(tmp.dir, gsub(".tif", ".prj", basename(in.tif.lst)))); unlink(paste0(tmp.dir, gsub(".tif", ".sgrd", basename(in.tif.lst)))); unlink(paste0(tmp.dir, gsub(".tif", ".sdat.aux.xml", basename(in.tif.lst)))) 
    }
  }
}

m.lst <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
dsel <- c(paste0("0", 1:9), "10", "11", "12") 
for(i in 1:12){
  in.tif.lst=c(paste0("/mnt/lacus/raw/WorldClim/wc2.1_30s_prec/wc2.1_30s_prec_", dsel[i], ".tif"), paste0("/mnt/gaia/raw/CHELSA/envicloud/chelsa/chelsa_v21/climatologies/1981-2010/pr/CHELSA_pr_", dsel[i], "_1981-2010_V.2.1.tif"), paste0("/mnt/tupi/SM2RAIN/clm_precipitation_sm2rain.sum_m_2007..2021_v1.5/clm_precipitation_sm2rain.sum.", tolower(m.lst[i]), "_m_10km_s0..0cm_2007..2021_v1.5.tif"))
  saga_prec_stats(in.tif.lst, out.tif.lst=c(paste0("mPREC_M_", m.lst[i], "_1km_ll.tif"), paste0("mPREC_sd_", m.lst[i], "_1km_ll.tif")), r.lst=c("near","near","near"), d.lst=c(-32767, -32767, -32767), out.ot="Int16", a_nodata=-32768, tr=1/120, te=te, p4s="+proj=longlat +datum=WGS84 +no_defs")
}

in.files = list.files(pattern=glob2rx("mPREC_*.tif"), full.names = TRUE)
out.files = paste0("./layers1km/", c(paste0("clm_precipitation_wc.v2.1.chelsa.v2.1.sm2rain.", sort(tolower(m.lst)), "_m_1km_s0..0cm_1980..2020_v0.3.tif"), 
             paste0("clm_precipitation_wc.v2.1.chelsa.v2.1.sm2rain.", sort(tolower(m.lst)), "_sd_1km_s0..0cm_1980..2020_v0.3.tif")))
data.frame(in.files, out.files)[20:22,]
file.copy(in.files, out.files)
