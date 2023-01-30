<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" maxScale="0" hasScaleBasedVisibilityFlag="0" version="3.4.1-Madeira" minScale="1e+8">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property value="false" key="WMSBackgroundLayer"/>
    <property value="false" key="WMSPublishDataSourceUrl"/>
    <property value="0" key="embeddedWidgets/count"/>
    <property value="Value" key="identify/format"/>
  </customproperties>
  <pipe>
    <rasterrenderer band="1" opacity="1" classificationMin="0" alphaBand="-1" type="singlebandpseudocolor" classificationMax="1000">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <rastershader>
        <colorrampshader classificationMode="2" clip="0" colorRampType="INTERPOLATED">
          <colorramp type="gradient" name="[source]">
            <prop k="color1" v="8,15,90,255"/>
            <prop k="color2" v="215,25,28,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0;56,126,47,255:0.0832313;151,255,66,255:0.350061;253,166,81,255"/>
          </colorramp>
          <item alpha="255" label="0" value="0" color="#080f5a"/>
          <item alpha="255" label="100" value="100" color="#9efa43"/>
          <item alpha="255" label="200" value="200" color="#c4d849"/>
          <item alpha="255" label="300" value="300" color="#eab74e"/>
          <item alpha="255" label="400" value="400" color="#fa9b4d"/>
          <item alpha="255" label="500" value="500" color="#f58545"/>
          <item alpha="255" label="600" value="600" color="#ef703c"/>
          <item alpha="255" label="700" value="700" color="#e95a34"/>
          <item alpha="255" label="800" value="800" color="#e3442c"/>
          <item alpha="255" label="900" value="900" color="#dd2e24"/>
          <item alpha="255" label="1e+3" value="1000" color="#d7191c"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeBlue="128" colorizeRed="255" saturation="0" colorizeGreen="128" colorizeOn="0" colorizeStrength="100" grayscaleMode="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
