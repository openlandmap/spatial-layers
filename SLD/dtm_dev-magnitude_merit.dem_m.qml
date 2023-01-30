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
    <rasterrenderer band="1" opacity="1" classificationMin="-10" alphaBand="-1" type="singlebandpseudocolor" classificationMax="10">
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
            <prop k="color1" v="43,131,186,255"/>
            <prop k="color2" v="215,25,28,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0.15;171,221,164,255:0.5;255,255,191,255:0.85;253,174,97,255"/>
          </colorramp>
          <item alpha="255" label="-10" value="-10" color="#2b83ba"/>
          <item alpha="255" label="-8" value="-8" color="#80bfac"/>
          <item alpha="255" label="-6" value="-6" color="#b7e2a8"/>
          <item alpha="255" label="-4" value="-4" color="#cfecb0"/>
          <item alpha="255" label="-2" value="-2" color="#e7f6b8"/>
          <item alpha="255" label="0" value="0" color="#ffffbf"/>
          <item alpha="255" label="2" value="2" color="#ffe8a4"/>
          <item alpha="255" label="4" value="4" color="#fed189"/>
          <item alpha="255" label="6" value="6" color="#feba6e"/>
          <item alpha="255" label="8" value="8" color="#f17c4a"/>
          <item alpha="255" label="10" value="10" color="#d7191c"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeBlue="128" colorizeRed="255" saturation="0" colorizeGreen="128" colorizeOn="0" colorizeStrength="100" grayscaleMode="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
