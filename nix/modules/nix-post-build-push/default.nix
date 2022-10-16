{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.nix-post-build-push;

  inherit (lib) mkOption types;

  exec = "nix-post-build-push";

  nixEnabled = config.nix.enable;
  enabledQueues = lib.filterAttrs (_: queue: queue.enable) cfg.queues;

  # Type representing a secret specification for use with
  # `utils.genJqSecretsReplacementSnippet`.
  secret =
    types.attrs
    // {
      name = "secret";
      description = "attribute set containing `{ _secret = <fully-qualified-path>; }`";
      check = v: (types.attrs.check v) && ((builtins.attrNames v) == ["_secret"]) && (types.path.check v._secret);
    };

  # Type representing an optionally-secret field.
  secretOr = other: types.oneOf ([secret] ++ (lib.toList other));

  # Cannot count on the config file existing when running the `post-build-hook`
  # command, so inline all options except for `destination` (which isn't needed
  # by the `enqueue-paths` stage, and may contain secrets like AWS
  # credentials).
  cmdFor = queue: subcommand: extra:
    [
      "${lib.getBin queue.package}/bin/${exec}"
      "--${lib.optionalString (!queue.checkSigs) "no-"}check-sigs"
      "--closure-type"
      queue.closureType
      "--queue-dir"
      queue.queueDir
      "--${lib.optionalString (!queue.substituteOnDestination) "no-"}substitute-on-destination"
      "--xargs-bin"
      queue.xargsBin
    ]
    ++ extra
    ++ lib.singleton subcommand
    ++ queue.nixOpts;

  hook = pkgs.writers.writeDash exec (lib.concatStringsSep "\n" (lib.mapAttrsToList (_: queue: ''
      printf 1>&2 -- 'enqueuing build results in nix-post-build-push queue "%s" (%s) ...\n' \
        ${lib.escapeShellArgs [queue.name queue.queueDir]}
      ${lib.escapeShellArgs (cmdFor queue "enqueue-paths" [])}
    '')
    enabledQueues));

  services =
    lib.mapAttrs' (_: queue: let
      destinationLooksLikeSecret = secret.check queue.destination;
    in {
      name = queue.serviceName;

      value = {
        description = "nix-post-build-push queue service ${queue.name}";

        script = let
          extra = lib.optionals (!destinationLooksLikeSecret) ["--destination" queue.destination];
        in
          (lib.optionalString destinationLooksLikeSecret ''
            NIX_POST_BUILD_PUSH_DESTINATION="$(< "''${CREDENTIALS_DIRECTORY}/destination")"
            export NIX_POST_BUILD_PUSH_DESTINATION
          '')
          + ''
            exec ${lib.escapeShellArgs (cmdFor queue "upload-queued-paths" extra)}
          '';

        # Don't restart the service when it has changed; let the next firing of the
        # associated timer trigger the newly-reconfigured service.
        restartIfChanged = false;

        serviceConfig =
          {
            Type = "oneshot";

            User = queue.user;
            Group = queue.group;

            # Queue directory needs to be writable
            BindPaths = [
              "${queue.queueDir}:${queue.queueDir}"
            ];

            # Make the upload job very low-priority
            Nice = 19;
            CPUSchedulingPolicy = "idle";
            IOSchedulingClass = "idle";

            # `nix copy` apparently needs the home directory to be writeable,
            # and "tmpfs" doesn't work either.
            ProtectHome = false;

            # Security settings
            DevicePolicy = "closed";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateIPC = true;
            PrivateTmp = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            ProtectSystem = "strict";
            RemoveIPC = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_NETLINK"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              # systemd.exec: "A reasonable set of system calls used by common
              # system services"
              "@system-service"
              # Deny privileged operations
              "~@privileged"
              # Deny attempts to change resource limits (setrlimit,
              # setpriority, ...)
              "~@resources"
              # Allow chown, as apparently something needs this.
              "@chown"
            ];
          }
          // lib.optionalAttrs destinationLooksLikeSecret {
            LoadCredential = ["destination:${toString queue.destination._secret}"];
          };

        unitConfig = {
          # Don't bother running if there is nothing to upload
          ConditionDirectoryNotEmpty = queue.queueDir;
        };
      };
    })
    enabledQueues;

  timers = let
    looksLikeLocal = d: types.str.check d && types.path.check (lib.removePrefix "file://" d);
  in
    lib.mapAttrs' (_: queue: let
      isLocalDestination = looksLikeLocal queue.destination;
    in {
      name = queue.timerName;

      value = {
        description = "nix-post-build-push queue upload timer ${queue.name}";

        wantedBy = ["timers.target"];

        timerConfig = {
          OnUnitActiveSec = queue.interval;
          Persistent = queue.persistentTimer;
          RandomizedDelaySec = queue.randomizedDelaySec;

          # Reuse the randomized offset from `RandomizedDelaySec`.
          FixedRandomDelay = true;
        };

        # If the destination cache or chroot store looks remote, wait for the
        # network to go online before attempting to upload stuff.
        after = lib.optional (queue.persistentTimer && !isLocalDestination) "network-online.target";
      };
    })
    enabledQueues;

  # Have to do this here rather than relying on (say) `StateDirectory` since
  # we may need to enqueue `$OUT_PATHS` before the first time a given
  # `nix-post-build-push-${name}` service runs.
  tmpfilesRules = map (queue: "d ${queue.queueDir} 0755 ${queue.user} ${queue.group} - -") (builtins.attrValues enabledQueues);

  commonOptions = {
    package = mkOption {
      type = types.package;
      defaultText = "pkgs.nix-post-build-push";
      description = lib.mdDoc ''
        Package providing the {command}`nix-post-build-push` executable.
      '';
    };

    user = mkOption {
      type = types.nonEmptyStr;
      defaultText = "root";
      example = "myuser";
      description = lib.mdDoc ''
        User account for running {command}`nix-post-build-push`.
      '';
    };

    group = mkOption {
      type = types.nonEmptyStr;
      defaultText = "root";
      example = "mygroup";
      description = lib.mdDoc ''
        Group for running {command}`nix-post-build-push`.
      '';
    };

    checkSigs = mkOption {
      type = types.bool;
      defaultText = "true";
      description = lib.mdDoc ''
        When false, pass `--no-check-sigs` to {command}`nix copy`; otherwise,
        omit that option.
      '';
    };

    closureType = mkOption {
      type = types.enum ["bare" "binary" "cache" "source"];
      defaultText = "binary";
      example = "cache";
      description = ''
        The type of package closure to copy to the destination cache or chroot
        store.
      '';
    };

    nixOpts = mkOption {
      type = types.listOf types.str;
      defaultText = "[]";
      example = ["--netrc-file" "/run/my/secrets/netrc"];
      description = lib.mdDoc ''
        List of command-line options to pass to the {command}`nix` executable
        when running, e.g., {command}`nix copy`.
      '';
    };

    substituteOnDestination = mkOption {
      type = types.bool;
      defaultText = "false";
      description = lib.mdDoc ''
        When true, pass `--substitute-on-destination` to {command}`nix copy`;
        otherwise, omit that option.
      '';
    };

    xargsBin = mkOption {
      type = types.path;
      defaultText = "\${lib.getBin pkgs.findutils}/bin/xargs";
      description = lib.mdDoc ''
        Path to the {command}`xargs` executable.
      '';
    };

    interval = mkOption {
      type = types.nonEmptyStr;
      example = "1 hour";
      defaultText = "10m";
      description = lib.mdDoc ''
        {manpage}`systemd.time(7)` time span expression used as the value of
        `OnUnitActiveSec` in the {manpage}`systemd.timer(5)` unit generated for
        the {command}`nix-post-build-push` queue.
      '';
    };

    persistentTimer = mkOption {
      type = types.bool;
      defaultText = "false";
      description = lib.mdDoc ''
        Value for `Persistent` in the {manpage}`systemd.timer(5)` unit
        generated for the {command}`nix-post-build-push` queue.

        When set to `true`, the corresponding service unit "will be triggered
        immediately if it would have been triggered at least one during the
        time when the timer was inactive".
      '';
    };

    randomizedDelaySec = mkOption {
      type = types.nonEmptyStr;
      defaultText = "0";
      example = "1m";
      description = lib.mdDoc ''
        {manpage}`systemd.time(7)` time span expression used as the value of
        `RandomizedDelaySec` in the {manpage}`systemd.timer(5)` unit generated
        for the {command}`nix-post-build-push` queue.
      '';
    };
  };
