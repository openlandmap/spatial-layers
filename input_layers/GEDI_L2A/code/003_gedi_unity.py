import os
import pandas as pd
import geopandas as gpd
from shapely.geometry import Polygon
from tqdm import tqdm
from eumap import parallel
from eumap.misc import ttprint
import numpy as np
import multiprocessing
import pyarrow.parquet as pq
from minio import Minio


### read files into list
#files = []
#root_path  = '/mnt/gaia/tmp/GEDI/GEDI02_A.002/'
#for sub_dir in os.scandir(root_path):
#    for file in os.scandir(sub_dir.path):
#        files.append(file.path)
        
#args = [(i,'go') for i in np.arange(len(files))]

### get total number of rows in files
#def test_worker(i,msg):
#    #try:
#        file = files[i]
#        sub_count = 0
#        row_count = len(pq.read_table(file,columns=['date']))
#        sub_count += row_count
#        return sub_count
    #except:
    #    print(f'ERROR in {file}')

#row_total = 0
#for result in parallel.job(test_worker, args, n_jobs=-1):
#    row_total += result        

### create an empty array for futher storage
#arr = np.empty((row_total,10))
#print(arr.shape)

### insert data from intermediate gedi to a single array
#def exe_worker(i,msg):
    #try:
#        file = files[i]
#        gddata = gpd.read_parquet(file)
#        gddata['date'] =  gddata['date'].apply(lambda x: int(x))
#        #print(gddata['date'].values)
#        gddata['x'] = gddata['geometry'].x
#        gddata['y'] = gddata['geometry'].y
#        data = gddata.drop(columns = ['geometry']).to_numpy()
#        if len(data)>0:
#            return data
    #except:
    #    print(f'ERROR in {file}')

#pointer = 0
#for result in parallel.job(exe_worker, args, n_jobs=-1):
#    arr_slice = slice(pointer, pointer+len(result))
#    arr[arr_slice,:] = result 
#    pointer += len(result)

### save an intermediate result (to not waste time recompute if some errors occur
#np.save('gedi_all.npy',arr)
    
### Or you can read in the preloading array
arr = np.load('/mnt/fastboy/tmp/faen/gedi_all.npy')

### Data partition
df = pd.DataFrame(arr, columns = ['date', 'lowestmode', 'rh100', 'rh99', 'rh98', 'rh75',
       'rh50', 'rh25','x','y'])
gdf = gpd.GeoDataFrame(
    df, geometry=gpd.points_from_xy(df.x, df.y), crs="EPSG:4326"
)

gdf = gdf.drop(columns = ['x','y'])
gdf['date'] = gdf['date'].apply(lambda x:str(int(x)))
out_file = f'/mnt/fastboy/tmp/faen/gedi_v1.fgb'
gdf.to_file(out_file,driver="FlatGeobuf")