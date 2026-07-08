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
    
    <!-- Static path -->
    <xsl:variable
        name="xslt-path"
        select="substring-before(fn:static-base-uri(), tokenize(fn:static-base-uri(), '/')[last()])"/>
    
    <!-- Config file -->
    <xsl:param name="config-file" select="$xslt-path || 'config.xml'"/>
    
    <!-- Config -->
    <xsl:variable name="config" select="doc($config-file)" as="document-node()"/>
    
    <!-- Sequence of task/component names -->
    <xsl:variable
        name="tasks" 
        select="$config//group[not(@generic)]/@components 
        => string-join(' ') 
        => tokenize('\s+')" />
    
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
    
    
    <!-- Macros list -->
    <xsl:variable name="macros">
        
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
                    
                    <xsl:apply-templates select="taskdef | include | import | xmlproperty | property | target">
                        <xsl:with-param name="context" select="." tunnel="yes"/>
                    </xsl:apply-templates>
                    
                    <!-- Normalised properties go here for now -->
                    <node TEXT="Properties" POSITION="top_or_left" ID="{sg:generate-id(.)}">
                        <xsl:apply-templates select="$normalised" mode="annotated"/>
                        
                        <!--<debug content="normalised">
                            <xsl:copy-of select="$normalised"/>
                        </debug>-->
                    </node>
                </node>
            </map>
        </xsl:variable>
        
        <xsl:message>Save to {$mm-targetpath || replace($filename, '\.xml', '.mm')}</xsl:message>
        
        <xsl:result-document href="{$mm-targetpath || replace($filename, '\.xml', '.mm')}">
            <xsl:copy-of select="$mm"/>
        </xsl:result-document>
    </xsl:template>
    
    
    <xsl:template match="property">
        <node TEXT="{name(.) || ' - ' || @name || '=' || @value}" BACKGROUND_COLOR="{sg:get-colour($config, name(.))}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
        </node>
    </xsl:template>
    
    <xsl:template match="xmlproperty">
        <node TEXT="{name(.) || ' - ' || @file}" BACKGROUND_COLOR="{sg:get-colour($config, name(.))}" ID="{sg:generate-id(.)}">
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
    
    
    <xsl:template match="taskdef" priority="10">
        <node TEXT="{name(.) || ' - ' || @resource}" BACKGROUND_COLOR="{sg:get-colour($config, name(.))}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <xsl:choose>
                <xsl:when test="fn:doc-available(sg:resolve-string(@resource, $normalised))">
                    <xsl:apply-templates select="doc(sg:resolve-string(@resource, $normalised))/*/*"/>
                </xsl:when>
                <xsl:otherwise>
                    <node TEXT="{sg:resolve-string(@resource, $normalised)}"/>
                </xsl:otherwise>
            </xsl:choose>
        </node>
    </xsl:template>
    
    
    <xsl:template match="import | include" priority="10">
        <node TEXT="{name(.) || ' - ' || @file}" BACKGROUND_COLOR="{sg:get-colour($config, name(.))}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            
            <!-- We import project files, so we need to look at the project element's children -->
            <xsl:choose>
                <xsl:when test="fn:doc-available(sg:resolve-string(@file, $normalised))">
                    <xsl:apply-templates select="doc(sg:resolve-string(@file, $normalised))/*/*"/>
                </xsl:when>
                <xsl:otherwise>
                    <node TEXT="{@file || sg:resolve-string(@file, $normalised)}"/>
                </xsl:otherwise>
            </xsl:choose>
        </node>
    </xsl:template>
    
    
    <!-- Macros -->
    <xsl:template match="macrodef" priority="10">
        <node TEXT="{name(.)}" BACKGROUND_COLOR="{sg:get-colour($config, name(.))}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <xsl:call-template name="info"/>
            <xsl:apply-templates select="node()"/>
        </node>
    </xsl:template>
    
    
    <!-- Refactored target -->
    <xsl:template match="target">
        <xsl:param name="context" tunnel="yes"/>
        <xsl:param name="read-default" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:variable name="target" select="@name"/>
        <xsl:variable name="depends" select="tokenize(@depends, ',[\s*]')"/>
        
        <xsl:choose>
            <!-- Show all targets -->
            <xsl:when test="$initial-target = 'ALL'">
                <xsl:call-template name="target-node">
                    <xsl:with-param name="target" select="$target"/>
                    <xsl:with-param name="depends" select="$depends"/>
                </xsl:call-template>
            </xsl:when>
            
            <!-- Initial run for default target -->
            <xsl:when test="@name = $default and ($initial-target = 'DEFAULT' or $initial-target = '') and $default != ''">
                <xsl:call-template name="target-node">
                    <xsl:with-param name="read-default" select="true()" tunnel="yes"/>
                    <xsl:with-param name="target" select="$target"/>
                    <xsl:with-param name="depends" select="$depends"/>
                </xsl:call-template>
            </xsl:when>
            
            <!-- User-named target, initial run -->
            <xsl:when test="@name = $initial-target and $initial-target != ''">
                <xsl:call-template name="target-node">
                    <xsl:with-param name="read-default" select="true()" tunnel="yes"/>
                    <xsl:with-param name="target" select="$target"/>
                    <xsl:with-param name="depends" select="$depends"/>
                </xsl:call-template>
            </xsl:when>
            
            <!-- Any target that isn't a user-named target or default -->
            <xsl:when test="not(matches(@name, $initial-target)) and $initial-target != 'DEFAULT' and $read-default">
                <xsl:call-template name="target-node">
                    <xsl:with-param name="read-default" select="true()" tunnel="yes"/>
                    <xsl:with-param name="target" select="$target"/>
                    <xsl:with-param name="depends" select="$depends"/>
                </xsl:call-template>
            </xsl:when>
            
            <!-- Any target that is not the default, but user-named target is DEFAULT or empty, and default target node has already been processed -->
            <xsl:when test="@name != $default and ($initial-target = 'DEFAULT' or $initial-target = '') and $default != '' and $read-default">
                <xsl:call-template name="target-node">
                    <xsl:with-param name="read-default" select="true()" tunnel="yes"/>
                    <xsl:with-param name="target" select="$target"/>
                    <xsl:with-param name="depends" select="$depends"/>
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>
        
    </xsl:template>
    
    
    <!-- <target> elements -->
    <xsl:template name="target-node">
        <xsl:param name="read-default" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:param name="context" tunnel="yes"/>
        <xsl:param name="target"/>
        <xsl:param name="depends"/>
        
        <xsl:variable name="default-label" select="if ($target = $default) then (' (default)') else ('')"/>
        
        <node TEXT="{name(.) || ' - ' || $target || $default-label}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <xsl:apply-templates select="@description"/>
            
            <!-- Iterate through @depends to get current node's children -->
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
    
    
    <!-- Description on targets -->
    <xsl:template match="@description | @todir">
        <richcontent TYPE="NOTE">
            <html>
                <head/>
                <body>
                    <p>{.}</p>
                </body>
            </html>
        </richcontent>
    </xsl:template>
    
    
    <xsl:template match="ant[ancestor::target]">
        <node TEXT="{name(.) || ' - ' || @antfile || ' ' || @target}" ID="{sg:generate-id(.)}"/>
    </xsl:template>
    
    
    <!-- Generic tasks/components, as defined in config -->
    <xsl:template match="*[local-name() = $tasks]">
        <node TEXT="{name(.)}" BACKGROUND_COLOR="{sg:get-colour($config, name(.))}" ID="{sg:generate-id(.)}">
            <xsl:sequence select="sg:created-modified()"/>
            <xsl:call-template name="info"/>
            <xsl:apply-templates select="node()"/>
        </node>
    </xsl:template>
    
    
    <!-- Attribute value output -->
    <xsl:template name="info">
        <richcontent TYPE="NOTE">
            <html>
                <head/>
                <body>
                    <xsl:apply-templates select="@*" mode="info"/>
                    
                    <!-- If we are looking at <exec> there will be args -->
                    <xsl:if test="arg">
                        <p>
                            <xsl:apply-templates select="fn:string-join(arg/@value, ' ')"/>
                        </p>
                    </xsl:if>
                </body>
            </html>
        </richcontent>
    </xsl:template>
    
    
    <!-- Attribute-based info -->
    <xsl:template match="@*" mode="info">
        <p>{name(.) || '=&quot;' || . || '&quot;'}</p>
    </xsl:template>
    
    
    <xsl:template match="target/foreach">
        <xsl:param name="target" tunnel="yes"/>
        <xsl:variable name="foreach-target" select="@target"/>
        <node TEXT="{name(.) || ' - ' || $foreach-target}" BACKGROUND_COLOR="{sg:get-colour($config, name(.))}" ID="{sg:generate-id(.)}">
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
    <xsl:template match="properties" mode="annotated">
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