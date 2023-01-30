<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.18.0-Zürich" styleCategories="AllStyleCategories" minScale="1e+8" maxScale="0" hasScaleBasedVisibilityFlag="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
    <Private>0</Private>
  </flags>
  <temporal fetchMode="0" enabled="0" mode="0">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <customproperties>
    <property key="WMSBackgroundLayer" value="false"/>
    <property key="WMSPublishDataSourceUrl" value="false"/>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="identify/format" value="Value"/>
  </customproperties>
  <pipe>
    <provider>
      <resampling maxOversampling="2" zoomedInResamplingMethod="nearestNeighbour" enabled="false" zoomedOutResamplingMethod="nearestNeighbour"/>
    </provider>
    <rasterrenderer opacity="1" nodataColor="" classificationMax="49" classificationMin="22" band="1" type="singlebandpseudocolor" alphaBand="-1">
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
        <colorrampshader maximumValue="49" colorRampType="INTERPOLATED" minimumValue="22" classificationMode="1" labelPrecision="0" clip="0">
          <colorramp name="[source]" type="cpt-city">
            <Option type="Map">
              <Option name="inverted" type="QString" value="1"/>
              <Option name="rampType" type="QString" value="cpt-city"/>
              <Option name="schemeName" type="QString" value="wkp/tubs/nrwc"/>
              <Option name="variantName" type="QString" value=""/>
            </Option>
            <prop v="1" k="inverted"/>
            <prop v="cpt-city" k="rampType"/>
            <prop v="wkp/tubs/nrwc" k="schemeName"/>
            <prop v="" k="variantName"/>
          </colorramp>
          <item label="22" color="#d77f3f" value="22" alpha="255"/>
          <item label="25" color="#b0783a" value="24.7" alpha="255"/>
          <item label="27" color="#c7a75c" value="27.4" alpha="255"/>
          <item label="30" color="#e7d57a" value="30.1" alpha="255"/>
          <item label="33" color="#a5ba6f" value="32.8" alpha="255"/>
          <item label="36" color="#6ca363" value="35.5" alpha="255"/>
          <item label="38" color="#3e8a59" value="38.2" alpha="255"/>
          <item label="41" color="#346945" value="40.9" alpha="255"/>
          <item label="44" color="#183e29" value="43.6" alpha="255"/>
          <item label="46" color="#373724" value="46.3" alpha="255"/>
          <item label="49" color="#050603" value="49" alpha="255"/>
          <rampLegendSettings direction="0" maximumLabel="" suffix="" prefix="" orientation="2" minimumLabel="">
            <numericFormat id="basic">
              <Option type="Map">
                <Option name="decimal_separator" type="QChar" value=""/>
                <Option name="decimals" type="int" value="6"/>
                <Option name="rounding_type" type="int" value="0"/>
                <Option name="show_plus" type="bool" value="false"/>
                <Option name="show_thousand_separator" type="bool" value="true"/>
                <Option name="show_trailing_zeros" type="bool" value="false"/>
                <Option name="thousand_separator" type="QChar" value=""/>
              </Option>
            </numericFormat>
          </rampLegendSettings>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0" gamma="1"/>
    <huesaturation colorizeRed="255" colorizeStrength="100" colorizeBlue="128" saturation="0" grayscaleMode="0" colorizeGreen="128" colorizeOn="0"/>
    <rasterresampler maxOversampling="2"/>
    <resamplingStage>resamplingFilter</resamplingStage>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
