<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:sg="urn:x-sgmlguru:ns:xslt"
    exclude-result-prefixes="#all"
    version="3.0">
    
    
    <xsl:function name="sg:xmlproperties-exist">
        <xsl:param name="context"/>
        
        <xsl:choose>
            <xsl:when test="exists($context//xmlproperty)">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xsl:function name="sg:parse-property">
        <xsl:param name="context"/>
        <xsl:param name="property-value"/>
        
        <xsl:choose>
            <xsl:when test="sg:xmlproperties-exist($context)">
                <xsl:choose>
                    <!-- We have just once Ant property in string (value < 3) -->
                    <xsl:when test="count(tokenize($property-value, '\{')) &lt; 3">
                        
                        <xsl:value-of select="translate($property-value, '${}', '£$%')"/>
                        
                    </xsl:when>
                    
                    <!-- More than one -->
                    <xsl:otherwise></xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>XML Properties do not exist</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
</xsl:stylesheet>