{call, ...}: let
  default = call ./default;
in {
  inherit default;
}
