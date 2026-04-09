<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:sg="urn:x-sgmlguru:ns:xslt"
    expand-text="yes"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:include href="functions.xsl"/>
    
    
    <xsl:template match="xmlproperty-files">
        <xsl:variable name="total">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates select="node()"/>
            </xsl:copy>
        </xsl:variable>
        
        <xsl:choose>
            <!-- Unresolved property (i.e. ${xxx.yyy} in @value: call template recursively resolving properties -->
            <xsl:when test="exists($total//property[@done = false()])">
                <xsl:call-template name="normalise-properties">
                    <xsl:with-param name="context" select="$total"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Or just output the thing -->
            <xsl:otherwise>
                <xsl:copy-of select="$total"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    
    <!-- The first round of property-flattening from xmlproperty files -->
    <xsl:template match="properties">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select=".//*[@value or @location]"/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- Any xmlproperty with a @value or @location is flattened -->
    <xsl:template match="*[@value or @location]">
        <!-- Read the current value -->
        <xsl:variable
            name="val"
            select="@value | @location"/>
        
        <!-- Redo the xmlproperty hierarchy as a period-separated path -->
        <xsl:variable
            name="path"
            select="string-join(for $x in ancestor-or-self::*[ancestor::properties] return name($x), '.')"/>
        
        <!-- Produce the flattened property -->
        <xsl:variable name="props">
            <property path="{$path}" value="{$val}" done="{if (contains($val, '$')) then (false()) else (true())}"/>
        </xsl:variable>
        
        <xsl:copy-of select="$props"/>
    </xsl:template>
    
    
    <!-- Recursive template -->
    <xsl:template name="normalise-properties">
        <xsl:param name="context"/>
        
        <!-- Read the flattened properties -->
        <xsl:variable name="properties">
            <xsl:apply-templates select="$context//property" mode="recursive"/>
        </xsl:variable>
        
        <!-- Iterate through properties, look up property values from previous set -->
        <xsl:variable name="calculated">
            <root>
                <xsl:for-each select="$properties//property">
                    <xsl:choose>
                        <!-- env.date is an exception -->
                        <xsl:when test="@path = 'env.date'">
                            <property path="env.date" value="ENV-DATE" done="true"/>
                        </xsl:when>
                        
                        <!-- Just copy if there are no more properties to resolve in the value -->
                        <xsl:when test="@done=true()">
                            <xsl:copy-of select="."/>
                        </xsl:when>
                        
                        <!-- If there are properties to resolve -->
                        <xsl:otherwise>
                            <xsl:copy>
                                <xsl:copy-of select="@path"/>
                                
                                <!-- This only does file paths now; needs to be tweaked to do any property combo -->
                                <xsl:variable name="new-value">
                                    <xsl:for-each select="fn:tokenize(@value, '/')">
                                        <xsl:choose>
                                            
                                            <!-- There are unresolved properties left -->
                                            <xsl:when test="contains(., '$')">
                                                <xsl:variable name="prop" select="replace(., '\$\{([^\}]+)\}', '$1')"/>
                                                
                                                <xsl:choose>
                                                    <xsl:when test="$prop = '${current.time}'">
                                                        <xsl:value-of select="'CURRENT-TIME'"/>
                                                    </xsl:when>
                                                    
                                                    <!-- Look up resolved valuea -->
                                                    <xsl:when test="exists($properties//property[@done=true() and @path=$prop][1]/@value)">
                                                        <xsl:value-of
                                                            select="$properties//property[@done=true() and @path=$prop][1]/@value"/>
                                                    </xsl:when>
                                                    
                                                    <!-- Or just copy for next iteration -->
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="."/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        
                                        <xsl:if test="position() != last()">
                                            <xsl:value-of select="'/'"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:variable>
                                
                                <!-- New value -->
                                <xsl:attribute
                                    name="value"
                                    select="$new-value"/>
                                
                                <!-- Is the new value fully resolved? -->
                                <xsl:attribute
                                    name="done"
                                    select="if (contains($new-value, '$')) then (false()) else (true())"/>
                            </xsl:copy>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </root>
        </xsl:variable>
        
        <!-- Output -->
        <xsl:choose>
            <!-- Still unresolved properties left, so recurse -->
            <xsl:when test="exists($calculated//property[@done = false()])">
                <xsl:call-template name="normalise-properties">
                    <xsl:with-param name="context" select="$calculated"/>
                </xsl:call-template>
            </xsl:when>
            
            <!-- Yippe, no unresolved properties -->
            <xsl:otherwise>
                <xsl:copy-of select="$calculated"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="property" mode="recursive">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    
</xsl:stylesheet>