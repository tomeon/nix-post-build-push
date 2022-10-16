## services.nix-post-build-push.baseDir
Base directory relative to which each queue's <literal>queueDir</literal> will be
created (by default, unless otherwise specified on a per-queue
basis).


*_Type_*:
path


*_Default_*
```
"/var/lib/nix-post-build-push"
```




## services.nix-post-build-push.defaults
Attribute set of defaults applicable to all
<literal>services.nix-post-build-push.queues</literal>, unless overridden.


*_Type_*:
submodule


*_Default_*
```
{}
```




## services.nix-post-build-push.defaults.checkSigs
When false, pass <literal>--no-check-sigs</literal> to <command>nix copy</command>; otherwise,
omit that option.


*_Type_*:
boolean


*_Default_*
```
"true"
```




## services.nix-post-build-push.defaults.closureType
The type of package closure to copy to the destination cache or chroot
store.


*_Type_*:
one of "bare", "binary", "cache", "source"


*_Default_*
```
"binary"
```


*_Example_*
```
"cache"
```


## services.nix-post-build-push.defaults.group
Group for running <command>nix-post-build-push</command>.


*_Type_*:
non-empty string


*_Default_*
```
"root"
```


*_Example_*
```
"mygroup"
```


## services.nix-post-build-push.defaults.interval
<citerefentry><refentrytitle>systemd.time</refentrytitle><manvolnum>7</manvolnum></citerefentry> time span expression used as the value of
<literal>OnUnitActiveSec</literal> in the <citerefentry><refentrytitle>systemd.timer</refentrytitle><manvolnum>5</manvolnum></citerefentry> unit generated for
the <command>nix-post-build-push</command> queue.


*_Type_*:
non-empty string


*_Default_*
```
"10m"
```


*_Example_*
```
"1 hour"
```


## services.nix-post-build-push.defaults.nixOpts
List of command-line options to pass to the <command>nix</command> executable
when running, e.g., <command>nix copy</command>.


*_Type_*:
list of string


*_Default_*
```
"[]"
```


*_Example_*
```
["--netrc-file","/run/my/secrets/netrc"]
```


## services.nix-post-build-push.defaults.package
Package providing the <command>nix-post-build-push</command> executable.


*_Type_*:
package


*_Default_*
```
"pkgs.nix-post-build-push"
```




## services.nix-post-build-push.defaults.persistentTimer
Value for <literal>Persistent</literal> in the <citerefentry><refentrytitle>systemd.timer</refentrytitle><manvolnum>5</manvolnum></citerefentry> unit
generated for the <command>nix-post-build-push</command> queue.

When set to <literal>true</literal>, the corresponding service unit "will be triggered
immediately if it would have been triggered at least one during the
time when the timer was inactive".


*_Type_*:
boolean


*_Default_*
```
"false"
```




## services.nix-post-build-push.defaults.randomizedDelaySec
<citerefentry><refentrytitle>systemd.time</refentrytitle><manvolnum>7</manvolnum></citerefentry> time span expression used as the value of
<literal>RandomizedDelaySec</literal> in the <citerefentry><refentrytitle>systemd.timer</refentrytitle><manvolnum>5</manvolnum></citerefentry> unit generated
for the <command>nix-post-build-push</command> queue.


*_Type_*:
non-empty string


*_Default_*
```
"0"
```


*_Example_*
```
"1m"
```


## services.nix-post-build-push.defaults.substituteOnDestination
When true, pass <literal>--substitute-on-destination</literal> to <command>nix copy</command>;
otherwise, omit that option.


*_Type_*:
boolean


*_Default_*
```
"false"
```




## services.nix-post-build-push.defaults.user
User account for running <command>nix-post-build-push</command>.


*_Type_*:
non-empty string


*_Default_*
```
"root"
```


*_Example_*
```
"myuser"
```


## services.nix-post-build-push.defaults.xargsBin
Path to the <command>xargs</command> executable.


*_Type_*:
path


*_Default_*
```
"${lib.getBin pkgs.findutils}/bin/xargs"
```




## services.nix-post-build-push.hook
Options related to the <literal>post-build-hook</literal> Nix configuration setting.


*_Type_*:
submodule


*_Default_*
```
{}
```




## services.nix-post-build-push.hook.enable
Whether to set the <command>nix-post-build-push</command> hook script
as the value of the <literal>post-build-hook</literal> Nix configuration
setting.


*_Type_*:
boolean


*_Default_*
```
true
```




## services.nix-post-build-push.hook.priority
Option priority for this module to use when setting
<literal>nix.settings.post-build-hook</literal> to
<literal>services.nix-post-build-push.hook.script</literal>.


*_Type_*:
signed integer


*_Default_*
```
"lib.modules.defaultPriority"
```


*_Example_*
```
1000
```


## services.nix-post-build-push.hook.script
Script suitable for use as <literal>post-build-hook</literal> in the Nix
configuration file.

<emphasis role="strong">NOTE</emphasis>: this option is not meant to be set by end users.  It
exists in case you want to define your own <literal>post-build-hook</literal>
and call this script from within it.


*_Type_*:
package






## services.nix-post-build-push.queues
Attribute set of <command>nix-post-build-push</command> queues.


*_Type_*:
attribute set of (submodule)


*_Default_*
```
{}
```




## services.nix-post-build-push.queues.\<name\>.checkSigs
When false, pass <literal>--no-check-sigs</literal> to <command>nix copy</command>; otherwise,
omit that option.


*_Type_*:
boolean


*_Default_*
```
"true"
```




