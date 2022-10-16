{
  lib,
  nix,
  perl,
  writers,
}: let
  src = ../../../bin/nix-post-build-push;

  env = perl.withPackages (p:
    with p; [
      nix.perl-bindings
      ClassTiny
      JSONPP
      TextParsewords
    ]);

  docEnv = perl.withPackages (p: [p.PodMarkdown]);

  script = writers.writeBashBin "nix-post-build-push" ''
    exec -a nix-post-build-push ${env}/bin/perl ${src} "$@"
  '';
in
  script.overrideAttrs (oldAttrs: let
    pname = oldAttrs.name;
    version = "0.1.0";
  in {
    inherit pname version;

    name = "${pname}-${version}";

    outputs = (oldAttrs.outputs or ["out"]) ++ ["doc" "man"];

    meta =
      (oldAttrs.meta or {})
      // {
        description = "An asynchronous Nix post-build-hook package uploader";
      };

    passthru =
      (oldAttrs.passthru or {})
      // {
        inherit env;
      };

    buildCommand =
      oldAttrs.buildCommand
      + ''
        mandir=$man/share/man/man1
        mkdir -p "$mandir"
        ${docEnv}/bin/pod2man --name=${lib.toUpper pname} --release="${pname} ${version}" ${src} "''${mandir}/${pname}.1"

        docdir=$doc/share/doc/${pname}
        mkdir -p "$docdir"
        ${docEnv}/bin/pod2markdown ${src} "''${docdir}/${pname}.md"
      '';
  })
