localFlake@{withSystem, inputs, ...}:
{...}:
let 
  local-devshell = inputs.devshell;
in {
  imports = [ local-devshell.flakeModule ];
  perSystem = {config, options, lib, system, ...}: {
    options.devshellContainer = lib.mkOption {
      type = with lib.types; submodule {
        options = {
          devshellAttrs = lib.mkOption {
            type = options.devshells.type;
            default = {};
            description = "";
          };
          containerAttrs = lib.mkOption {
            type = attrs;
            default = {};
            description = "";
          };
        };
      };
      default = {
        devshellAttrs = {};
        containerAttrs = {};
      };
    };

  };
}