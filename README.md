# README

This is a simple visualiser for Ant build files. It produces a representation of a modularised Ant build file as a mind map, intended for FreePlane. The reason for its existence is a client of mine with some very complicated and heavily modularised Ant files.


## Prerequisites

You'll require an XSLT 3.0 processor such as Saxon 12.x. For viewing, you'll need [FreePlane](https://github.com/freeplane/freeplane). I've been using version 1.12.1; earlier versions may or may not work as expected.


## Running

Currently, you're simply running an XSLT 3.0 stylesheet. If you have oXygen installed, just open the XSLT and create a transformation scenario. If not, open your IDE of choice or run the XSLT from the command line.

* The transformation target, i.e. input file, is the Ant build file you are interested in.
* You currently have these parameters:
	* `$initial-target` is used to configure the transform:
		* 'ALL' will show you *all targets* in the build, even if they aren't used.
		* 'DEFAULT' will show you the default target and its dependencies, IF set in `/project/@default`.
		* '' (empty string) will show the default target, if one exists.
		* <TARGET_NAME> shows the specified target.
		* 'USED' will show targets in use. Not implemented yet.
	* `$mm-targetpath` is the location of the target folder where the resulting mind map is saved, including a trailing '/', and defaults to the location of the input build file. This is a URL, mind, and I currently have no idea what will happen with Windows paths (I've developed the XSLT on Linux). 


## Configuring

Most Ant elements are handled using a generic element match that looks like this:

```XML
<!-- Generic tasks/components, as defined in config -->
<xsl:template match="*[local-name() = $tasks]">
    <node TEXT="{name(.)}" BACKGROUND_COLOR="{sg:get-colour($config, name(.))}" ID="{sg:generate-id(.)}">
        <xsl:sequence select="sg:created-modified()"/>
        <xsl:call-template name="info"/>
        <xsl:apply-templates select="node()"/>
    </node>
</xsl:template>
```

`$tasks` is defined thusly:

```XML
<!-- Sequence of task/component names -->
<xsl:variable
    name="tasks" 
    select="$config//group[not(@generic)]/@components 
    => string-join(' ') 
    => tokenize('\s+')" />
```

`$config`, `xslt/config.xml`, looks like this:

```XML
<?xml version="1.0" encoding="UTF-8"?>
<config>
    <groups>
        <group name="taskdef" components="taskdef" generic="false">
            <colour value="#666600"/>
        </group>
        <group name="task-file-operations" components="copy move mkdir loadresource loadfile">
            <colour value="#008000"/>
        </group>
        <group name="task-fileset" components="fileset include exclude filelist path filterchain tokenfilter filetokenizer">
            <colour value="#228B22"/>
        </group>
        <group name="task-string" components="replaceregexp propertyregex concat replacestring">
            <colour value="#FFD700"/>
        </group>
        <group name="task-exec" components="exec arg">
            <colour value="#000080"/>
        </group>
        <group name="local" components="local propertyresource">
            <colour value="#2F4F4F"/>
        </group>
        <group name="control" components="if isset equals then else condition not">
            <colour value="#B22222"/>
        </group>
        <group name="admin" components="record">
            <colour value="#D8BFD8"/>
        </group>
        <group name="import" components="import" generic="false">
            <colour value="#678900"/>
        </group>
        <group name="xmlproperty" components="xmlproperty" generic="false">
            <colour value="#3333ff"/>
        </group>
        <group name="property" components="property" generic="false">
            <colour value="#999999"/>
        </group>
    </groups>
</config>
```

This means that we can easily add to the matched elements by adding the element name(s) to the config's `group/@components` whitespace-separated lists. The groups are split into types depending on function, but currently there's no real science behind the approach.


## Bugs

What bugs?

Seriously, though, let me know if you spot weirdness: ari DOT nordstrom AT gmail.com.
