<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
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
    
    
    <xsl:function name="sg:open-property-files">
        <xsl:param name="context"/>
        
        <xsl:variable name="props">
            <xsl:for-each select="$context//xmlproperty">
                <xsl:copy-of select="doc(@file)"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:copy-of select="$props"/>
    </xsl:function>
    
    
    <xsl:function name="sg:parse-property">
        <xsl:param name="property-value"/>
        <!--<xsl:param name="properties"/>-->
        
        <xsl:variable name="property-components">
            <xsl:copy-of select="analyze-string($property-value, '\$\{([^\}]+)*\}')"/>
        </xsl:variable>
        <xsl:copy-of select="$property-components"/>
    </xsl:function>
    
    
    <xsl:function name="sg:get-path">
        <xsl:param name="string"/>
        <xsl:variable name="tokenised-string" select="fn:tokenize($string, '\.')"/>
        
        <!-- Never mind this; we'll replace it with actual functionality -->
        <xsl:sequence select="$tokenised-string"/>
    </xsl:function>
    
</xsl:stylesheet>