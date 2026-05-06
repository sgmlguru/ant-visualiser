<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:sg="urn:x-sgmlguru:ns:xslt"
    exclude-result-prefixes="#all"
    version="3.0">
    
    
    <xsl:function name="sg:parse-property">
        <xsl:param name="property-value"/>
        <!--<xsl:param name="properties"/>-->
        
        <xsl:variable name="property-components">
            <xsl:copy-of select="analyze-string($property-value, '\$\{([^\}]+)*\}')"/>
        </xsl:variable>
        <xsl:copy-of select="$property-components"/>
    </xsl:function>
    
    
    <xsl:function name="sg:resolve-string">
        <xsl:param name="string"/>
        <xsl:param name="properties"/>
        
        <xsl:variable name="tokenised" select="analyze-string($string, '\$\{[^}]+\}')" as="element()"/>
        
        <xsl:variable name="resolve">
            <xsl:for-each select="$tokenised/*">
                <xsl:choose>
                    <xsl:when test="local-name(.) = 'match'">
                        <xsl:variable name="str" select="."/>
                        <xsl:value-of select="$properties//property[@path = sg:get-property-name($str)][1]/@value"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:copy-of select="$resolve"/>
    </xsl:function>
    
    
    <xsl:function name="sg:get-property-name">
        <xsl:param name="string" as="xs:string"/>
        
        <xsl:value-of select="translate($string, '${}', '')"/>
    </xsl:function>
    
</xsl:stylesheet>