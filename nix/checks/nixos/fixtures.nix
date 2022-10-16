let
  writeSelf = name:
    derivation {
      inherit name;
      system = "x86_64-linux";
      builder = "/bin/sh";
      args = [
        "-c"
        ''
          echo "$name" > "$out"
        ''
      ];
    };
in
  builtins.listToAttrs (map (name: {
    inherit name;
    value = writeSelf name;
  }) ["foo" "bar" "baz" "quux" "qaz" "qof"])
