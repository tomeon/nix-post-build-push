{call, ...}: let
  nixos = call ./nixos;
in {
  inherit nixos;
}
