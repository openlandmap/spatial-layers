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
    <rasterrenderer band="1" opacity="1" classificationMin="-9041" alphaBand="-1" type="singlebandpseudocolor" classificationMax="8861">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>MinMax</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <rastershader>
        <colorrampshader classificationMode="2" clip="0" colorRampType="INTERPOLATED">
          <colorramp type="gradient" name="[source]">
            <prop k="color1" v="43,131,186,255"/>
            <prop k="color2" v="215,25,28,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0.25;171,221,164,255:0.5;255,255,191,255:0.75;253,174,97,255"/>
          </colorramp>
          <item alpha="255" label="-9041" value="-9041" color="#2b83ba"/>
          <item alpha="255" label="-7251" value="-7250.8" color="#5ea7b1"/>
          <item alpha="255" label="-5461" value="-5460.6" color="#91cba9"/>
          <item alpha="255" label="-3670" value="-3670.4" color="#bce4aa"/>
          <item alpha="255" label="-1880" value="-1880.2" color="#def2b4"/>
          <item alpha="255" label="-90" value="-90" color="#ffffbf"/>
          <item alpha="255" label="1700" value="1700.2" color="#ffdf9a"/>
          <item alpha="255" label="3490" value="3490.4" color="#febe74"/>
          <item alpha="255" label="5281" value="5280.6" color="#f69053"/>
          <item alpha="255" label="7071" value="7070.8" color="#e75437"/>
          <item alpha="255" label="8861" value="8861" color="#d7191c"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeBlue="128" colorizeRed="255" saturation="0" colorizeGreen="128" colorizeOn="0" colorizeStrength="100" grayscaleMode="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
