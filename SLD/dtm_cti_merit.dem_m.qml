<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" version="3.4.1-Madeira" hasScaleBasedVisibilityFlag="0" maxScale="0" minScale="1e+8">
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
    <rasterrenderer opacity="1" classificationMax="2000" type="singlebandpseudocolor" alphaBand="-1" classificationMin="-2000" band="1">
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
          <colorramp name="[source]" type="gradient">
            <prop k="color1" v="43,131,186,255"/>
            <prop k="color2" v="215,25,28,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0.25;171,221,164,255:0.5;255,255,191,255:0.75;253,174,97,255"/>
          </colorramp>
          <item color="#2b83ba" value="-2000" alpha="255" label="-2000"/>
          <item color="#5ea7b1" value="-1600" alpha="255" label="-1600"/>
          <item color="#91cba9" value="-1200" alpha="255" label="-1200"/>
          <item color="#bce4aa" value="-800" alpha="255" label="-800"/>
          <item color="#def2b4" value="-400" alpha="255" label="-400"/>
          <item color="#ffffbf" value="0" alpha="255" label="0"/>
          <item color="#ffdf9a" value="400" alpha="255" label="400"/>
          <item color="#febe74" value="800" alpha="255" label="800"/>
          <item color="#f69053" value="1200" alpha="255" label="1200"/>
          <item color="#e75437" value="1600" alpha="255" label="1600"/>
          <item color="#d7191c" value="2000" alpha="255" label="2000"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeBlue="128" colorizeGreen="128" colorizeRed="255" colorizeStrength="100" grayscaleMode="0" colorizeOn="0" saturation="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
