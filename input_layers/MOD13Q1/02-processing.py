import sys
import os

import traceback
from eumap.parallel import TilingProcessing
from eumap import gapfiller
from eumap.misc import find_files, ttprint
from eumap.raster import read_rasters, save_rasters, write_new_raster
from eumap import parallel
import numpy as np
from pathlib import Path
import bottleneck as bn
from minio import Minio
import requests
import statsmodels.api as sm
from scipy.special import expit, logit
from statsmodels.tsa.seasonal import STL

def out_files(out_dir, fn_files, suffix=''):
    out_fn_list = []
    
    for i in range(0, len(fn_files)):
        src_fn = Path(fn_files[i])
        out_fn = Path(str(out_dir)).joinpath('%s%s.tif' % (src_fn.stem, suffix))
        out_fn.parent.mkdir(parents=True, exist_ok=True)
        out_fn_list.append(out_fn)
        
    return out_fn_list

def save_gapfill(gapfiller_alg, out_dir, fn_rasters, window):
    fn_raster_gapfilled = out_files(out_dir, fn_rasters)
    fn_raster_flag = out_files(out_dir, fn_rasters, suffix='_flag')
    
    gapfiller_alg.gapfilled_data[np.isnan(gapfiller_alg.gapfilled_data)] = -32768
    gapfiller_alg.gapfilled_data_flag[np.isnan(gapfiller_alg.gapfilled_data_flag)] = 0
    
    save_rasters(fn_rasters[0], fn_raster_gapfilled, gapfiller_alg.gapfilled_data, spatial_win=window, dtype='int16', nodata=-32768, n_jobs=10)
    save_rasters(fn_rasters[0], fn_raster_flag, gapfiller_alg.gapfilled_data_flag, spatial_win=window, dtype='uint8', nodata=0, n_jobs=10)
    
    return fn_raster_gapfilled + fn_raster_flag

def save_trend(trend_result, out_dir, fn_rasters, window):
    i = 126
    data_trend = trend_result[:,:,0:i]

    lm_result = {}
    lm_result['const'] = trend_result[:,:,i:i+1]
    lm_result['const_bse'] = trend_result[:,:,i+1:i+2]
    lm_result['const_t'] = trend_result[:,:,i+2:i+3]
    lm_result['const_p'] = trend_result[:,:,i+3:i+4]
    lm_result['const_0025'] = trend_result[:,:,i+4:i+5]
    lm_result['const_0975'] = trend_result[:,:,i+5:i+6]
    lm_result['beta'] = trend_result[:,:,i+6:i+7]
    lm_result['beta_bse'] = trend_result[:,:,i+7:i+8]
    lm_result['beta_t'] = trend_result[:,:,i+8:i+9]
    lm_result['beta_p'] = trend_result[:,:,i+9:i+10]
    lm_result['beta_0025'] = trend_result[:,:,i+10:i+11]
    lm_result['beta_0975'] = trend_result[:,:,i+11:i+12]
    lm_result['rsqr'] = trend_result[:,:,i+12:i+13]

    result = []
    
    for key in lm_result.keys():
        data_n = lm_result[key]
        data_n[np.isnan(data_n)] = -32768
        
        fn_new_raster = out_dir.joinpath(f'{key}.tif')
        result.append(fn_new_raster)
        write_new_raster(fn_rasters[0], fn_new_raster, data_n, spatial_win=window, dtype='float32', nodata=-32768,)
    
    fn_trend = out_files(out_dir, fn_rasters, suffix='_trend')
    
    result = result + fn_trend
    
    data_trend[np.isnan(data_trend)] = -32768
    save_rasters(fn_rasters[0], fn_trend, data_trend, spatial_win=window, dtype='int16', nodata=-32768, n_jobs=10)
    
    return result
        
def modis_url(start_year, end_year):
    basepath = 'http://192.168.1.53:9000/tmp/GLOBAL_MOD13Q1_EVI'
    urls = []
    
    for year in range(start_year, end_year+1):
        for i in range(1, 7):
            urls.append(f'{basepath}/{year}_MODIS_EVI_B{str(i).zfill(2)}.tif')
    
    return urls

