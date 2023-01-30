## Global Cropland map based on the GSFSAD30 https://lpdaac.usgs.gov/dataset_discovery/measures/measures_products_table
## tom.hengl@gmail.com

library(rgdal)
library(raster)
setwd("/data/GFSAD30")

## Make a mosaic:
tif.lst <- list.files(path="/data/GFSAD30", pattern=glob2rx("*.tif$"), full.names=TRUE, recursive=TRUE)
GDALinfo(tif.lst[30])
## 457 tiles
cat(tif.lst, sep="\n", file="GFSAD30_tiles.txt")
system('gdalbuildvrt -input_file_list GFSAD30_tiles.txt GFSAD30_30m.vrt')
system('gdalinfo GFSAD30_30m.vrt')
## Size is 1328814, 554412
## Pixel Size = (0.000269494585236,-0.000269494585236)
## TAKES FEW HOURS
system('gdal_translate GFSAD30_30m.vrt GFSAD30_croplands_30m_2013_01_01.tif -ot \"Byte\" -co \"COMPRESS=DEFLATE\" -r \"near\" -co \"BIGTIFF=YES\" -co \"NUM_THREADS=24\"')
#system('gdalwarp GFSAD30_30m.vrt GFSAD30_croplands_30m_2013_01_01.tif -co \"BIGTIFF=YES\" -srcnodata 0 -dstnodata 0 -r \"near\" -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi -ot \"Byte\" -wo \"NUM_THREADS=ALL_CPUS\" --config GDAL_CACHEMAX 2000')
system('gdaladdo GFSAD30_croplands_30m_2013_01_01.tif 2 4 8 16 32 64 128')
## Creating output file that is 1328814P x 554412L.
## 0	Water	Water bodies/no-data
## 1	Non-Cropland	Non-Cropland areas
## 2	Cropland	Cropland areas
system('gdalwarp GFSAD30_30m.vrt GFSAD30_croplands_100m_2013_01_01.tif -co \"BIGTIFF=YES\" -srcnodata 0 -dstnodata 0 -r \"near\" -tr 0.0008333333 0.0008333333 -wm 2000 -overwrite -co \"COMPRESS=DEFLATE\" -multi -ot \"Byte\" -wo \"NUM_THREADS=ALL_CPUS\" --config GDAL_CACHEMAX 2000'); system('gdaladdo GFSAD30_croplands_100m_2013_01_01.tif 2 4 8 16 32 64 128')
