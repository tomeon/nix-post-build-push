{
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs) lib;

  destinationFor = queue: "/var/tmp/nix-post-build-push-${queue.name}-chroot";

  common = {
    config,
    lib,
    ...
  }: let
    toplevel = config;
    inherit (toplevel.services.nix-post-build-push) queues;
    destinationFileFor = queue: "nix-post-build-post-${queue.name}-destination";
  in {
    environment.etc =
      lib.mapAttrs' (_: queue: {
        name = destinationFileFor queue;
        value = {
          text = destinationFor queue;
        };
      })
      queues;

    services.nix-post-build-push.queues.main = {config, ...}: {
      # Chroot store, not cache.
      checkSigs = false;

      destination = {
        _secret = "/etc/${toplevel.environment.etc.${destinationFileFor config}.target}";
      };
    };

    systemd.tmpfiles.rules = map (
      queue: "d ${destinationFor queue} 0755 root root - -"
    ) (builtins.attrValues queues);

    systemd.services =
      lib.mapAttrs' (_: queue: let
        destination = destinationFor queue;
      in {
        name = "nix-post-build-push-${queue.name}";
        value = {
          serviceConfig.BindPaths = [
            "${destination}:${destination}"
          ];
        };
      })
      queues;

    nix = {
      settings = {
        #extra-experimental-features = "flakes nix-command";
        substituters = lib.mkForce [];
        trusted-substituters = lib.mkForce [];
      };
    };
  };
in
  pkgs.nixosTest {
    name = "nix-post-build-push";

    nodes = {
      multiuser = {
        lib,
        pkgs,
        ...
      }: {
        imports = [
          inputs.self.nixosModules.nix-post-build-push
          common
        ];

        nix.enable = lib.mkForce true;
      };

      singleuser = {
        config,
        lib,
        pkgs,
        ...
      }: {
        imports = [
          inputs.self.nixosModules.nix-post-build-push
          common
        ];

        environment.systemPackages = [
          # We disable the Nix daemon module, so we need to add this to the
          # system path ourselves.
          config.nix.package.out
        ];

        nix.enable = lib.mkForce false;
      };
    };

    testScript = {nodes, ...}: let
      partitionAttrs = cond: attrs:
        builtins.foldl' (
          out: name: let
            next = attrs.${name};
            merge = res: out // {${res} = out.${res} // {${name} = next;};};
            res =
              if cond name next
              then "right"
              else "wrong";
          in
            merge res
        ) {
          right = {};
          wrong = {};
        } (builtins.attrNames attrs);

      partitioned = partitionAttrs (_: node: node.config.nix.enable) nodes;

      mkNixEnabledScript = name: node: let
        enabledQueues = lib.filterAttrs (_: queue: queue.enable) node.config.services.nix-post-build-push.queues;
        mkDestinationCheck = _: queue: ''
          ${name}.succeed('ls -AlRth ${destinationFor queue} 1>&2')
        '';
        destinationChecks = lib.mapAttrsToList mkDestinationCheck enabledQueues;
      in
        ''
          ${name}.wait_for_unit('nix-daemon.socket')
          ${name}.wait_until_succeeds('nix --extra-experimental-features nix-command store ping 1>&2')

          ${name}.succeed('cat /etc/nix/nix.conf 1>&2')
          ${name}.succeed('grep "post-build-hook.*nix-post-build-push" /etc/nix/nix.conf 1>&2')

          ${name}.succeed('systemctl cat "nix-post-build-push-*" 1>&2')

          ${name}.succeed('nix --extra-experimental-features nix-command build -L -f ${./fixtures.nix} 1>&2')

          ${name}.succeed('ls -AlRth /var/lib/nix-post-build-push 1>&2')

          ${name}.succeed('systemctl start --all "nix-post-build-push-*.service" 1>&2')
        ''
        + (lib.concatStringsSep "\n" destinationChecks);

      mkNixDisabledScript = name: node: ''
        ${name}.wait_until_succeeds('nix --extra-experimental-features nix-command store ping 1>&2')

        ${name}.fail('cat /etc/nix/nix.conf 1>&2')
        ${name}.fail('grep "post-build-hook.*nix-post-build-push" /etc/nix/nix.conf 1>&2')

        ${name}.fail('systemctl cat "nix-post-build-push-*" | grep . 1>&2')
      '';

      nixEnabledScripts = lib.mapAttrsToList mkNixEnabledScript partitioned.right;

      nixDisabledScripts = lib.mapAttrsToList mkNixDisabledScript partitioned.wrong;
    in
      lib.concatStringsSep "\n" (nixEnabledScripts ++ nixDisabledScripts);
  }
