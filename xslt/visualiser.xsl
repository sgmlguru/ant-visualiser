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
    
    <xsl:output method="xml" indent="yes" omit-xml-declaration="no"/>
    
    <!-- Functions -->
    <xsl:import href="functions.xsl"/>
    
    <!-- XML property normalisation -->
    <xsl:include href="normalise-xmlproperties.xsl"/>
    
    <!-- Default target for build -->
    <xsl:variable name="default" select="/*/@default" as="xs:string?"/>
    
    <!-- Config -->
    <xsl:variable name="config" select="doc('./config.xml')" as="document-node()"/>
    
    <!-- Ant property hacks -->
    <xsl:param name="env.date" select="'20260506155549'" as="xs:string?"/>
    <xsl:param name="current.time" select="'194350'" as="xs:string?"/>
    
    <!-- User-provided initial target or other config -->
    <xsl:param name="initial-target" as="xs:string?"/>
    
    
    <xsl:variable name="base-uri" select="base-uri(/)"/>
    <xsl:variable name="filename" select="tokenize($base-uri, '/')[last()]"/>
    <xsl:variable name="base-path" select="substring-before($base-uri, $filename)"/>
    
    <!-- The location of the generated mind map -->
    <xsl:param name="mm-targetpath" select="$base-path"/>
    
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
    
    
    <!-- Should contain only resolved properties, if everything went well -->
    <xsl:variable name="normalised">
        <xsl:apply-templates select="$property-files" mode="props"/>
    </xsl:variable>
    
    
    <xsl:template match="/*">
        <xsl:variable name="mm" as="element()">
            <map version="freeplane 1.12.14">
                <xsl:comment>To view this file, download free mind mapping software Freeplane from https://www.freeplane.org</xsl:comment>
                <bookmarks>
                    <bookmark nodeId="{sg:generate-id(.)}" name="Root" opensAsRoot="true"/>
                </bookmarks>
                <!-- Build file root -->
                <node TEXT="{$filename || ' - ' || @name}" ID="{sg:generate-id(.)}">
                    <xsl:sequence select="sg:created-modified()"/>
                    <!-- Style -->
                    <xsl:copy-of select="doc('../styles/dark-solarized.xml')/ext-style/*"/>
                    
                    <xsl:apply-templates select="taskdef | import | xmlproperty | property | target">
                        <xsl:with-param name="context" select="." tunnel="yes"/>
                    </xsl:apply-templates>
                    
                    <!-- Normalised properties go here for now -->
                    <node TEXT="Properties" POSITION="top_or_left" ID="{sg:generate-id(.)}">
                        <xsl:apply-templates select="$normalised" mode="annotated"/>
                        
                        <!--<debug>
                            <xsl:copy-of select="$normalised"/>
                        </debug>-->
                    </node>
                </node>
            </map>
        </xsl:variable>
        
        <!--<xsl:result-document href="{$mm-targetpath || replace($filename, '\.xml', '.mm')}">-->
            <xsl:copy-of select="$mm"/>
        <!--</xsl:result-document>-->
    </xsl:template>
    
    
    <xsl:template match="property">
        <node TEXT="{name(.) || ' - ' || @name || '=' || @value}" BACKGROUND_COLOR="{$config//colour[@name='property']/@value}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
        </node>
    </xsl:template>
    
    <xsl:template match="xmlproperty">
        <node TEXT="{name(.) || ' - ' || @file}" BACKGROUND_COLOR="{$config//colour[@name='xmlproperty']/@value}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            
            <!-- Get the unresolved properties, per xmlproperty file, and convert them to rich content -->
            <xsl:variable name="current" select="$base-path || @file"/>
            <xsl:if test="doc-available($current)">
                <xsl:variable name="xmlproperty-flattened">
                    <xsl:apply-templates select="doc($current)" mode="props"/>
                </xsl:variable>
                <xsl:apply-templates select="$xmlproperty-flattened" mode="annotated"/>
                
                <!--<debug>
                    <xsl:copy-of select="$xmlproperty-flattened"/>
                </debug>-->
            </xsl:if>
        </node>
    </xsl:template>
    
    
    <xsl:template match="taskdef">
        <node TEXT="{name(.) || ' - ' || @resource}" BACKGROUND_COLOR="{$config//colour[@name='taskdef']/@value}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <xsl:apply-templates select="node()"/>
        </node>
    </xsl:template>
    
    
    <xsl:template match="import">
        <node TEXT="{name(.) || ' - ' || @file}" BACKGROUND_COLOR="{$config//colour[@name='import']/@value}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <!-- Put the resolved path in a tooltip or other mindmap documentation node -->
            
            <!-- We import project files, so we need to look at the project element's children -->
            <xsl:apply-templates select="doc(sg:resolve-string(@file, $normalised))/*/*"/>
        </node>
    </xsl:template>
    
    
    <xsl:template match="target[$initial-target = 'ALL']">
        <xsl:param name="context" tunnel="yes"/>
        <xsl:variable name="target" select="@name"/>
        <xsl:variable name="depends" select="tokenize(@depends, ',[\s*]')"/>
        <xsl:variable name="default-label" select="if ($target = $default) then (' (default)') else ('')"/>
        
        <xsl:message>Matched target/@name={@name}</xsl:message>
        
        <xsl:call-template name="target-node">
            <xsl:with-param name="target" select="$target"/>
            <xsl:with-param name="depends" select="$depends"/>
            <xsl:with-param name="default-label" select="$default-label"/>
        </xsl:call-template>
    </xsl:template>
    
    
    <!-- Initial match for default target -->
    <xsl:template match="target[@name = $default and ($initial-target = 'DEFAULT' or $initial-target = '') and $default != '']">
        <xsl:param name="context" tunnel="yes"/>
        <xsl:variable name="target" select="@name"/>
        <xsl:variable name="depends" select="tokenize(@depends, ',[\s*]')"/>
        <xsl:variable name="default-label" select="if ($target = $default) then (' (default)') else ('')"/>
        
        <xsl:message>Matched target/@name={@name}</xsl:message>
        
        <xsl:call-template name="target-node">
            <xsl:with-param name="read-default" select="true()" tunnel="yes"/>
            <xsl:with-param name="target" select="$target"/>
            <xsl:with-param name="depends" select="$depends"/>
            <xsl:with-param name="default-label" select="$default-label"/>
        </xsl:call-template>
    </xsl:template>
    
    
    <!-- Look at a target named by the user, so $initial-target is set -->
    <xsl:template match="target[@name = $initial-target and $initial-target != '']">
        <xsl:param name="context" tunnel="yes"/>
        <xsl:variable name="target" select="@name"/>
        <xsl:variable name="depends" select="tokenize(@depends, ',[\s*]')"/>
        <xsl:variable name="default-label" select="if ($target = $default) then (' (default)') else ('')"/>
        
        <xsl:message>Matched target/@name={@name}</xsl:message>
        
        <xsl:call-template name="target-node">
            <xsl:with-param name="read-default" select="true()" tunnel="yes"/>
            <xsl:with-param name="target" select="$target"/>
            <xsl:with-param name="depends" select="$depends"/>
            <xsl:with-param name="default-label" select="$default-label"/>
        </xsl:call-template>
    </xsl:template>
    
    
    <xsl:template match="target[@name != $initial-target]">
        <xsl:param name="read-default" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="context" tunnel="yes"/>
        <xsl:variable name="target" select="@name"/>
        <xsl:variable name="depends" select="tokenize(@depends, ',[\s*]')"/>
        <xsl:variable name="default-label" select="if ($target = $default) then (' (default)') else ('')"/>
        
        <xsl:message>Matched target/@name={@name}</xsl:message>
        
        <xsl:if test="$read-default">
            <xsl:call-template name="target-node">
                <xsl:with-param name="read-default" select="true()" tunnel="yes"/>
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="depends" select="$depends"/>
                <xsl:with-param name="default-label" select="$default-label"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    
    <!-- Targets handled when initial-target looks at @default -->
    <xsl:template match="target[@name != $default and ($initial-target = 'DEFAULT' or $initial-target = '') and $default != '']">
        <xsl:param name="read-default" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="context" tunnel="yes"/>
        <xsl:variable name="target" select="@name"/>
        <xsl:variable name="depends" select="tokenize(@depends, ',[\s*]')"/>
        <xsl:variable name="default-label" select="if ($target = $default) then (' (default)') else ('')"/>
        
        <xsl:message>Matched target/@name={@name}</xsl:message>
        
        <xsl:if test="$read-default">
            <xsl:call-template name="target-node">
                <xsl:with-param name="read-default" select="true()" tunnel="yes"/>
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="depends" select="$depends"/>
                <xsl:with-param name="default-label" select="$default-label"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    
    <!-- <target> elements -->
    <xsl:template name="target-node">
        <xsl:param name="read-default" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="context" tunnel="yes"/>
        <xsl:param name="target"/>
        <xsl:param name="depends"/>
        <xsl:param name="default-label"/>
        
        <node TEXT="{name(.) || ' - ' || $target || $default-label}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <xsl:apply-templates select="@description"/>
            
            <!-- Iterate through @depends -->
            <xsl:for-each select="$depends">
                <xsl:variable name="current-target" select="."/>
                <xsl:apply-templates select="$context//target[@name = $current-target]">
                    <xsl:with-param name="context" select="$context" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each>
            
            <!-- Current <target> instructions -->
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
        <node TEXT="{name(.) || ' - ' || @antfile || ' ' || @target}" ID="{sg:generate-id(.)}"/>
    </xsl:template>
    
    
    <xsl:template match="target/foreach">
        <xsl:param name="target" tunnel="yes"/>
        <xsl:variable name="foreach-target" select="@target"/>
        <node TEXT="{name(.) || ' - ' || $foreach-target}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <xsl:apply-templates select="//target[@name = $foreach-target]"/>
        </node>
    </xsl:template>
    
    
    <xsl:template match="echo">
        <node TEXT="{name(.)}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <richcontent TYPE="NOTE">
                <html>
                    <head/>
                    <body>
                        <xsl:if test="@message != ''">
                            <p>@message="{@message}"</p>
                        </xsl:if>
                        <xsl:if test="fn:normalize-space(text()) != ''">
                            <p>text()="{string-join(.//text(), ' ')}"</p>
                        </xsl:if>
                    </body>
                </html></richcontent>
        </node>
    </xsl:template>
    
    
    <!-- Remove for now -->
    <xsl:template match="comment() | processing-instruction()"/>
    
    
    <!-- Annotated properties -->
    <xsl:template match="root | properties" mode="annotated">
        <richcontent TYPE="NOTE">
            <html>
                <head>
                    
                </head>
                <body>
                    <table>
                        <thead>
                            <tr>
                                <td>Name/path</td>
                                <td>Value</td>
                                <td>State</td>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:apply-templates select="property" mode="annotated"/>
                        </tbody>
                    </table>
                </body>
            </html>
        </richcontent>
    </xsl:template>
    
    
    <xsl:template match="property" mode="annotated">
        <tr>
            <td>{@path}</td>
            <td>{@value}</td>
            <td>{@done}</td>
        </tr>
    </xsl:template>
    
</xsl:stylesheet>