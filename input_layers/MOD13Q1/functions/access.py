from datetime import datetime
from dateutil.relativedelta import relativedelta
from eumap import parallel
from pathlib import Path
import pandas as pd
import numpy as np
import rasterio 
import math

import matplotlib
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import seaborn as sns

S3_URL = 'https://s3.eu-central-1.wasabisys.com/openlandmap/veg'
#S3_URL = 'http://192.168.1.57:9000/global/veg'

def _eval(str_val, args):
    return eval("f'"+str_val+"'", args)

def _gen_urls(layer, start_year, end_year, base_url=S3_URL):
    urls = []
    dt_format = '%Y.%m.%d'
    for year in range(start_year, end_year+1):
        for month in range(1,12,2):
            dt1 = datetime.strptime(f'{year}.{str(month).zfill(2)}.01', dt_format)
            dt2 = dt1 + relativedelta(months=+2) + relativedelta(days=-1)
            if dt2.strftime("%d") == '29':
                dt2 = dt2 + relativedelta(days=-1)
            dt1 = dt1.strftime(dt_format)
            dt2 = dt2.strftime(dt_format)
            
            url = _eval(f'{base_url}/{layer}', locals())
            urls.append(url)
    return urls

def get_mod13q1_evi_urls(start_year=2000, end_year=2020):
    return _gen_urls('veg_evi.mod13q1_tmwm.inpaint_p90_250m_0..0cm_{dt1}..{dt2}_v0.2.tif', start_year, end_year)

def get_mod13q1_evi_flags_urls(start_year=2000, end_year=2020):
    return _gen_urls('veg_evi.mod13q1_tmwm.inpaint_f_250m_0..0cm_{dt1}..{dt2}_v0.2.tif', start_year, end_year)

def get_mod13q1_evi_trend_urls(start_year=2000, end_year=2020):
    return _gen_urls('veg_evi.mod13q1_stl.trend_p90_250m_0..0cm_{dt1}..{dt2}_v0.2.tif', start_year, end_year)

def get_mod13q1_evi_ols_urls():
    return [ f'{S3_URL}/{layer}' 
            for layer in [
                'veg_evi.mod13q1_stl.trend.logit.ols.alpha_m_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.alpha_l.025_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.alpha_pv_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.alpha_sd_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.alpha_tv_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.alpha_u.975_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.beta_m_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.beta_l.025_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.beta_pv_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.beta_sd_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.beta_tv_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols.beta_u.975_250m_0..0cm_2000..2020_v0.2.tif',
                'veg_evi.mod13q1_stl.trend.logit.ols_r2_250m_0..0cm_2000..2020_v0.2.tif'
            ]
           ]

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
            dt = str(raster_name).split('_')[6]
            start_date = dt.split('..')[0].replace('.','-')
            end_date = dt.split('..')[1].replace('.','-')
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

def run_ols(trend):
    from scipy.special import expit, logit
    import statsmodels.api as sm

    trend[trend > 10000] = 10000
    trend[trend < 0] = 0

    trend_norm = (trend + 1) / 10002
    trend_norm = logit(trend_norm)

    y = trend_norm
    y_size = trend_norm.shape[0]

    _X = np.array(range(0, y_size)) / y_size

    X = sm.add_constant(_X)
    model = sm.OLS(y,X)
    results = model.fit()

    conf_int = results.conf_int(alpha=0.05, cols=None)
    r = expit(results.params[0] + _X * results.params[1])
    low = expit(results.params[0]-results.bse[0] + _X * results.params[1]-results.bse[1])
    upp = expit(results.params[0]+results.bse[0] + _X * results.params[1]+results.bse[0])
    r2 = results.rsquared
    pv = results.pvalues

    return r, low, upp, r2, pv

def read_and_plot_ts(lat, lon, start_year=2000, end_year=2020):
    gpf = read_ts(lon, lat, get_mod13q1_evi_urls(start_year, end_year))
    stl = read_ts(lon, lat, get_mod13q1_evi_trend_urls(start_year, end_year))
    reg, low, upp, r2, pv = run_ols(stl['value'])

    sns.set_style("ticks")
    matplotlib.rcParams.update({'font.size': 15})

    myfig, myax = plt.subplots(figsize=(10, 6))

    # Plot temperature
    myax.plot(pd.to_datetime(gpf['start_date'], format='%Y-%m-%d'), reg, color='tab:red', linestyle='-', label='OLS')
    myax.fill_between(pd.to_datetime(gpf['start_date'], format='%Y-%m-%d'), low, upp, color='tab:red', alpha=0.2)
    myax.plot(pd.to_datetime(gpf['start_date'], format='%Y-%m-%d'), gpf['value']/10000, color='tab:blue', linestyle='-', label='Gapfilled')
    myax.plot(pd.to_datetime(stl['start_date'], format='%Y-%m-%d'), stl['value']/10000, color='tab:green', linestyle='-', label='Trend')

    myax.set_xlabel('Time')
    myax.set_ylabel('EVI')
    myax.set_title(f'MOD13Q1 ({lon:.4f}, {lat:.4f}) \n r2={r2:.3f}, beta(P>|t|)={pv[1]:.3f}, alpha(P>|t|)={pv[0]:.3f}')
    myax.grid(False)

    # format x axis labels
    #myax.xaxis.set_major_locator(DayLocator())
    #myax.xaxis.set_major_formatter(mdates.DateFormatter('%y%m%d'))
    fmt_half_year = mdates.MonthLocator(interval=29)

    myax.legend(loc='lower left');