def trend_analysis(data):
    from scipy.special import expit, logit
    from statsmodels.tsa.seasonal import STL

    has_nan = np.sum(np.isnan(data).astype('int'))
    
    if has_nan == 0:
        
        res = STL(data, period=6, seasonal=7, trend=21, robust=True).fit()
        
        trend = res.trend

        trend[trend > 10000] = 10000
        trend[trend < 0] = 0
        
        trend_norm = (trend + 1) / 10002
        trend_norm = logit(trend_norm)
        
        y = trend_norm
        y_size = trend_norm.shape[0]
        
        X = np.array(range(0, y_size)) / y_size

        X = sm.add_constant(X)
        model = sm.OLS(y,X)
        results = model.fit()
        
        conf_int = results.conf_int(alpha=0.05, cols=None)
        
        result_stack = np.stack([
            results.params,
            results.bse,
            results.tvalues,
            results.pvalues,
            conf_int[0],
            conf_int[1]
        ],axis=1)
        
        return np.concatenate([
            trend,
            result_stack[0,:],
            result_stack[1,:],
            np.stack([results.rsquared])
        ])
        
    else: 
        nan_result = np.empty(139)
        nan_result[:] = np.nan
        return nan_result

def _processed(idx):
  url = f'http://192.168.1.57:9000/tmp/global_mod13q1_evi_final/{idx}/beta.tif'
  r = requests.head(url)
  return (r.status_code == 200)

def run(idx, tile, window, out_dir, landmask):
    try:
        
        if not _processed(idx):

            # Fixing the mismatch between the tiling system e the images
            window = window.round_lengths(op='ceil', pixel_precision=0)

            out_dir = Path(out_dir).joinpath(str(idx))
            
            fn_rasters = modis_url(2000,2020)
            
            land_mask, _ = read_rasters(raster_files=[landmask], n_jobs=1, spatial_win=window)
            land_mask = (np.logical_or((land_mask == 1), (land_mask == 3)))[:,:,0]

            data, _ = read_rasters(raster_files=fn_rasters, verbose=True, n_jobs=10, 
                spatial_win=window, data_mask=land_mask)
            
            data[data <= 0] = np.nan

            ttprint(f'Processing tile {str(idx)} - {str(data.shape)}')
            
            land_mask = land_mask.astype('int')
            
            gapfiller_alg = gapfiller.TMWM(data=data, time_win_size=7, season_size=6, \
                std_win=5, std_env=2, outlier_remover=gapfiller.OutlierRemover.Std)
            
            data_gapfilled = gapfiller_alg.run()
            pct_gapfilled = gapfiller_alg._perc_gapfilled(gapfiller_alg.gapfilled_data)
            
            if pct_gapfilled < 1.0:
                inPainting = gapfiller.InPainting(data=gapfiller_alg.gapfilled_data, space_win = 10, data_mask=land_mask)
                inPainting.run()
                gapfiller_alg.gapfilled_data_flag[inPainting.gapfilled_data_flag == 1] = 100
                inPainting.gapfilled_data_flag = gapfiller_alg.gapfilled_data_flag
                gapfiller_alg = inPainting
            
            ttprint('Running trend analysis')
            trend_result = parallel.apply_along_axis(trend_analysis, 2, gapfiller_alg.gapfilled_data)
            
            result = save_gapfill(gapfiller_alg, out_dir, fn_rasters, window) + \
                     save_trend(trend_result, out_dir, fn_rasters, window)
            
            host = "192.168.1.57:9000"
            access_key = "XXXXXXXXXXXXXXXXX"
            access_secret = "XXXXXXXXXXXXXXXXX"
            bucket_name = 'tmp'
            out_pref = f'global_mod13q1_evi_final/{idx}'
            
            client = Minio(host, access_key, access_secret, secure=False)

            for output_fn_file in result:
                object_name = f'{output_fn_file.name}'
                object_bucket = f'{bucket_name}'
                ttprint(f'Copying {output_fn_file} to http://{host}/{object_bucket}/{out_pref}/{object_name}')
                client.fput_object(object_bucket, f'{out_pref}/{object_name}', output_fn_file)
                os.remove(output_fn_file)

            os.rmdir(out_dir)

        else:
            ttprint(f'Already processed http://192.168.1.57:9000/tmp/global_mod13q1_evi_final/{idx}/beta.tif')

    except:
        tb = traceback.format_exc()
        ttprint(f'ERROR: Tile {idx} failed.')
        ttprint(tb)

    return True

start=int(sys.argv[1])
end=int(sys.argv[2])
server_name=sys.argv[3]

landmask = '/mnt/slurm/jobs/mod13q1_evi/landmask.tif'
tiling_system_fn = '/mnt/slurm/jobs/mod13q1_evi/modis_pol_90km.gpkg'
out_dir = f'/mnt/{server_name}/tmp/GLOBAL_MOD13Q1_EVI_tiles/'
base_raster_fn = 'http://192.168.1.53:9000/tmp/GLOBAL_MOD13Q1_EVI/2000_MODIS_EVI_B03.tif'

tiling = TilingProcessing(tiling_system_fn=tiling_system_fn, base_raster_fn=base_raster_fn, verbose=True)
t = tiling.process_multiple(range(start, end), run, out_dir, landmask, use_threads=False, max_workers=5, progress_bar=False)