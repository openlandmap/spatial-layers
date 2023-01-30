<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis hasScaleBasedVisibilityFlag="0" version="3.4.1-Madeira" styleCategories="AllStyleCategories" maxScale="0" minScale="1e+8">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property key="WMSBackgroundLayer" value="false"/>
    <property key="WMSPublishDataSourceUrl" value="false"/>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="identify/format" value="Value"/>
  </customproperties>
  <pipe>
    <rasterrenderer type="singlebandpseudocolor" classificationMin="-10" classificationMax="10" opacity="1" band="1" alphaBand="-1">
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
        <colorrampshader clip="0" classificationMode="2" colorRampType="INTERPOLATED">
          <colorramp type="gradient" name="[source]">
            <prop k="color1" v="43,131,186,255"/>
            <prop k="color2" v="215,25,28,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0.48;171,221,164,255:0.5;255,255,191,255:0.52;253,174,97,255"/>
          </colorramp>
          <item label="-10" value="-10" color="#2b83ba" alpha="255"/>
          <item label="-8" value="-8" color="#4596b6" alpha="255"/>
          <item label="-6" value="-6" color="#60a9b1" alpha="255"/>
          <item label="-4" value="-4" color="#7bbbac" alpha="255"/>
          <item label="-2" value="-2" color="#96cea8" alpha="255"/>
          <item label="0" value="0" color="#ffffbf" alpha="255"/>
          <item label="2" value="2" color="#f79555" alpha="255"/>
          <item label="4" value="4" color="#ef7647" alpha="255"/>
          <item label="6" value="6" color="#e75738" alpha="255"/>
          <item label="8" value="8" color="#df382a" alpha="255"/>
          <item label="10" value="10" color="#d7191c" alpha="255"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation saturation="0" grayscaleMode="0" colorizeStrength="100" colorizeRed="255" colorizeOn="0" colorizeBlue="128" colorizeGreen="128"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
