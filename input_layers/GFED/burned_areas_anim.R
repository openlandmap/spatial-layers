## Animation of 30 yrs of fires
## tom.hengl@opengeohub.org

library(raster)
library(maps)
library(scales)
library(maptools)
library(plotKML)
country.m <- map('world', plot=FALSE, fill=TRUE)
IDs <- sapply(strsplit(country.m$names, ":"), function(x) x[1])
require(maptools)
country <- as(map2SpatialPolygons(country.m, IDs=IDs), "SpatialLines")

tifs.lst <- list.files("/mnt/landmark/fires/GFED_20km", pattern = glob2rx("burned_area_GFED4*.tif$"), full.names = TRUE) 
## 240 images
tbl <- data.frame(filename=tifs.lst)
tbl$Year.Month <- paste0(substr(sapply(tbl$filename, function(i){strsplit(basename(i), "_")[[1]][4]}), 1, 4), "-", 
                              substr(sapply(tbl$filename, function(i){strsplit(basename(i), "_")[[1]][5]}), 1, 2))
raster(tifs.lst[1])

#grep("burned_area_GFED4.1s_2003.hdf5_10", tbl$filename)
plot_map <- function(i, tbl, out.dir="/data/tmp/GFED_20km/"){
  out.file = paste0(out.dir, gsub(".tif", ".png", basename(tbl[i,"filename"])))
  if(!file.exists(out.file)){
    png(file = out.file, width = 1440, height = 720, type="cairo")
    par(mar=c(0,0,0,0), oma=c(0,0,0,0))
    image(log1p(raster(paste(tbl[i,"filename"])))*10, asp=1, col=c(R_pal[[2]], rep("#FF0000FF", 20)), zlim=c(0,100))
    text(-60, paste(tbl[i,"Year.Month"]), cex=2)
    lines(country, col=alpha("black", 0.15), cex=0.8)
    dev.off()
  }
}

## Create animation:
x = parallel::mclapply(1:nrow(tbl), plot_map, tbl, mc.cores=10)
## https://stackoverflow.com/questions/51310892/import-png-files-and-convert-to-animation-mp4-in-r
# library(animation)
imgs <- paste0("/data/tmp/GFED_20km/", gsub(".tif", ".png", basename(tbl$filename)))
# saveVideo({
#   for(img in imgs){
#     im <- magick::image_read(img)
#     plot(as.raster(im))
#   }  
# }, video.name = "/data/tmp/fires_historic_GFED4.mp4")
#system(paste0('convert -delay 100 ', paste(gsub(".tif", ".png", basename(tbl$filename)), collapse=" "), ' /data/tmp/fires_historic_GFED4.gif -monitor'))
## TAKES >1hr
x = file.copy(imgs, paste0("image_", 1:length(tifs.lst), ".png"))
## https://askubuntu.com/questions/610903/how-can-i-create-a-video-file-from-a-set-of-jpg-images
unlink('/data/tmp/fires_historic_GFED4.mp4')
system('ffmpeg -framerate 8 -i image_%00d.png -c:v libx264 -profile:v high -crf 20 -pix_fmt yuv420p /data/tmp/fires_historic_GFED4.mp4')
