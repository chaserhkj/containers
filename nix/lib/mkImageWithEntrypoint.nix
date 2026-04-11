localFlake@{withSystem, ...}:
{...}:
{
  perSystem = {config, lib, pkgs, system, ...}: {
    options.imagesWithFixedEntrypointVariant = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.attrs;
      default = {};
      description = "Definition of images as passed to nix2container.buildImage";
    };

    config.packages = let 
        localInputs' = localFlake.withSystem system ({inputs', ...}: inputs');
        inherit(localInputs'.nix2container.packages.nix2container) buildImage;
    in lib.mapAttrs (
      name: imageDefWithExtra: let
          extraAttrs = imageDefWithExtra.extra or {};
          imageDef = builtins.removeAttrs imageDefWithExtra ["extra"];
          entryPointImageDef = imageDef // {
            config = (imageDef.config or {}) // {
              Entrypoint = [ "/bin/entrypoint.sh" ];
              Cmd = [];
            };
            copyToRoot = lib.toList (imageDef.copyToRoot or []) ++ [
              (let
                entrypointStr = lib.escapeShellArgs (imageDef.config.Entrypoint or []);
                cmdStr = if (imageDef.config ? Cmd && imageDef.config.Cmd != [])
                  then lib.escapeShellArgs imageDef.config.Cmd
                  else ''"$@"'';
              in pkgs.writeShellScriptBin "entrypoint.sh"
              ''
                exec ${entrypointStr} ${cmdStr}
              '')
            ];
          };
        in ((buildImage imageDef)
        // {
          fixedEntrypoint = buildImage entryPointImageDef;
        } // extraAttrs )
    ) config.imagesWithFixedEntrypointVariant;
  };
}