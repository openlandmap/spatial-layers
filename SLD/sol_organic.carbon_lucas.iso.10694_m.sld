<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>Soil organic carbon content</sld:Name>
            <sld:Description>OpenLandMap legends</sld:Description>
            <sld:Title/>
            <sld:FeatureTypeStyle>
                <sld:Name/>
                <sld:Rule>
                    <sld:RasterSymbolizer>
                        <sld:Geometry>
                            <ogc:PropertyName>grid</ogc:PropertyName>
                        </sld:Geometry>
                        <sld:Opacity>1</sld:Opacity>
                        <sld:ColorMap>
                            <sld:ColorMapEntry color="#d77f3f" label="8" opacity="1.0" quantity="22"/>
                            <sld:ColorMapEntry color="#b0783a" label="11" opacity="1.0" quantity="24.7"/>
                            <sld:ColorMapEntry color="#c7a75c" label="14" opacity="1.0" quantity="27.4"/>
                            <sld:ColorMapEntry color="#e7d57a" label="19" opacity="1.0" quantity="30.1"/>
                            <sld:ColorMapEntry color="#a5ba6f" label="26" opacity="1.0" quantity="32.8"/>
                            <sld:ColorMapEntry color="#6ca363" label="36" opacity="1.0" quantity="35.5"/>
                            <sld:ColorMapEntry color="#3e8a59" label="44" opacity="1.0" quantity="38.2"/>
                            <sld:ColorMapEntry color="#346945" label="59" opacity="1.0" quantity="40.9"/>
                            <sld:ColorMapEntry color="#183e29" label="80" opacity="1.0" quantity="43.6"/>
                            <sld:ColorMapEntry color="#373724" label="98" opacity="1.0" quantity="46.3"/>
                            <sld:ColorMapEntry color="#050603" label="133" opacity="1.0" quantity="49"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
