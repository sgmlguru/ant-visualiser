<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    expand-text="yes"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="default" select="/*/@default" as="xs:string?"/>
    
    <xsl:param name="initial-target" select="$default" as="xs:string?"/>
    
    <xsl:variable name="base-uri" select="base-uri(/)"/>
    <xsl:variable name="filename" select="tokenize($base-uri, '/')[last()]"/>
    <xsl:variable name="base-path" select="substring-before($base-uri, $filename)"/>
    
    
    <xsl:template match="/*">
        <map>
            <node TEXT="{$filename || ' - ' || @name}">
                <xsl:apply-templates select="target[@name = $initial-target]">
                    <xsl:with-param name="context" select="." tunnel="yes"/>
                </xsl:apply-templates>
            </node>
        </map>
    </xsl:template>
    
    
    <xsl:template match="xmlproperty">
        <node TEXT="{name(.) || ' - ' || @file}">
            <xsl:apply-templates select="node()"/>
        </node>
    </xsl:template>
    
    
    <xsl:template match="target">
        <xsl:param name="context" tunnel="yes"/>
        <xsl:variable name="target" select="@name"/>
        <xsl:variable name="depends" select="tokenize(@depends, ',[\s*]')"/>
        <xsl:variable name="default-label" select="if ($target = $default) then (' (default)') else ('')"/>
        
        <node TEXT="{name(.) || ' - ' || $target || $default-label}">
            <xsl:for-each select="$depends">
                <xsl:variable name="current-target" select="."/>
                <xsl:apply-templates select="$context//target[@name = $current-target]">
                    <xsl:with-param name="context" select="$context" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each>
            <xsl:apply-templates select="node()">
                <xsl:with-param name="target" select="$target" tunnel="yes"/>
            </xsl:apply-templates>
        </node>
    </xsl:template>
    
    
    <xsl:template match="ant[ancestor::target]">
        <node TEXT="{name(.) || ' - ' || @antfile || ' ' || @target}">
            <xsl:apply-templates select="node()"/>
        </node>
    </xsl:template>
    
    
    <xsl:template match="target/foreach">
        <xsl:param name="target" tunnel="yes"/>
        <xsl:variable name="foreach-target" select="@target"/>
        <node TEXT="{name(.) || ' - ' || $foreach-target}">
            <xsl:apply-templates select="//target[@name = $foreach-target]"/>
        </node>
    </xsl:template>
    
    
    <!-- Remove for now -->
    <xsl:template match="comment() | processing-instruction() | echo"/>
    
</xsl:stylesheet>