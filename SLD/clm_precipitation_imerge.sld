<?xml version="1.0" ?>
<sld:StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:sld="http://www.opengis.net/sld">
    <sld:UserLayer>
        <sld:LayerFeatureConstraints>
            <sld:FeatureTypeConstraint/>
        </sld:LayerFeatureConstraints>
        <sld:UserStyle>
            <sld:Name>clm_precipitation_imerge</sld:Name>
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
                            <sld:ColorMapEntry color="#f7fbff" label="0" opacity="1.0" quantity="0"/>
                            <sld:ColorMapEntry color="#deebf7" label="39.4" opacity="1.0" quantity="39.4"/>
                            <sld:ColorMapEntry color="#c6dbef" label="78.8" opacity="1.0" quantity="78.8"/>
                            <sld:ColorMapEntry color="#9ecae1" label="118" opacity="1.0" quantity="118"/>
                            <sld:ColorMapEntry color="#6baed6" label="158" opacity="1.0" quantity="158"/>
                            <sld:ColorMapEntry color="#4292c6" label="197" opacity="1.0" quantity="197"/>
                            <sld:ColorMapEntry color="#2171b5" label="236" opacity="1.0" quantity="236"/>
                            <sld:ColorMapEntry color="#08519c" label="273" opacity="1.0" quantity="273"/>
                            <sld:ColorMapEntry color="#08306b" label="1200" opacity="1.0" quantity="1200"/>
                        </sld:ColorMap>
                    </sld:RasterSymbolizer>
                </sld:Rule>
            </sld:FeatureTypeStyle>
        </sld:UserStyle>
    </sld:UserLayer>
</sld:StyledLayerDescriptor>
