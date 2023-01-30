<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis hasScaleBasedVisibilityFlag="0" version="3.0.0-Girona" maxScale="0" minScale="1e+08">
  <pipe>
    <rasterrenderer classificationMax="15" type="singlebandpseudocolor" classificationMin="0" alphaBand="-1" opacity="0.56" band="1">
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
        <colorrampshader clip="0" colorRampType="INTERPOLATED" classificationMode="1">
          <colorramp type="random" name="[source]">
            <prop k="count" v="16"/>
            <prop k="hueMax" v="359"/>
            <prop k="hueMin" v="0"/>
            <prop k="rampType" v="random"/>
            <prop k="satMax" v="240"/>
            <prop k="satMin" v="100"/>
            <prop k="valMax" v="240"/>
            <prop k="valMin" v="250"/>
          </colorramp>
          <item color="#ffffff" alpha="255" value="0" label="0"/>
          <item color="#734c00" alpha="255" value="1" label="Steep mountain (rough)"/>
          <item color="#e64c00" alpha="255" value="2" label="Steep mountain (smooth)"/>
          <item color="#a87000" alpha="255" value="3" label="Moderate mountain (rough)"/>
          <item color="#cd8966" alpha="255" value="4" label="Moderate mountain (smooth)"/>
          <item color="#a8a800" alpha="255" value="5" label="Hills (rough in small and large scale)"/>
          <item color="#d7b09e" alpha="255" value="6" label="Hills (smooth in small scale, rough in large scale)"/>
          <item color="#ff00c5" alpha="255" value="7" label="Upper large slope"/>
          <item color="#ffbee8" alpha="255" value="8" label="Middle large slope"/>
          <item color="#ffaa00" alpha="255" value="9" label="Dissected terrace, moderate plateau"/>
          <item color="#9c9c9c" alpha="255" value="10" label="Slope in and around terrace or plateau"/>
          <item color="#ffd37f" alpha="255" value="11" label="Terrace, smooth plateau"/>
          <item color="#ffff00" alpha="255" value="12" label="Alluvial fan, pediment, bajada, pediplain"/>
          <item color="#55ff00" alpha="255" value="13" label="Alluvial plain, pediplain"/>
          <item color="#00c5ff" alpha="255" value="14" label="Alluvial or coasttal plain, pediplain"/>
          <item color="#0070ff" alpha="255" value="15" label="Alluvial or coasttal plain (gentlest), lake plain, playa"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeOn="0" colorizeBlue="128" saturation="0" grayscaleMode="0" colorizeGreen="128" colorizeRed="255" colorizeStrength="100"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