in {
  options = {
    services.nix-post-build-push = {
      baseDir = mkOption {
        type = types.path;
        default = "/var/lib/${exec}";
        description = lib.mdDoc ''
          Base directory relative to which each queue's `queueDir` will be
          created (by default, unless otherwise specified on a per-queue
          basis).
        '';
      };

      hook = mkOption {
        default = {};
        description = lib.mdDoc ''
          Options related to the `post-build-hook` Nix configuration setting.
        '';
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = lib.mdDoc ''
                Whether to set the {command}`nix-post-build-push` hook script
                as the value of the `post-build-hook` Nix configuration
                setting.
              '';
            };

            script = mkOption {
              type = types.package;
              description = lib.mdDoc ''
                Script suitable for use as `post-build-hook` in the Nix
                configuration file.

                **NOTE**: this option is not meant to be set by end users.  It
                exists in case you want to define your own `post-build-hook`
                and call this script from within it.
              '';
            };

            priority = mkOption {
              type = types.int;
              default = lib.modules.defaultPriority;
              defaultText = "lib.modules.defaultPriority";
              example = 1000;
              description = lib.mdDoc ''
                Option priority for this module to use when setting
                `nix.settings.post-build-hook` to
                `services.nix-post-build-push.hook.script`.
              '';
            };
          };
        };
      };

      defaults = mkOption {
        default = {};
        description = lib.mdDoc ''
          Attribute set of defaults applicable to all
          `services.nix-post-build-push.queues`, unless overridden.
        '';
        type = types.submodule {
          options = commonOptions;

          config = lib.mapAttrs (_: lib.mkOptionDefault) {
            package = pkgs.nix-post-build-push;
            user = "root";
            group = "root";
            checkSigs = true;
            closureType = "binary";
            nixOpts = [];
            substituteOnDestination = false;
            xargsBin = "${lib.getBin pkgs.findutils}/bin/xargs";
            interval = "10m";
            persistentTimer = false;
            randomizedDelaySec = "0";
          };
        };
      };

      queues = mkOption {
        default = {};
        description = lib.mdDoc ''
          Attribute set of {command}`nix-post-build-push` queues.
        '';
        type = types.attrsOf (types.submodule ({
          name,
          config,
          ...
        }: {
          options =
            commonOptions
            // {
              enable = lib.mkOption {
                type = types.bool;
                default = true;
                description = lib.mdDoc ''
                  Enable the {command}`nix-post-build-push` Nix `post-build-hook`
                  command.
                '';
              };

              name = mkOption {
                type = types.str;
                default = name;
                defaultText = "<name>";
                description = lib.mdDoc ''
                  Arbitrary name to associate with this
                  {command}`nix-post-build-push` queue.
                '';
              };

              destination = mkOption {
                type = secretOr [(types.strMatching ".*://.*") types.path];
                example = {
                  _secret = "/run/my/secrets/cache-url";
                };
                description = lib.mdDoc ''
                  The URL of the target cache or the path of the target chroot
                  store.

                  This is where {command}`nix-post-build-push` will copy queued
                  packages.

                  Supports reading the URL or path from a file
                '';
              };

              queueDir = mkOption {
                type = types.path;
                default = "${cfg.baseDir}/${config.name}";
                example = "/var/spool/my/queue";
                description = lib.mdDoc ''
                  Path to the directory that {command}`nix-post-build-push`
                  should use for managing its queue of symbolic links to store
                  paths.
                '';
              };

              serviceName = mkOption {
                type = types.nonEmptyStr;
                description = lib.mdDoc ''
                  Name of the systemd service associated with this queue.

                  **NOTE**: this option is not meant to be set by end users.
                  It exists in case you want to modify the service definition:
                  rather than writing
                  `systemd.services.<literal-service-name>`, you can instead
                  write
                  `systemd.services.''${config.nix-post-build-push.queues.myqueue.serviceName}`.
                '';
              };

              timerName = mkOption {
                type = types.nonEmptyStr;
                description = lib.mdDoc ''
                  Name of the systemd timer associated with this queue.

                  **NOTE**: this option is not meant to be set by end users.
                  It exists in case you want to modify the timer definition:
                  rather than writing `systemd.timers.<literal-timer-name>`,
                  you can instead write
                  `systemd.timers.''${config.nix-post-build-push.queues.myqueue.timerName}`.
                '';
              };
            };

          config = let
            unitName = "${exec}-${config.name}";
          in
            lib.mapAttrs (_: lib.mkOptionDefault) cfg.defaults
            // {
              serviceName = lib.mkForce unitName;
              timerName = lib.mkForce unitName;
            };
        }));
      };
    };
  };

  config = lib.mkIf (enabledQueues != {}) (lib.mkMerge [
    {
      services.nix-post-build-push.hook.script = lib.mkForce hook;
    }

    (lib.mkIf (!nixEnabled) {
      warnings = [
        "${exec}: sorry, `${exec}` is not supported when `nix.enable` is false; all queues are disabled."
      ];
    })

    (lib.mkIf nixEnabled {
      nix.settings = lib.mkIf cfg.hook.enable {
        post-build-hook = lib.mkOverride cfg.hook.priority cfg.hook.script;
      };

      systemd.services = services;
      systemd.timers = timers;
      systemd.tmpfiles.rules = tmpfilesRules;
    })
  ]);
}
