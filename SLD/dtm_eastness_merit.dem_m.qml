<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.4.1-Madeira" maxScale="0" styleCategories="AllStyleCategories" hasScaleBasedVisibilityFlag="0" minScale="1e+8">
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
    <rasterrenderer alphaBand="-1" type="singlebandpseudocolor" band="1" opacity="1" classificationMin="-1000" classificationMax="1000">
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
        <colorrampshader colorRampType="INTERPOLATED" clip="0" classificationMode="2">
          <colorramp type="gradient" name="[source]">
            <prop k="color1" v="43,131,186,255"/>
            <prop k="color2" v="215,25,28,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0.45;171,221,164,255:0.5;255,255,191,255:0.55;253,174,97,255"/>
          </colorramp>
          <item value="-1000" color="#2b83ba" label="-1e+3" alpha="255"/>
          <item value="-800" color="#4797b5" label="-800" alpha="255"/>
          <item value="-600" color="#64abb0" label="-600" alpha="255"/>
          <item value="-400" color="#80bfac" label="-400" alpha="255"/>
          <item value="-200" color="#9dd3a7" label="-200" alpha="255"/>
          <item value="0" color="#ffffbf" label="0" alpha="255"/>
          <item value="200" color="#f99e59" label="200" alpha="255"/>
          <item value="400" color="#f17c4a" label="400" alpha="255"/>
          <item value="600" color="#e85b3a" label="600" alpha="255"/>
          <item value="800" color="#e03a2b" label="800" alpha="255"/>
          <item value="1000" color="#d7191c" label="1e+3" alpha="255"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeRed="255" colorizeOn="0" saturation="0" colorizeGreen="128" colorizeStrength="100" grayscaleMode="0" colorizeBlue="128"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
