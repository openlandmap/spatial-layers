## Global terrain classification using 280 m DEMs
## https://link.springer.com/article/10.1186/s40645-017-0157-2

setwd("/data/Landform")
load(".RData")
library(raster)
library(rgdal)
library(foreign)

landform.leg = read.csv("Landform_legend.csv")
r = raster("/data/GEOG/TAXOUSDA_250m_ll.tif")
tr = res(r)[1]

tile2raster = function(shp.file, tr=0.002083333, field="GROUP", landform.leg){
  out.tif = paste0('/data/Landform/tiled/', gsub(".shp", ".tif", basename(shp.file)))
  if(!file.exists(out.tif)){
    dbf.file = gsub(".shp", ".dbf", shp.file)
    db <- read.dbf(dbf.file)
    db$Value = plyr::join(db, landform.leg, by=field)$Value
    write.dbf(db, dbf.file)
    system(paste0('gdal_rasterize -a Value -tr ', tr,' ', tr, ' -co "COMPRESS=DEFLATE" -a_nodata 255 -ot \"Byte\" -l ', tools::file_path_sans_ext(basename(shp.file)), ' ', shp.file,' ', out.tif))
  }
}

shp.lst = list.files("/data/Landform", pattern=glob2rx("*.shp$"), full.names = TRUE, recursive = TRUE)
## test it:
#tile2raster(shp.file = shp.lst[5], landform.leg=landform.leg)
library(snowfall)
snowfall::sfInit(parallel=TRUE, cpus=22)
sfExport("tile2raster", "shp.lst", "landform.leg")
sfLibrary(foreign)
sfLibrary(tools)
sfLibrary(plyr)
x <- sfClusterApplyLB(shp.lst, function(i){ try( tile2raster(shp.file=i, landform.leg=landform.leg) ) })
sfStop()

dem.lst = list.files("/data/Landform/tiled", pattern=glob2rx("*.tif$"), full.names = TRUE, recursive = TRUE)
cat(dem.lst, sep="\n", file="landform_tiles.txt")
system('gdalbuildvrt -input_file_list landform_tiles.txt landform_250m.vrt')
system('gdalinfo landform_250m.vrt')
#system(paste0('gdalwarp landform_250m.vrt landform_dem_1km_v15_Feb_2018.tif -ot \"Int16\" -co \"BIGTIFF=YES\" -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -tr ', 1/120, ' ', 1/120))
system('gdalwarp landform_250m.vrt landform_dem_250m_v15_Feb_2018_i.tif -s_srs \"+proj=longlat +datum=WGS84\" -ot \"Byte\" -co \"BIGTIFF=YES\" -r \"near\" -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi -overwrite')
GDALinfo("landform_dem_250m_v15_Feb_2018_i.tif")

## fill in gaps / mising values using predominant value
## Install GRASS GIS and create a new mapset:
#grass -c /data/Landform/landform_dem_250m_v15_Feb_2018_i.tif -e /data/grassdata/landform --overwrite
## Start GRASS GIS:
#grass -text /data/grassdata/landform/PERMANENT
#r.external input=landform_dem_250m_v15_Feb_2018_i.tif output=landform_with_gaps --overwrite
## define output directory for files resulting from GRASS calculation:
#r.external.out directory=/data/Landform/ format="GTiff" options="COMPRESS=DEFLATE"
## perform GRASS calculation / stores the output map directly as GeoTIFF:
#r.fill.stats input=landform_with_gaps output=landform_dem_250m_v15_Feb_2018_f.tif dist=0.01 -m mode=mode -k --overwrite
## r.fill.stats complete. Processing time was 0h32m16s.
## cease GDAL output connection and turn back to write GRASS raster files:
#r.external.out -r
system(paste0("gdal_translate landform_dem_250m_v15_Feb_2018_f.tif landform_dem_250m_v15_Feb_2018.tif -ot \"Byte\" -a_nodata 255 -co \"COMPRESS=DEFLATE\""))
system('gdaladdo landform_dem_250m_v15_Feb_2018.tif 2 4 8 16 32 64 128')
## Add metadata ----
md.Fields = c("SERIES_NAME", "ATTRIBUTE_UNITS_OF_MEASURE", "CITATION_URL", "CITATION_ORIGINATOR",	"CITATION_ADDRESS",	"PUBLICATION_DATE", "PROJECT_URL", "DATA_LICENSE")
md.Values = c("Global terrain classification using 280 m DEMs", "meter", "https://doi.org/10.1186/s40645-017-0157-2", "Geospatial Information Authority of Japan, Geography and Crustal Dynamics Research Center, Ibaraki, Japan", "iwahashi-j96pz@mlit.go.jp", "5 January 2018", "http://www.gsi.go.jp/cais/geoinfo-index-e.html", "https://creativecommons.org/licenses/by/4.0/")
m = paste('-mo ', '\"', md.Fields, "=", md.Values, '\"', sep="", collapse = " ")
command = paste0('gdal_edit.py ', m,' landform_dem_250m_v15_Feb_2018.tif')
system (command, intern=TRUE)
system('gdalinfo landform_dem_250m_v15_Feb_2018.tif')

