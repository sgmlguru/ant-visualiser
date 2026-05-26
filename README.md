# README

This is a simple visualiser for Ant build files. It produces a representation of a modularised Ant build file as a mind map, intended for FreePlane. The reason for its existence is a client of mine with some very complicated and heavily modularised Ant files.

There's not much to see here yet, though. Come back in a while.


## Prerequisites

You'll require an XSLT 3.0 processor such as Saxon 12.x. For viewing, you'll need [FreePlane](https://github.com/freeplane/freeplane). I've been using version 1.12.1; earlier versions may or may not work as expected.


## Running

Currently, you're simply running an XSLT 3.0 stylesheet. If you have oXygen installed, just open the XSLT and create a transformation scenario. If not, open your IDE of choice or run the XSLT from the command line.

* The transformation target, i.e. input file, is the Ant build file you are interested in.
* You currently have these parameters:
	* `$initial-target` is your initial Ant `target` name. If the build file provides a default target via `@default`, that's what the XSLT will use unless you provide some other target in the build file. Bad things will currently happen if there is no default and you don't provide an initial target.
	* `$mm-targetpath` is just the location of your desired target folder, including a trailing '/'. This is a URL, mind, and I currently have no idea what will happen with Windows paths. 
