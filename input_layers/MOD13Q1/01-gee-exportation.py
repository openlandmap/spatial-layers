import ee

ee.Initialize()

def modisQaMask(image):
  
  qa = image.select('SummaryQA');
  qaMask = qa.gt(1)
              
  return image.mask(qaMask.Not());

def genTimeSerie(dsName, dataSources, year):
  
  ts = dataSources[dsName]['ts']
  
  startDt = ee.Date(str(year) + ts['startDtSuffix'])

  bandName = dataSources[dsName]['band'] 
  reducer = dataSources[dsName]['reducer']  
  qaMask = dataSources[dsName]['qaMask']
  imgCollection = dataSources[dsName]['imgCollection']
  footprint = imgCollection.get('system:footprint')
  
  def genComposite(i, result):
    result = ee.Dictionary(result)
    startDt = ee.Date(result.get('startDt'))
    images = ee.List(result.get('images'))
    
    endDt = startDt.advance(ts['delta'], ts['unit'])

    startDt = startDt.advance(-16, 'day')
    endDt = endDt.advance(16, 'day')
    
    composite = imgCollection.filterDate(startDt, endDt) \
                          .map(qaMask) \
                          .select(bandName) \
                          .reduce(reducer) \
                          .select([0],[bandName])
                          
                          
    composite = composite.set({
      'start_date': ee.Date(startDt).format('YYYY-MM-dd'),
      'end_data': ee.Date(endDt).format('YYYY-MM-dd')
    })
    
    startDt = endDt
    images = images.add(composite)
    
    return { 'startDt':startDt, 'images': images }

  timeFrames = ee.List.sequence(1, ts['totalUnits'], 1)
  composites = timeFrames.iterate(genComposite, { "startDt":startDt, "images": [] } )
  
  return ee.List(ee.Dictionary(composites).get('images'))

def listToBands(imageList):
  
  def addAsBand(img, result):
    return ee.Image(result).addBands(img)

  imageList = ee.List(imageList)
  firstImg = imageList.get(0)
  return ee.Image(imageList.slice(1, imageList.size()).iterate(addAsBand, firstImg))

def exportTs(dsName, year, dataSources, exportation):
  imageList = genTimeSerie(dsName, dataSources, year)
  
  image = listToBands(imageList)

  totalUnits = dataSources[dsName]['ts']['totalUnits']
  unit = dataSources[dsName]['ts']['unit']

  outputname = str(year) + '_' + dsName + '_' + dataSources[dsName]['band']

  print("Exporting %s (%s %ss) to %s" % (outputname, totalUnits, unit, exportation['folder']))

  task = ee.batch.Export.image.toCloudStorage(
    image = image,
    description = outputname, 
    #folder = exportation['folder'],
    bucket = 'global_eo',
    fileNamePrefix = exportation['folder'] + '/' + outputname,
    scale = exportation['scale'],
    crs = exportation['crs'],
    region = exportation['region'],
    maxPixels = 1e13)

  task.start()

dataSources = {
  'MODIS': {
    'imgCollection': ee.ImageCollection("MODIS/006/MOD13Q1"),
    'band': 'EVI',
    'qaMask': modisQaMask,
    'reducer': ee.Reducer.percentile([90]),
    'ts': {
        'startDtSuffix': '-01-01',
        'delta': 2,
        'unit': 'month',
        'totalUnits': 6
    }
  }
}

exportation = {
  'region': ee.Geometry.Polygon([-180, 90, 0, 90, 180, 90, 180, -90, 10, -90, -180, -90], None, False),
  'folder': 'GLOBAL_MOD13Q1_EVI',
  'scale': 250,
  'crs': 'EPSG:4326'
}

for year in range(2000,2021):

  if year == 2000:
    dataSources['MODIS']['ts']['startDtSuffix'] = '-02-01'
  else:
    dataSources['MODIS']['ts']['startDtSuffix'] = '-01-01'

  dataSources['MODIS']['band'] = 'EVI'
  exportTs('MODIS', year, dataSources, exportation)
