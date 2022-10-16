{
  description = "An asynchronous Nix post-build-hook package uploader";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.inputs.flake-utils.follows = "flake-utils";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    overlays = import ./nix/overlays;
  in
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;

        overlays =
          [
            inputs.devshell.overlay
          ]
          ++ (builtins.attrValues overlays);

        config = {};
      };

      eval = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            networking.hostName = "eval";
            boot.isContainer = true;
          }

          self.nixosModules.nix-post-build-push
        ];
      };

      docs = pkgs.nixosOptionsDoc {
        options = eval.options.services.nix-post-build-push;
        warningsAreErrors = true;
      };

      call = path: import path {inherit call inputs pkgs system;};
    in {
      checks = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux (call ./nix/checks);

      devShells = call ./nix/devshells;

      packages = {
        inherit (pkgs) nix-post-build-push;
        default = pkgs.nix-post-build-push;
        docs = docs.optionsCommonMark;
      };
    })
    // {
      nixosModules = import ./nix/modules;
      inherit overlays;
    };
}
