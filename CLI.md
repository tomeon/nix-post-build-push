# NAME

    nix-post-build-push - push Nix build results to a remote cache, asynchronously

# SYNOPSIS

    $ nix-post-build-push [<option> ...] <command> [<nix-option> ...] [-- <store-path-or-out-link> ...]

# ARGUMENTS

Upload store paths:

    $ nix-post-build-push [<option> ...] perform-upload [<nix-option> ...] [-- <store-path-or-out-link> ...]

Enqueue store paths for later upload:

    $ nix-post-build-push [<option> ...] enqueue-paths [<nix-option> ...] [-- <store-path-or-out-link> ...]

Upload queued store paths:

    $ nix-post-build-push [<option> ...] upload-queued-paths [<nix-option> ...]

Display queued paths:

    $ nix-post-build-push [<option> ...] show-queued-paths [<nix-option> ...]

Display the closure of all queued paths:

    $ nix-post-build-push [<option> ...] show-closure [<nix-option> ...]

Show a usage message:

    $ nix-post-build-push [<option> ...] help

Show all `nix-post-build-push` documentation:

    $ nix-post-build-push [<option> ...] doc # or "man", or "perldoc"

Show the `nix-post-build-push` version:

    $ nix-post-build-push [<option> ...] version

# OPTIONS

## --\[no-\]check-sigs

When disabled, pass `--no-check-sigs` to `nix copy`; otherwise, omit
it.

Enabled by default.

## --closure-type {bare,binary,source,cache}

The set of packages to upload to the destination cache or chroot store.

### bare

Not really a closure.  Just the store paths linked from within the queue
directory.

Not fully supported, as `nix copy` copies **closures** by default, and
using `nix copy`'s `--no-recursive` option tends to lead to errors
about "invalid references".

### binary

The closure of the store paths linked from within the queue directory.

`nix-store --query --requisites [<path> ...]`.

### source

The closure of the derivers of the store paths linked from within the queue
directory.

`nix-store --query --deriver [<path> ...] | xargs nix-store --query --requisites`.

### cache

The closure of the derivers of the store paths linked from within the queue
directory, plus the closures of the derivers' output paths.

`nix-store --query --deriver [<path> ...] | xargs nix-store --query --requisites --include-outputs`.

## --config-file &lt;path>

Path to a JSON file containing configuration parameters for
`nix-post-build-push`.

Default is `${XDG_CONFIG_HOME}/nix-post-build-push/nix-post-build-push.json`.

## --destination &lt;url|path>

The URL of the target cache or path of the target chroot store.  Equivalent to
`nix copy`'s `--to` option.

This option is mandatory; there is no default.

## --\[no-\]include-out-paths

When enabled, the `enqueue-paths` command will enqueue the store paths
listed in the `OUT_PATHS` environment variable, as well as whatever paths
were passed as positional parameters to `nix-post-build-push`.

Enabled by default.

## --queue-dir &lt;path>

Path to the directory that `nix-post-build-push` should use for managing
its queue of symbolic links to store paths.

Default is `${XDG_STATE_HOME}/nix-post-build-push`.

## --\[no-\]substitute-on-destination

When enabled, pass `--substitute-on-destination` to `nix copy`;
otherwise, omit it.

Disabled by default.

## --xargs-bin &lt;name|path>

Name of or path to the `xargs` executable.

Default is `xargs`.

## `nix` OPTIONS

All other options are passed through to the `nix` executable.

## FILES

Any arguments appearing after a bare `--` are treated as paths to enqueue
(by `enqueue-paths`) or paths to upload (by `perform-upload`).

# ENVIRONMENT VARIABLES

Options provided as environment variables are higher-precedence than those
defined in the configuration file, but lower-precedence than those defined at
the command line.

## NIX\_POST\_BUILD\_PUSH\_CHECK\_SIGS={0,1}

Equivalent to `--[no-]check-sigs`.

## NIX\_POST\_BUILD\_PUSH\_CLOSURE\_TYPE={bare,binary,source,cache}

Equivalent to `--closure-type`.

## NIX\_POST\_BUILD\_PUSH\_CONFIG\_FILE=&lt;path>

Equivalent to `--config-file`.

## NIX\_POST\_BUILD\_PUSH\_DESTINATION=&lt;url|path>

Equivalent to `--destination`.

## NIX\_POST\_BUILD\_PUSH\_INCLUDE\_OUT\_PATHS={0,1}

Equivalent to `--[no-]include-out-paths`.

## NIX\_POST\_BUILD\_PUSH\_NIX\_OPTS=&lt;string>

Arbitrary options to pass to the `nix` executable.

This value is parsed into a list via [Text::ParseWords](https://metacpan.org/pod/Text%3A%3AParseWords)'s `shellwords`.

## NIX\_POST\_BUILD\_PUSH\_QUEUE\_DIR=&lt;path>

Equivalent to `--queue-dir`.

## NIX\_POST\_BUILD\_PUSH\_SUBSTITUTE\_ON\_DESTINATION={0,1}

Equivalent to `--[no-]substitute-on-destination`.

## NIX\_POST\_BUILD\_PUSH\_XARGS\_BIN=&lt;name|path>

Equivalent to `--xargs-bin`.

# CONFIGURATION FILE

Options provided in the configuration file are lower-precedence than those
defined as environment variables and those defined at the command line.

## check-sigs &lt;bool>

Equivalent to `--[no-]check-sigs`.

## closure-type &lt;string>

Equivalent to `--closure-type`.

## destination &lt;string>

Equivalent to `--destination`.

## include-out-paths &lt;bool>

Equivalent to `--[no-]include-out-paths`.

## nix-opts &lt;list\[string\]>

Equivalent to `NIX_POST_BUILD_PUSH_NIX_OPTS`.

## queue-dir &lt;string>

Equivalent to `--queue-dir`.

## substitute-on-destination &lt;bool>

Equivalent to `--[no-]substitute-on-destination`.

## xargs-bin &lt;string>

Equivalent to `--xargs-bin`.
