import os
os.environ['USE_PYGEOS'] = '0'
import h5py
import numpy as np
import pandas as pd
import geopandas as gp
from shapely.geometry import Point
from tqdm import tqdm
import geopandas as gpd
from pathlib import Path
from datetime import datetime,timedelta

from eumap.misc import ttprint
from eumap import parallel
from eumap.misc import ttprint

### Search all files in folder
folder = '/mnt/gaia/raw/GEDI/GEDI02_A.002/'
print('start')
args = []
for sub_dir in os.scandir(folder):
    for file in os.scandir(sub_dir.path):
        args.append((sub_dir.path,file.name))

### In case to tackle individual failing files
#args = [('/mnt/gaia/raw/GEDI/GEDI02_A.002/2019.06.16','GEDI02_A_2019167121250_O02883_03_T05018_02_003_01_V002.h5')]
#print(f'file number: {len(args)}')

### Redo the preprocess. Using a txt file of no_valid_list to avoid reprocessed the no_valid dataset.
#with open('/mnt/freya/ensemble_DTM_faen/no_valid_list.in') as f:
#    lines = ''.join(f.readlines()).replace('\n', '')

### filter gedi points
def _gedi_filter(indir,file):
    try:
        L2A = indir+'/'+file
        
        ## Avoid processing no valid dataset 
        
        #if L2A in lines:
        #    ttprint(f'no valid points in {L2A}')
        #    return
        
        ## Avoid processing the dataset with existing output dataset
        out_file_test = L2A.replace('raw','tmp').replace('h5','pq')
        if os.path.exists(out_file_test):
            ttprint(f'skip {L2A}')
            return
        
        ## Process based on LP DAAC tutorial (https://lpdaac.usgs.gov/resources/e-learning/getting-started-gedi-l2a-version-2-data-python/)
        ttprint(f'reading {L2A}')    
        gediL2A = h5py.File(L2A, 'r')  # Read file using h5py
        gediL2A_objs = []
        gediL2A.visit(gediL2A_objs.append)                                           # Retrieve list of datasets
        gediSDS = [o for o in gediL2A_objs if isinstance(gediL2A[o], h5py.Dataset)]  # Search for relevant SDS inside data file
        ttprint(f'end reading')    

        beamNames = [g for g in gediL2A.keys() if g.startswith('BEAM')]
        beamLabels = list(map(lambda x:x.replace(x,'Coverage'),beamNames[:4])) + list(map(lambda x:x.replace(x,'Full Power'),beamNames[4:]))
        sdate = datetime(2018,1,1)


        ttprint(f'processing beams')
        delta_time,se,zLat,zLon,qf,st,lowestmode,rh100,rh99,rh98,rh75,rh50,rh25,df,srf,sa = ([] for i in range(16))
        for b,l in list(zip(beamNames,beamLabels)):       
            # Loop through each beam and open the SDS needed
            [delta_time.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/delta_time') and b in g][0]][()]]    
            [zLat.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/lat_lowestmode') and b in g][0]][()]]
            [zLon.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/lon_lowestmode') and b in g][0]][()]]
            #[se.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/solar_elevation') and b in g][0]][()]]
            [qf.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/quality_flag') and b in g][0]][()]]
            [st.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/sensitivity') and b in g][0]][()]]
            #[sa.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/selected_algorithm') and b in g][0]][()]]
            [lowestmode.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/elev_lowestmode') and b in g][0]][()]]
            [rh100.append(h[-1]) for h in gediL2A[[g for g in gediSDS if g.endswith('/rh') and b in g][0]][()]]
            [rh99.append(h[-2]) for h in gediL2A[[g for g in gediSDS if g.endswith('/rh') and b in g][0]][()]]
            [rh98.append(h[-3]) for h in gediL2A[[g for g in gediSDS if g.endswith('/rh') and b in g][0]][()]]
            [rh25.append(h[24]) for h in gediL2A[[g for g in gediSDS if g.endswith('/rh') and b in g][0]][()]]
            [rh50.append(h[49]) for h in gediL2A[[g for g in gediSDS if g.endswith('/rh') and b in g][0]][()]]
            [rh75.append(h[74]) for h in gediL2A[[g for g in gediSDS if g.endswith('/rh') and b in g][0]][()]]
            [df.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/degrade_flag') and b in g][0]][()]]
            #[srf.append(h) for h in gediL2A[[g for g in gediSDS if g.endswith('/stale_return_flag') and b in g][0]][()]]
        
        ## Convert lists to Pandas dataframe, filter out accroding to flags
        
        date = indir.rsplit('/',1)[-1].replace('.','')
        dataframe = pd.DataFrame({'date':date,  'latitude': zLat, 'longitude': zLon, 'lowestmode': lowestmode,'rh100':rh100,'rh99':rh99,'rh98':rh98,'rh75':rh50,'rh50':rh50,'rh25':rh25,'quality flag':qf,'sensitivity':st, 'degrade flag': df})
        dataframe = dataframe[dataframe['quality flag']!=0]
        dataframe = dataframe[dataframe['degrade flag']<=0]
        dataframe = dataframe[dataframe['sensitivity']>=0.98]
        #print(len(dataframe))
        
        ## Output dataframe into geoparquet 
        if len(dataframe) > 0:

            gdf = gpd.GeoDataFrame(
                dataframe, geometry=gpd.points_from_xy(dataframe.longitude, dataframe.latitude), crs="EPSG:4326"
            )
            columns = ['date','geometry','lowestmode','rh100','rh99','rh98','rh75','rh50','rh25']
            gdf  = gdf[columns]
            out_dir = L2A.rsplit('/', 1)[0].replace('raw','tmp')
            os.makedirs(out_dir,exist_ok = True)
            out_file = f"{out_dir}/{L2A.split('/')[-1][:-3]}"
            #columns = ['date','geometry','lowestmode','rh100','rh99','rh98','rh75','rh50','rh25','beam','solar_elevation','sensitivity','quality flag','stale return flag','degrade flag','selected_algorithm']
            ttprint(f'saving {out_file}.pq')
            gdf.to_parquet(f'{out_file}.pq')  
        else:
            ttprint(f'no valid points in {L2A}')
            
    except:
        ttprint(f'ERROR in {L2A}')

### Work process in parallel 
for result in parallel.job(_gedi_filter, args, n_jobs=90):
    print(result)
