localFlake@{withSystem, inputs, lib, importApply, ...}:
{...}: 
let 
  local-devshell = inputs.devshell;
  local-mkImageWithEntryPoint = importApply ./mkImageWithEntryPoint.nix localFlake;
in {
  imports = [ 
    local-devshell.flakeModule
    local-mkImageWithEntryPoint
  ];
  perSystem = {config, options, system, pkgs, ...}: let 

    inherit (builtins) mapAttrs;

    # make underlying devshell declaration from devshellContainer config
    make-devshell-config = name: allConfigs: lib.mkMerge [
      {
        packages = [
          pkgs.nixVersions.latest
        ];
      }
      allConfigs.devshellConfig
    ];

    # make underlying container attributes from devshellContainer config
    make-container-attrs = name: allConfigs: lib.mkMerge [
      {

      }
      allConfigs.containerAttrs
    ];

  in {
    options.devshellContainer = lib.mkOption {
      type = with lib lib.types; submodule {
        options = {
          devshellConfig = mkOption {
            type = options.devshells.type;
          };
          containerAttrs = mkOption {
            type = submodule {
            };
          };
        };
      };
    };
    config = {
      devshells = mapAttrs make-devshell-config config.devshellContainer;
      imagesWithFixedEntrypointVariant = mapAttrs make-container-attrs config.devshellContainer;
    };
  };
}