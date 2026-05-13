localFlake@{importApplyContext, buildImageWithSystem, ...}:
{...}:
{
  imports = [ (localFlake.importApplyContext ./containers.nix) ];
  perSystem = {config, lib, pkgs, system, ...}: {
    options.containers = with lib; with types; mkOption {
      type = lazyAttrsOf (submodule {
        options.buildFixedEntrypointVariant = mkOption {
          type = bool;
          default = false;
          description = "flag to enable building fixed entrypoint variant of the image."
          +" image will be exported as sub attribute fixedEntrypointVariant";
        };
      });
    };
    config._containers = let 
      inherit (builtins) mapAttrs removeAttrs;

      buildImage = localFlake.buildImageWithSystem system;
      addVariant = pname: inputConfig:
        lib.mkIf inputConfig.buildFixedEntrypointVariant {
          passthru.fixedEntrypointVariant = let 
            baseDef = config._containers.${pname}.sanitizedConfig;
          in buildImage (baseDef // {
            config = baseDef.config // {
              Entrypoint = ["/bin/entrypoint.sh"];
              Cmd = [];
            };
            copyToRoot = lib.toList baseDef.copyToRoot ++ [
              (let
                entrypointStr = lib.escapeShellArgs baseDef.config.Entrypoint;
                cmdStr = if baseDef.config.Cmd != []
                  then lib.escapeShellArgs baseDef.config.Cmd
                  else ''"$@"'';
              in pkgs.writeShellScriptBin "entrypoint.sh"
              ''
                exec ${entrypointStr} ${cmdStr}
              '')];
          });
        };
    in mapAttrs addVariant config.containers;
  };
}