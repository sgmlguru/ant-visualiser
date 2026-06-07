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


## Bugs

What bugs?

Seriously, though, let me know if you spot weirdness: ari DOT nordstrom AT gmail.com.
