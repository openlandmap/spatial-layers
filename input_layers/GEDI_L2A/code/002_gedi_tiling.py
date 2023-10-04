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

### connection setting to S3
host = '192.168.1.30:8333'
access_key = "iwum9G1fEQ920lYV4ol9"
access_secret = "GMBME3Wsm8S7mBXw3U4CNWurkzWMqGZ0n2rXHggS0"
bucket_name = 'tmp-gedi-ard'
minio_client = Minio(host, access_key, access_secret, secure=False)


### read files into list
files = []
root_path  = '/mnt/gaia/tmp/GEDI/GEDI02_A.002/'
for sub_dir in os.scandir(root_path):
    for file in os.scandir(sub_dir.path):
        files.append(file.path)
        
args = [(i,'go') for i in np.arange(len(files))]

### get total number of rows in files from test workers
def test_worker(i,msg):
    try:
        file = files[i]
        sub_count = 0
        row_count = len(pq.read_table(file,columns=['date']))
        sub_count += row_count
        return sub_count
    except:
        print(f'ERROR in {file}')

row_total = 0
for result in parallel.job(test_worker, args, n_jobs=-1):
    row_total += result        

### create an empty array for futher storage
arr = np.empty((row_total,10))
print(arr.shape)

### insert data from intermediate gedi to a single array by execute workers
def exe_worker(i,msg):
    try:
        file = files[i]
        gddata = gpd.read_parquet(file)
        gddata['date'] =  gddata['date'].apply(lambda x: int(x))
        #print(gddata['date'].values)
        gddata['x'] = gddata['geometry'].x
        gddata['y'] = gddata['geometry'].y
        data = gddata.drop(columns = ['geometry']).to_numpy()
        if len(data)>0:
            return data
    except:
        print(f'ERROR in {file}')

pointer = 0
for result in parallel.job(exe_worker, args, n_jobs=-1):
    arr_slice = slice(pointer, pointer+len(result))
    arr[arr_slice,:] = result 
    pointer += len(result)

### save an intermediate result (to not waste time recompute if some errors occur
#np.save('gedi_all.npy',arr)
    
### Or you can read in the preloading array
#arr = np.load('/mnt/fastboy/tmp/faen/gedi_all.npy')

### Data partition

## define global bbox
bbox = [-180,-56,180,75]
def recursive_split(arr,n, bbox):
    print(arr.shape)
    ## test if there is no data in our arr. If not, return None
    if n < 2:
        pass
    else:
        x_bound = np.logical_and(arr[:,-2]<bbox[2],arr[:,-2]>bbox[0])
        y_bound = np.logical_and(arr[:,-1]<bbox[3],arr[:,-1]>bbox[1])
        arr = arr[np.logical_and(x_bound,y_bound)]
    if len(arr)==0:
        #print('nothing in bbox')
        return
    ## create a center point that partition bbox into 4 smaller bbox
    cent = [(bbox[0]+bbox[2])/2,(bbox[1]+bbox[3])/2]
    
    ## if subset bbox is smaller than 1 degree, return, and transfer arr into geopanadas and then save as a geoparquet
    if (cent[0]-bbox[0])<1 and (cent[1]-bbox[1])<1:
        # take lower left as reference 
        x = int(bbox[0])
        y = int(bbox[1])
        if x < 0:
            ew = 'W'
            x = -x
        else:
            ew = 'E'

        if y < 0:
            ns = 'S'
            y = -y
        else:
            ns = 'N'
        df = pd.DataFrame(arr, columns = ['date', 'lowestmode', 'rh100', 'rh99', 'rh98', 'rh75',
               'rh50', 'rh25','x','y'])
        gdf = gpd.GeoDataFrame(
            df, geometry=gpd.points_from_xy(df.x, df.y), crs="EPSG:4326"
        )
        
        gdf = gdf.drop(columns = ['x','y'])
        gdf['date'] = gdf['date'].apply(lambda x:str(int(x)))
        #out_file = f'gedi_ard_gpkg/{str(x).zfill(3)}{ew}_{str(y).zfill(2)}{ns}.gpkg'
        #gdf.to_file(out_file,driver="GPKG")
        out_file = f'gedi_ard/{str(x).zfill(3)}{ew}_{str(y).zfill(2)}{ns}.pq'
        gdf.to_parquet(out_file)
        minio_client.fput_object(bucket_name, f'/{out_file}', out_file)
        ttprint(f'Copying {out_file} to http://{host}/{bucket_name}/{out_file}\n')
        os.remove(out_file)
        
        return
    ## if the sub bbox in x is smaller than 1 degree, then just parition horizontally
    if (cent[0]-bbox[0])<1:
        if not float(cent[1]).is_integer():
            cent[1] = np.floor(cent[1])

        #print('end dividing x')
        u = arr[arr[:,-1]<cent[1]]
        u_bbox= [bbox[0],bbox[1],bbox[1],cent[1]]
        l = arr[arr[:,-1]>cent[1]]
        l_bbox= [bbox[0],cent[1],bbox[1],bbox[3]]
        return recursive_split(u, n+1, u_bbox) , recursive_split(l, n+1,l_bbox)
    
    ## if the sub bbox in y is smaller than 1 degree, then just parition vertically
    if (cent[1]-bbox[1])<1:
        if not float(cent[0]).is_integer():
            cent[0] = np.floor(cent[0])

        #print('end dividing y')
        l = arr[arr[:,-2]<cent[0]]
        l_bbox= [bbox[0],bbox[1],cent[0],bbox[3]]
        r = arr[arr[:,-2]>cent[0]]
        r_bbox= [cent[0],bbox[1],bbox[2],bbox[3]]
        return recursive_split(l, n+1, l_bbox) , recursive_split(r, n+1,r_bbox)
        
    ## when the center point is not integer, then force it to the floor integer
    if not float(cent[0]).is_integer():
        cent[0] = np.floor(cent[0])
    if not float(cent[1]).is_integer():
        cent[1] = np.floor(cent[1])
    
    ## parititon to 4 quadrants
    ul = arr[np.logical_and(arr[:,-2]<cent[0],arr[:,-1]<cent[1])]
    ur = arr[np.logical_and(arr[:,-2]>cent[0],arr[:,-1]<cent[1])]
    ll = arr[np.logical_and(arr[:,-2]<cent[0],arr[:,-1]>cent[1])]
    lr = arr[np.logical_and(arr[:,-2]>cent[0],arr[:,-1]>cent[1])]

    ul_bbox= [bbox[0],bbox[1],cent[0],cent[1]]            
    ur_bbox= [cent[0],bbox[1],bbox[2],cent[1]]
    ll_bbox= [bbox[0],cent[1],cent[0],bbox[3]]
    lr_bbox= [cent[0],cent[1],bbox[2],bbox[3]]

    ## recursive in parallel
    ul_p = multiprocessing.Process(target=recursive_split,args=(ul, n+1, ul_bbox))
    ul_p.start()    
    ur_p = multiprocessing.Process(target=recursive_split,args=(ur, n+1, ur_bbox))
    ur_p.start()
    ll_p = multiprocessing.Process(target=recursive_split,args=(ll, n+1, ll_bbox))
    ll_p.start()
    lr_p = multiprocessing.Process(target=recursive_split,args=(lr, n+1, lr_bbox))
    lr_p.start()
    return ul_p.join(),ur_p.join(),ll_p.join(),lr_p.join()

recursive_split(arr,0,bbox)