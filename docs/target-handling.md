# Ant Visualiser Target Handling

This is just a write-up of what issue #20 requires.


## `$initial-target` = 'ALL'

This means `xsl:template/match="target[$initial-target = "ALL"]"`, which really just leads to matching every single `target` in an Ant build. I can't see any exceptions.


## `$initial-target` = 'DEFAULT'

We have two outcomes here:

* If `$default != ''`, we match an initial target set by `$default` and then follow the `$depends` targets, recursively. The result needs to be a single target child to the map, leading to anything referenced by it.
* If `$default = ''`, we need to stop processing and tell the user that there is in fact no default target.


## `$initial-target` = 'USED'

This can mean a few things:

* If `$default != ''`, we follow the default (see above). Should we also include anything used by other targets???
* If `$default = ''`, we only use "indirect targets", i.e. targets used by other targets. Not sure this is workable.


## `$initial-target` Is Not Set by User

* Defaults to `$default`, if set.
* Otherwise, defaults to 'ALL'.

