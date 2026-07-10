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
    
    
    <xsl:function name="sg:collect-properties" as="document-node()*">
        <xsl:param name="doc" as="document-node()"/>
        <xsl:param name="base-path" as="xs:string"/>
        <xsl:param name="visited-paths" as="xs:string*"/>
        
        <xsl:sequence select="$doc"/>
        
        <xsl:for-each select="$doc//import">
            <xsl:variable name="file-path" select="@file"/>
            <xsl:variable name="resolved-path" select="
                if (contains($file-path, '${')) 
                then $base-path || substring-after(substring-after($file-path, '}'), '/') 
                else $base-path || $file-path"/>
            
            <!-- If we haven't done this path yet -->
            <xsl:if test="doc-available($resolved-path) and not($resolved-path = $visited-paths)">
                <xsl:variable name="imported-doc" select="doc($resolved-path)"/>
                <xsl:variable name="new-base-path" select="substring-before($resolved-path, tokenize($resolved-path, '/')[last()])"/>
                
                <xsl:sequence select="sg:collect-properties($imported-doc, $new-base-path, ($visited-paths, $resolved-path))"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>
    
    
    <xsl:function name="sg:generate-id" as="xs:string">
        <xsl:param name="context"/>
        <xsl:value-of select="'ID_' || fn:generate-id($context)"/>
    </xsl:function>
    
    
    <xsl:function name="sg:created-modified" as="attribute()+">
        <xsl:attribute name="CREATED" select="floor((current-dateTime() - xs:dateTime('1970-01-01T00:00:00Z')) div xs:dayTimeDuration('PT0.001S'))"/>
        <xsl:attribute name="MODIFIED" select="floor((current-dateTime() - xs:dateTime('1970-01-01T00:00:00Z')) div xs:dayTimeDuration('PT0.001S')) + 1000"/>
    </xsl:function>
    
    
    <xsl:function name="sg:get-colour" as="xs:string">
        <xsl:param name="config"/>
        <xsl:param name="name"/>
        
        <xsl:variable name="component-name">
            <xsl:value-of select="$config//group[@components 
                => string-join(' ') 
                => tokenize('\s+') = $name]/colour/@value"/>
        </xsl:variable>
        
        <xsl:variable name="group">
            <xsl:value-of select="$config//group[@name 
                => string-join(' ') 
                => tokenize('\s+') = $name]/colour/@value"/>
        </xsl:variable>
        
        <xsl:choose>
            <!-- Individual component -->
            <xsl:when test="$component-name != ''">
                <xsl:value-of select="$component-name"/>
            </xsl:when>
            <!-- Only component group -->
            <xsl:when test="$group">
                <xsl:value-of select="$group"/>
            </xsl:when>
            <!-- No default -->
            <xsl:otherwise/>
        </xsl:choose>
        
    </xsl:function>
    
    
    <xsl:function name="sg:find-macros" as="xs:string*">
        <xsl:param name="file-paths" as="xs:string*"/>
        <xsl:param name="visited-paths" as="xs:string*"/>
        <xsl:param name="normalised" as="document-node()"/>
        
        <xsl:variable name="files-to-process" select="$file-paths[not(. = $visited-paths)]"/>
        
        <xsl:if test="exists($files-to-process)">
            <xsl:variable name="current-file" select="$files-to-process[1]"/>
            <xsl:variable name="doc" select="doc($current-file)"/>
            <xsl:variable name="local-macros" select="$doc//macrodef/@name/string()"/>
            
            <xsl:variable name="next-files" as="xs:string*">
                <xsl:for-each select="$doc//taskdef[@resource]">
                    <xsl:if test="fn:doc-available(resolve-uri(sg:resolve-string(@resource, $normalised), $current-file))">
                        <xsl:value-of select="resolve-uri(sg:resolve-string(@resource, $normalised), $current-file)"/>
                    </xsl:if>
                    
                </xsl:for-each>
                <xsl:for-each select="$doc//(include | import)[@file]">
                    <xsl:if test="fn:doc-available(resolve-uri(sg:resolve-string(@file, $normalised), $current-file))">
                        <xsl:value-of select="resolve-uri(sg:resolve-string(@file, $normalised), $current-file)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:sequence
                select="$local-macros, 
                sg:find-macros(($files-to-process[position() > 1], $next-files), ($visited-paths, $current-file), $normalised)"/>
        </xsl:if>
    </xsl:function>
    
</xsl:stylesheet>