localFlake@{buildImageWithSystem, ...}:
{...}:
{
  perSystem = {config, lib, system, ...}: {
    options = with lib lib.types; {
      defaultImagePrefix = mkOption {
        type = str;
        default = "";
        description = "default image prefix to add to package names";
      };
      defaultImageTag = mkOption {
        type = str;
        default = "latest";
        description = "default image tag to use";
      };
      containers = mkOption {
        type = submodule {
          freeformType = attrsOf (uniq anything);
          options = {
            config = mkOption {
              type = submodule {
                freeformType = attrsOf (uniq anything);
                options = {
                  env = mkOption { type = listOf str; };
                };
              };
            };
            perms = mkOption { type = listOf attrs; };
            layers = mkOption { type = listOf attrs; };
            copyToRoot = mkOption { type = listOf pkgs; };
            passthru = mkOption {
              type = attrsOf (uniq anything);
              description = "passthrough attribute set, to be merged with the"
              +" derivation as returned by nix2container";
            };
          };
        };
        description = "nix2container definitions."
          +" uses mostly the same prototype as nix2container"
          +" input attribute sets. see nix2container documentation for details.";
      };
    };
    config.packages = let 
      inherit(builtins) mapAttrs removeAttrs;

      buildImage = localFlake.buildImageWithSystem system;
      buildImageFor = pname: inputConfig: buildImage ({
        name = config.defaultImagePrefix ++ pname;
        tag = config.defaultImageTag;
      } // removeAttrs inputConfig ["passthru"])
      // inputConfig.passthru;

    in mapAttrs buildImageFor config.containers;
  };
}