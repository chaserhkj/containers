localFlake@{importApplyContext, devshell, flakePartsModule, ...}:
{...}: {
  imports = [ 
    flakePartsModule
    devshell.flakeModule
  ];
  perSystem = systemCtx@{lib, config, options, pkgs, self', system, ...}: let 

    inherit (builtins) mapAttrs;

    devshellContainerOptionSubmodule = let 
      inherit (lib) types mkOption;
      inherit (types) lines nullOr package listOf str submodule attrs;
    in 
    submodule (subCtx@{config, options, ...}:{
      options = {
        nixConfig = mkOption {
          type = lines;
          description = "/etc/nix/nix.conf contents in the container";
        };
        nixPkg = mkOption {
          type = nullOr package;
          default = pkgs.nixVersions.latest;
          description = "nix package to include in the container, set null to disable nix from container";
        };
        baseFSDirs = mkOption {
          type = listOf str;
          description = "base FS directories to create in the container";
        };
        rootEnvConfig = mkOption {
          type = nullOr (submodule {
            options.packages = mkOption {
              type = listOf package;
              description = "packages for the root environment";
            };
            options.includedPaths = mkOption {
              type = listOf str;
              description = "paths in the packages to be included in root environment";
            };
          });
          description = "config for root environment in the container,"
          +" additional packages can be added using copyToRoot, set null to disable";
        };
        caCertPkg = mkOption {
          type = nullOr package;
          default = pkgs.cacert;
          description = "CA cert package to include in the container, set null to disable";
        };
        nixLdPkg = mkOption {
          type = nullOr package;
          default = pkgs.nix-ld;
          description = "nix-ld package to enable in the container, set null to disable";
        };
        nixLdExtraLibs = mkOption {
          type = listOf package;
          description = "extra library packages to be exported to nix-ld";
        };
        # Additional container config to be applied
        _container = mkOption {
          type = attrs;
          internal = true;
        };
        # Additional devshell config to be applied
        _devshell = mkOption {
          type = attrs;
          internal = true;
        };
      };
      config = {
        # Baseline configurations to append on
        baseFSDirs = [ "tmp" ];
        nixConfig =
        ''
        accept-flake-config = true
        experimental-features = nix-command flakes
        build-users-group =
        sandbox = false
        '';
        rootEnvConfig = lib.mkMerge [
          {
            packages = with pkgs; [
              bashInteractive
              coreutils-full
              util-linux
              busybox
            ];
            includedPaths = [ "/bin" ];
          }
          (lib.mkIf (config.caCertPkg != null) {
            packages = [config.caCertPkg];
            includedPaths = ["/etc/ssl"];
          })
        ];

        # additional devshell config
        _devshell = {
          packages = lib.mkIf (config.nixPkg != null) [
            config.nixPkg
          ];
        };

        # additional container config
        _container = {
          config = {
            Env = lib.mkMerge [
              [ "USER=root" "HOME=/root" ]
              (lib.mkIf (config.caCertPkg != null) [
                "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              ])
              (lib.mkIf (config.nixLdPkg != null) (let
                nix-ld-path = lib.fileContents "${config.nixLdPkg.stdenv.cc}/nix-support/dynamic-linker";
                nix-ld-lib-path = lib.makeLibraryPath ([config.nixLdPkg.stdenv.cc.cc] ++ config.nixLdExtraLibs); 
              in [
                "NIX_LD=${nix-ld-path}"
                "NIX_LD_LIBRARY_PATH=${nix-ld-lib-path}"
              ]))
            ];
          };
          initializeNixDatabase = config.nixPkg != null;
          copyToRoot = let 
            inherit (builtins) map;
            inherit (lib.strings) concatLines;
            baseFS = pkgs.runCommand "base-fs" {}
              ''
              mkdir $out
              ${concatLines (map (dir: "mkdir -p $out/${dir}") config.baseFSDirs)}
              '';
            rootEnv = pkgs.buildEnv {
              name = "root";
              paths = config.rootEnvConfig.packages;
              pathsToLink = config.rootEnvConfig.includedPaths;
            };
          in lib.mkMerge [
            [baseFS rootEnv]
            # nix config
            (lib.mkIf (config.nixPkg != null) [(
              pkgs.writeTextDir "etc/nix/nix.conf" config.nixConfig
            )])
            # nix-ld compat
            (lib.mkIf (config.nixLdPkg != null) [(
            let 
              libDir = if builtins.elem system [ "x86_64-linux" "mips64-linux" "powerpc64le-linux" ]
                then "lib64"
                else "lib";
              in pkgs.runCommand "nix-ld-compat" {}
              ''
              install -D -m755 ${config.nixLdPkg}/libexec/nix-ld $out/${libDir}/$(basename ${config.nixLdPkg.stdenv.cc.bintools.dynamicLinker})
              ''
            )])
          ];
        };
      };
    });


  in {
    options.devshellContainers = lib.mkOption {
      type = lib.types.lazyAttrsOf devshellContainerOptionSubmodule;
      description = "devshell environment wrapped as a nix2container image";
    };
    config = {
      # Transfer devshells config
      devshells = mapAttrs (name: configData: configData._devshell)  config.devshellContainers;
      # Transfer container config
      # Entrypoint comes from devShell and needs to be populated externally
      containers = mapAttrs (name: configData: lib.mkMerge [
        configData._container
        {
          config.Entrypoint = [self'.devShells.${name}.flakeApp.program];
        }
      ])  config.devshellContainers;
    };
  };
}