import os
import geopandas as gpd
import pandas as pd
import numpy as np
from shapely.geometry import box
from eumap import parallel

# input folder as argument
args = [('input',i.path) for i  in os.scandir('~./gedi_ard')]

# work in parallel. Count number of points, set the name, make a lower left bbox based on the name. Finally return as a data frame
def worker(msg,i):
    count = len(gpd.read_parquet(i))
    name = i.split('/')[-1][:-3]
    if name[3] == 'W':
        x = -int(name[:3])
    else:
        x = int(name[:3])

    if name[7] == 'S':
        y = -int(name[5:7])
    else:
        y = int(name[5:7])
    poly = box(*(x, y,x+1 , y+1))
    d = {'name': [name], 'count': [count], 'geometry':[poly]}
    df = pd.DataFrame(data=d)
    return df


ls = []
for result in parallel.job(worker, args, n_jobs=60):
    ls.append(result)

# make a geodataframe and save
gdf = gpd.GeoDataFrame(pd.concat(ls), crs="EPSG:4326")
gdf.to_file('lookup.fgb',driver='FlatGeobuf')