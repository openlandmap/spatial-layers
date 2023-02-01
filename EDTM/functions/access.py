import pandas as pd
import rasterio
from eumap import parallel
from pathlib import Path
import numpy as np
import seaborn as sns
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

S3_URL = 'https://s3.openlandmap.org/arco'

def _eval(str_val, args):
    return eval("f'"+str_val+"'", args)

def get_ensem_dtm_bare_earth_url():
    return ('https://s3.eu-central-1.wasabisys.com/openlandmap/dtm/dtm.bareearth_ensemble_p10_30m_s_2018_go_epsg4326_v20230130.tif')

def get_ensem_dtm_std_url():
    return ('https://s3.eu-central-1.wasabisys.com/openlandmap/dtm/dtm.bareearth_ensemble_std_30m_s_2018_go_epsg4326_v20230130.tif')

def read_overview(layer_path, oviews_pos = -4, verbose = False):
    if verbose:
        print(f'Reading {layer_path}')
    with rasterio.open(layer_path) as src:
        # List of overviews from biggest to smallest
        oviews = src.overviews(1)
        if verbose:
            print(f'-Available overviews: {oviews}')
        oview = oviews[oviews_pos]
        result = src.read(1, out_shape=(1, src.height // oview, src.width // oview)).astype('float32')
        return result, src

def read_pixel(cog_url, coordinates):
    pixel_val = None
    try:
        with rasterio.open(cog_url) as ds:
            pixel_val = np.stack(ds.sample(coordinates))
    except Exception as e:
        print(e, 'at coordinates', coordinates)
    return pixel_val

def read_ts(lon, lat, urls):
    result = []
    args = [ (cog_url, [ (lon, lat) ] ) for cog_url in urls ]
    for arg, pixel_vals in zip(args, parallel.job(read_pixel, args, n_jobs=-1)):
        raster_name = Path(arg[0]).name
        cordinates = arg[1]
        try:
            start_date = str(raster_name).split('_')[5]
            end_date = str(raster_name).split('_')[6]
        except:
            dt = None
            start_date = None
            end_date = None
        
        #print(raster_name, pixel_vals)
        for i in range(0, len(cordinates)):
            lon, lat = cordinates[i]
            result.append({
                'raster_name': raster_name,
                'start_date': start_date,
                'end_date': end_date,
                'lon': lon,
                'lat': lat, 
                'value': float(pixel_vals[i][0])
            })

    return pd.DataFrame(result)

