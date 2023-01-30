
saveRDS.gz <- function(object,file,threads=parallel::detectCores()) {
  con <- pipe(paste0("pigz -p",threads," > ",file),"wb")
  saveRDS(object, file = con)
  close(con)
}

readRDS.gz <- function(file,threads=parallel::detectCores()) {
  con <- pipe(paste0("pigz -d -c -p",threads," ",file))
  object <- readRDS(file = con)
  close(con)
  return(object)
}

get.xy = function(obj){
  cc = do.call(expand.grid, coordinatevalues.xy(obj))
  out = do.call(cbind, lapply(cc, as.numeric))
  return(out)
}

## Modified R-sp function to run in parallel / for large matrices
coordinatevalues.xy <- function(obj) {
  if(!is(obj, "GridTopology"))
    stop("function only works for objects of class or extending GridTopology")
  ret = list()
  ret = parallel::mclapply(seq_along(obj@cells.dim), function(i){
    if(i == 2) # y-axis is the exception--starting at top of map, and decreasing:
      obj@cellcentre.offset[i] + obj@cellsize[i] * ((obj@cells.dim[i] - 1):0)
    else
      obj@cellcentre.offset[i] + obj@cellsize[i] * (0:(obj@cells.dim[i] - 1))
    }, mc.cores = parallel::detectCores())
  ns = names(obj@cellcentre.offset)
  if(is.null(ns))
    ns = paste("s", 1:length(ret), sep = "") #dimnames(obj@bbox)[[1]]
  names(ret) = ns
  ret
}

## https://stackoverflow.com/questions/31062486/quickly-split-a-large-vector-into-chunks-in-r
plyrChunks <- function(d, n){
  is <- seq(from = 1, to = length(d), by = ceiling(n))
  if(tail(is, 1) != length(d)) {
    is <- c(is, length(d)) 
  } 
  chunks <- plyr::llply(head(seq_along(is), -1), 
                  function(i){
                    start <-  is[i];
                    end <- is[i+1]-1;
                    d[start:end]})
  lc <- length(chunks)
  td <- tail(d, 1)
  chunks[[lc]] <- c(chunks[[lc]], td)
  return(chunks)
}

## https://agupubs.onlinelibrary.wiley.com/doi/full/10.1002/2013JD020803
temp.from.geom <- function(fi, day, a=30.419375, b=-15.539232, elev=0, t.grad = 0.6) {
  f = ifelse(fi==0,1e-10,fi)
  costeta = cos( (day-18 )*pi/182.5 +2^(1-sign(fi) ) *pi) 
  cosfi = cos(fi*pi/180 )
  A = cosfi
  B = (1-costeta ) * abs(sin(fi*pi/180 ) )
  x = a*A + b*B - t.grad * elev / 100
  return(x)
}
