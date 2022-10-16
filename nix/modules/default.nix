let
  nix-post-build-push = import ./nix-post-build-push;
in {
  inherit nix-post-build-push;
  default = nix-post-build-push;
}
