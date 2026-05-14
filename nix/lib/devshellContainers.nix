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
      inherit (types) lines nullOr package listOf str submodule;

      containerSubmoduleType = systemCtx.options.containers.type.nestedTypes.elemType;
      devshellSubmoduleType = systemCtx.options.devshells.type.nestedTypes.elemType;
    in 
    submodule (subCtx@{config, options, ...}:{
      options = {
        container = mkOption {
          type = containerSubmoduleType;
          description = "additional container configuration as accepted by containers module";
        };
        # internal resolved container configuration
        _container = mkOption {
          type = containerSubmoduleType;
          internal = true;
        };
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
        devshell = mkOption {
          type = devshellSubmoduleType;
          description = "additional devshell configuration as accepted by devshell module";
        };
        # internal resolved devshell config
        _devshell = mkOption {
          type = devshellSubmoduleType;
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
        rootEnvConfig = {
          packages = with pkgs; [
            bashInteractive
            coreutils-full
            util-linux
            busybox
          ];
          includedPaths = [ "/bin" ];
        };

        # Evaluating final devshell config
        _devshell = lib.mkMerge [
          {
            packages = lib.mkIf (config.nixPkg != null) [
              config.nixPkg
            ];
          }
          (lib.mkAliasDefinitions subCtx.options.devshell)
        ];

        # Evaluating container config
        _container = lib.mkMerge [
          {
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
          }
          (lib.mkAliasDefinitions subCtx.options.container)
        ];
      };
    });


  in {
    options.devshellContainers = lib.mkOption {
      type = lib.types.lazyAttrsOf devshellContainerOptionSubmodule;
      description = "devshell environment wrapped as a nix2container image";
    };
    config = {
      devshells = let 
        getDevshellOpt = name:
          (systemCtx.options.devshellContainers.type.getSubOptions [ name ])._devshell;
      in 
        mapAttrs (name: configData: lib.mkAliasDefinitions (getDevshellOpt name)) config.devshellContainers;
      containers = mapAttrs (name: configData: configData._container)  config.devshellContainers;
    };
  };
}