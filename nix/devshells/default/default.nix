{
  system ? builtins.currentSystem,
  inputs ? (import ../..).inputs,
  pkgs ?
    import inputs.nixpkgs {
      inherit system;
      config = {};
      overlays = [];
    },
  ...
}: let
  sourceSetupHooks = pkgs.lib.concatMapStringsSep "\n" (pkg: ''
    if [ -e ${pkg}/nix-support/setup-hook ]; then
      . ${pkg}/nix-support/setup-hook
    fi
  '');
in
  pkgs.devshell.mkShell ({config, ...}: {
    imports = ["${inputs.devshell}/extra/git/hooks.nix"];

    commands = [
      {
        name = "fmt";
        category = "linting";
        help = "Format Nix code in the devshell $PRJ_ROOT";
        command = ''
          ${pkgs.alejandra}/bin/alejandra "$@" "''${PRJ_ROOT?}"
        '';
      }
      {
        package = pkgs.alejandra;
        category = "linting";
      }
      {
        package = pkgs.editorconfig-checker;
        category = "linting";
      }
      {
        name = "mkdoc";
        category = "utilities";
        command = ''
          set -eu

          doc="$(${pkgs.nix}/bin/nix build --print-out-paths --no-link "''${PRJ_ROOT}#nix-post-build-push.doc")"
          cli_src="''${doc}/share/doc/nix-post-build-push/nix-post-build-push.md"
          cli_dest="''${PRJ_ROOT}/CLI.md"
          module_src="$(${pkgs.nix}/bin/nix build --print-out-paths --no-link "''${PRJ_ROOT}#docs")"
          module_dest="''${PRJ_ROOT}/MODULE.md"

          if [ "''${1:-}" = --verify ]; then
            rc=0
            cmp "$cli_src" "$cli_dest" || rc="$?"
            cmp "$module_src" "$module_dest" || rc="$?"
            exit "$rc"
          else
            ${pkgs.coreutils}/bin/cp -f "$cli_src" "$cli_dest"
            ${pkgs.coreutils}/bin/cp -f "$module_src" "$module_dest"
          fi
        '';
      }
      {
        name = "perl";
        category = "utilities";
        help = "nix-post-build-push Perl environment";
        package = pkgs.nix-post-build-push.env;
      }
      {
        name = "nix-post-build-push";
        category = "utilities";
        package = pkgs.nix-post-build-push;
      }
    ];

    devshell.packages = with pkgs; [cacert git];
    devshell.startup.sourceSetupHooks = pkgs.lib.noDepEntry (sourceSetupHooks config.devshell.packages);

    git.hooks = {
      enable = true;
      pre-commit.text = builtins.readFile ./pre-commit.sh;
    };
  })
