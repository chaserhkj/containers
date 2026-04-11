{...}:
{
  perSystem = {config, lib, inputs', pkgs, ...}: {
    options.imagesWithFixedEntrypointVariant = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.attrs;
      default = {};
      description = "Definition of images as passed to nix2container.buildImage";
    };

    config.packages = let 
        inherit(inputs'.nix2container.packages.nix2container) buildImage;
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