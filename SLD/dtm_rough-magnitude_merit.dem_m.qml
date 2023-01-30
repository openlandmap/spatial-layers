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
    <rasterrenderer band="1" opacity="1" classificationMin="0" alphaBand="-1" type="singlebandpseudocolor" classificationMax="4977">
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
            <prop k="stops" v="0.0195838;230,245,228,255:0.471154;189,85,0,255"/>
          </colorramp>
          <item alpha="255" label="0" value="0" color="#2b83ba"/>
          <item alpha="255" label="497.7" value="497.7" color="#dfd9bc"/>
          <item alpha="255" label="995.4" value="995.4" color="#d6b589"/>
          <item alpha="255" label="1493" value="1493.1" color="#cd9256"/>
          <item alpha="255" label="1991" value="1990.8" color="#c36e24"/>
          <item alpha="255" label="2489" value="2488.5" color="#be5101"/>
          <item alpha="255" label="2986" value="2986.2" color="#c34606"/>
          <item alpha="255" label="3484" value="3483.9" color="#c83b0c"/>
          <item alpha="255" label="3982" value="3981.6" color="#cd2f11"/>
          <item alpha="255" label="4479" value="4479.3" color="#d22416"/>
          <item alpha="255" label="4977" value="4977" color="#d7191c"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeBlue="128" colorizeRed="255" saturation="0" colorizeGreen="128" colorizeOn="0" colorizeStrength="100" grayscaleMode="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
