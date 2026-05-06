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
    
    <!-- Functions -->
    <xsl:import href="functions.xsl"/>
    
    <!-- XML property normalisation -->
    <xsl:include href="normalise-xmlproperties.xsl"/>
    
    <!-- Default target for build -->
    <xsl:variable name="default" select="/*/@default" as="xs:string?"/>
    
    
    <xsl:param name="env.date" select="'20260506155549'" as="xs:string?"/>
    <xsl:param name="current.time" select="'194350'" as="xs:string?"/>
    
    <xsl:param name="initial-target" select="$default" as="xs:string?"/>
    <xsl:param name="mm-targetpath" select="'file:///home/ari/Documents/repos/ant-visualiser/tmp/'"/>
    
    <xsl:param name="taskdef-colour" select="'#666600'"/>
    <xsl:param name="import-colour" select="'#678900'"/>
    <xsl:param name="xmlproperty-colour" select="'#3333ff'"/>
    <xsl:param name="property-colour" select="'#999999'"/>
    
    <xsl:variable name="base-uri" select="base-uri(/)"/>
    <xsl:variable name="filename" select="tokenize($base-uri, '/')[last()]"/>
    <xsl:variable name="base-path" select="substring-before($base-uri, $filename)"/>
    
    <xsl:variable name="context" select="/"/>
    
    
    <xsl:variable name="property-files">
        <xmlproperty-files>
            <xsl:variable name="all-imported-docs" select="sg:collect-properties(/, $base-path, ())"/>
            
            <xsl:for-each select="$all-imported-docs//xmlproperty">
                <xsl:variable name="current" select="$base-path || @file"/>
                <xsl:if test="doc-available($current)">
                    <xsl:copy-of select="doc($current)"/>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="$all-imported-docs//property">
                <xsl:choose>
                    <xsl:when test="@file">
                        <xsl:variable name="prop-file" select="$base-path || @file"/>
                        <xsl:if test="doc-available($prop-file)">
                            <xsl:copy-of select="doc($prop-file)"/>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="@name and @value">
                        <property name="{@name}" value="{@value}"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
            
            <xsl:for-each select="$all-imported-docs//local">
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </xmlproperty-files>
    </xsl:variable>
    
    
    <xsl:variable name="normalised">
        <xsl:apply-templates select="$property-files" mode="props"/>
    </xsl:variable>
    
    
    <xsl:template match="/*">
        <xsl:variable name="mm" as="element()">
            <map version="freeplane 1.12.1">
                <bookmarks>
                    <bookmark nodeId="ID_1090958577" name="Root" opensAsRoot="true"/>
                </bookmarks>
                <!-- Build file root -->
                <node TEXT="{$filename || ' - ' || @name}">
                    <!-- Style -->
                    <xsl:copy-of select="doc('../styles/dark-solarized.xml')/ext-style/*"/>
                    
                    <xsl:apply-templates select="taskdef | import | xmlproperty | property | target">
                        <xsl:with-param name="context" select="." tunnel="yes"/>
                    </xsl:apply-templates>
                </node>
                
                <xsl:copy-of select="$normalised"/>
            </map>
        </xsl:variable>
        
        <!--<xsl:result-document href="{$mm-targetpath || replace($filename, '\.xml', '.mm')}">-->
            <xsl:copy-of select="$mm"/>
        <!--</xsl:result-document>-->
    </xsl:template>
    
    
    <xsl:template match="property">
        <node TEXT="{name(.) || ' - ' || @name || '=' || @value}" BACKGROUND_COLOR="{$property-colour}"/>
    </xsl:template>
    
    <xsl:template match="xmlproperty">
        <node TEXT="{name(.) || ' - ' || @file}" BACKGROUND_COLOR="{$xmlproperty-colour}">
            <xsl:apply-templates select="node()"/>
        </node>
    </xsl:template>
    
    
    <xsl:template match="taskdef">
        <node TEXT="{name(.) || ' - ' || @resource}" BACKGROUND_COLOR="{$taskdef-colour}">
            <xsl:apply-templates select="node()"/>
        </node>
    </xsl:template>
    
    
    <xsl:template match="import">
        <node TEXT="{name(.) || ' - ' || @file}" BACKGROUND_COLOR="{$import-colour}">
            <!-- Put the resolved path in a tooltip or other mindmap documentation node -->
            
            <!-- We import project files, so we need to look at the project element's children -->
            <xsl:apply-templates select="doc(sg:resolve-string(@file, $normalised))/*/*"/>
        </node>
    </xsl:template>
    
    
    <xsl:template match="target">
        <xsl:param name="context" tunnel="yes"/>
        <xsl:variable name="target" select="@name"/>
        <xsl:variable name="depends" select="tokenize(@depends, ',[\s*]')"/>
        <xsl:variable name="default-label" select="if ($target = $default) then (' (default)') else ('')"/>
        
        <node TEXT="{name(.) || ' - ' || $target || $default-label}">
            <xsl:apply-templates select="@description"/>
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
    
    
    <xsl:template match="@description">
        <richcontent TYPE="NOTE">
            <html>
                <head/>
                <body>
                    <p>{.}</p>
                </body>
            </html></richcontent>
    </xsl:template>
    
    
    <xsl:template match="ant[ancestor::target]">
        <node TEXT="{name(.) || ' - ' || @antfile || ' ' || @target}"/>
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