## services.nix-post-build-push.queues.\<name\>.closureType
The type of package closure to copy to the destination cache or chroot
store.


*_Type_*:
one of "bare", "binary", "cache", "source"


*_Default_*
```
"binary"
```


*_Example_*
```
"cache"
```


## services.nix-post-build-push.queues.\<name\>.destination
The URL of the target cache or the path of the target chroot
store.

This is where <command>nix-post-build-push</command> will copy queued
packages.

Supports reading the URL or path from a file


*_Type_*:
(attribute set containing `{ _secret = <fully-qualified-path>; }`) or string matching the pattern .*://.* or (path)




*_Example_*
```
{"_secret":"/run/my/secrets/cache-url"}
```


## services.nix-post-build-push.queues.\<name\>.enable
Enable the <command>nix-post-build-push</command> Nix <literal>post-build-hook</literal>
command.


*_Type_*:
boolean


*_Default_*
```
true
```




## services.nix-post-build-push.queues.\<name\>.group
Group for running <command>nix-post-build-push</command>.


*_Type_*:
non-empty string


*_Default_*
```
"root"
```


*_Example_*
```
"mygroup"
```


## services.nix-post-build-push.queues.\<name\>.interval
<citerefentry><refentrytitle>systemd.time</refentrytitle><manvolnum>7</manvolnum></citerefentry> time span expression used as the value of
<literal>OnUnitActiveSec</literal> in the <citerefentry><refentrytitle>systemd.timer</refentrytitle><manvolnum>5</manvolnum></citerefentry> unit generated for
the <command>nix-post-build-push</command> queue.


*_Type_*:
non-empty string


*_Default_*
```
"10m"
```


*_Example_*
```
"1 hour"
```


## services.nix-post-build-push.queues.\<name\>.name
Arbitrary name to associate with this
<command>nix-post-build-push</command> queue.


*_Type_*:
string


*_Default_*
```
"<name>"
```




## services.nix-post-build-push.queues.\<name\>.nixOpts
List of command-line options to pass to the <command>nix</command> executable
when running, e.g., <command>nix copy</command>.


*_Type_*:
list of string


*_Default_*
```
"[]"
```


*_Example_*
```
["--netrc-file","/run/my/secrets/netrc"]
```


## services.nix-post-build-push.queues.\<name\>.package
Package providing the <command>nix-post-build-push</command> executable.


*_Type_*:
package


*_Default_*
```
"pkgs.nix-post-build-push"
```




## services.nix-post-build-push.queues.\<name\>.persistentTimer
Value for <literal>Persistent</literal> in the <citerefentry><refentrytitle>systemd.timer</refentrytitle><manvolnum>5</manvolnum></citerefentry> unit
generated for the <command>nix-post-build-push</command> queue.

When set to <literal>true</literal>, the corresponding service unit "will be triggered
immediately if it would have been triggered at least one during the
time when the timer was inactive".


*_Type_*:
boolean


*_Default_*
```
"false"
```




## services.nix-post-build-push.queues.\<name\>.queueDir
Path to the directory that <command>nix-post-build-push</command>
should use for managing its queue of symbolic links to store
paths.


*_Type_*:
path


*_Default_*
```
"/var/lib/nix-post-build-push/‹name›"
```


*_Example_*
```
"/var/spool/my/queue"
```


## services.nix-post-build-push.queues.\<name\>.randomizedDelaySec
<citerefentry><refentrytitle>systemd.time</refentrytitle><manvolnum>7</manvolnum></citerefentry> time span expression used as the value of
<literal>RandomizedDelaySec</literal> in the <citerefentry><refentrytitle>systemd.timer</refentrytitle><manvolnum>5</manvolnum></citerefentry> unit generated
for the <command>nix-post-build-push</command> queue.


*_Type_*:
non-empty string


*_Default_*
```
"0"
```


*_Example_*
```
"1m"
```


## services.nix-post-build-push.queues.\<name\>.serviceName
Name of the systemd service associated with this queue.

<emphasis role="strong">NOTE</emphasis>: this option is not meant to be set by end users.
It exists in case you want to modify the service definition:
rather than writing
<literal>systemd.services.&lt;literal-service-name&gt;</literal>, you can instead
write
<literal>systemd.services.${config.nix-post-build-push.queues.myqueue.serviceName}</literal>.


*_Type_*:
non-empty string






## services.nix-post-build-push.queues.\<name\>.substituteOnDestination
When true, pass <literal>--substitute-on-destination</literal> to <command>nix copy</command>;
otherwise, omit that option.


*_Type_*:
boolean


*_Default_*
```
"false"
```




## services.nix-post-build-push.queues.\<name\>.timerName
Name of the systemd timer associated with this queue.

<emphasis role="strong">NOTE</emphasis>: this option is not meant to be set by end users.
It exists in case you want to modify the timer definition:
rather than writing <literal>systemd.timers.&lt;literal-timer-name&gt;</literal>,
you can instead write
<literal>systemd.timers.${config.nix-post-build-push.queues.myqueue.timerName}</literal>.


*_Type_*:
non-empty string






## services.nix-post-build-push.queues.\<name\>.user
User account for running <command>nix-post-build-push</command>.


*_Type_*:
non-empty string


*_Default_*
```
"root"
```


*_Example_*
```
"myuser"
```


## services.nix-post-build-push.queues.\<name\>.xargsBin
Path to the <command>xargs</command> executable.


*_Type_*:
path


*_Default_*
```
"${lib.getBin pkgs.findutils}/bin/xargs"
```




