# `nix-post-build-push`

An asynchronous Nix `post-build-hook` package uploader.

## Usage

`nix-post-build-push` is provided as a Nix flake.

Include it in your flake:

```nix
{
  inputs = {
    nix-post-build-push.url = "path:/home/matt/git/nix/nix-hooks";

    # Optionally, make `nix-post-build-push` follow other flake inputs (note that
    # you may need to adjust the flake input names to reflect those used by your
    # flake):
    nix-post-build-push.inputs.devshell.follows = "devshell";
    nix-post-build-push.inputs.flake-utils.follows = "flake-utils";
    nix-post-build-push.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then include the `nix-post-build-push` overlay and NixOS module in one or more
NixOS configurations, and configure the module to your liking:

```nix
{
  outputs = { nixpkgs, nix-post-build-push, ... }: {
    nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-post-build-push.nixosModules.nix-post-build-push

        {
          # nix-post-build-push does not (currently) support configurations
          # where `nix.enable = false;`.
          nix.enable = true;

          nixpkgs.overlays = [
            nix-post-build-push.overlays.nix-post-build-push
          ];

          services.nix-post-build-push = {
            defaults.closureType = "cache";
            queues.main = {
              destination = "ssh://my.cache.server";
              interval = "5 min";
            };
          };
        }
      ];
    };
  };
}
```

## How it works

`nix-post-build-push` manages a queue of symbolic links to Nix store paths.
Each of these links is registered as an indirect garbage collector root.

When a Nix build completes, `nix-post-build-push` adds a symbolic link to its
queue for each store path specified in the `OUT_PATHS` environment variable.

Later, `nix-post-build-push` takes the closure of the store paths linked from
its queue and copies it to a binary cache or chroot store (via `nix copy`).

Because creating some symbolic links is quick relative to (say) synchronously
copying the closure of `OUT_PATHS` to a binary cache or chroot store,
`nix-post-build-push` doesn't block the Nix build loop for overly long.

## NixOS module options

Please see [MODULE.md](MODULE.md).

## `nix-post-build-push` CLI usage

Please see [CLI.md](CLI.md).
