localFlake@{buildImageWithSystem, ...}:
{...}:
{
  perSystem = {config, lib, system, ...}: 
  with lib; with types;
  let 
    # Convert the first character of a string to lower case
    lowerFirst = s: 
    let
      first = lib.toLower (builtins.substring 0 1 s);
      rest = builtins.substring 1 (builtins.stringLength s) s;
    in
      first + rest;
    # Prototype for OCI image config as used by nix2container
    ociImageConfigSchema = {
      User = mkOption { type = nullOr str; default = null; };
      # not type-checked for now
      ExposedPorts = mkOption { type = attrsOf anything; };
      Env = mkOption { type = listOf str; };
      Entrypoint = mkOption { type = listOf str;};
      Cmd = mkOption {type = listOf str;};
      # not type-checked for now
      Volumes = mkOption {type = attrsOf anything; };
      WorkingDir = mkOption {type = nullOr str; default = null;};
      Labels = mkOption {type = attrsOf str; };
      StopSignal = mkOption {type = nullOr str; default = null;};
    };
    ociImageConfigSchemaLowerCase = builtins.listToAttrs (
      lib.mapAttrsToList (name: value: { name = lowerFirst name; value = value;}) ociImageConfigSchema
    );
    # Prototype for nix2container.buildImage input attribute
    buildImageConfigSchema = {
      name = mkOption { type = str; };
      tag = mkOption { type = nullOr str; default = null; };
      config = mkOption {
        type = submodule { options = ociImageConfigSchema; };
      };
      copyToRoot = mkOption { type = listOf pkgs; };
      # result of nix2container.pullImage or nix2container.pullImageFromManifest
      # not type-checked for now
      fromImage = mkOption { type = anything; default = null; };
      maxLayers = mkOption { type = int; default = 1; };
      # not type-checked for now
      perms = mkOption { type = listOf attrs; };
      initializeNixDatabase = mkOption { type = bool; default = false; };
      # result of nix2container.buildLayer
      # not type-checked for now
      layers = mkOption { type = listOf anything; };
    };
    buildImageConfigStrictType = submodule {
      options = buildImageConfigSchema;
    };
    buildImageConfigInputType = submodule {
      options = buildImageConfigSchema // {
        # Allow omitting name in the input and use default prefix
        name = mkOption { type = nullOr str; default = null; };
        # Accept both CamelCase and camelCase
        config = mkOption { type = submodule {
          options = ociImageConfigSchema // ociImageConfigSchemaLowerCase;
        };};
      };
    };
  in {
    options = {
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
        type = lazyAttrsOf (submodule {
          freeformType = buildImageConfigInputType;
          options.passthru = mkOption {
            type = lazyAttrsOf (uniq anything);
            description = "passthrough attribute set, to be merged with the"
            +" derivation as returned by nix2container";
          };
        });
        description = "nix2container definitions."
          +" uses mostly the same prototype as nix2container"
          +" input attribute sets. see nix2container documentation for details.";
      };
      # Option storing internal data
      _containers = mkOption {
        type = lazyAttrsOf (submodule {
          options = {
            # Sanitized config before passing into nix2container
            sanitizedConfig = mkOption { type = buildImageConfigStrictType; };
            # Final config being passed into nix2container
            finalConfig = mkOption { type = buildImageConfigStrictType; };
            # Final actual passthrough attributes
            passthru = mkOption { type = lazyAttrsOf (uniq anything); };
          };
        });
        internal = true;
      };
    };
    config = let 
      inherit(builtins) mapAttrs removeAttrs attrNames map listToAttrs hasAttr intersectAttrs;

      sanitizeConfig = pname: container: let
        mergedOCIConfig = listToAttrs (map (field: {
          name = field;
          value = lib.mkMerge [
            container.config.${lowerFirst field}
            container.config.${field}
          ];
        }) (attrNames ociImageConfigSchema));
      in
        intersectAttrs buildImageConfigSchema container 
        // { 
          name = if container.name == null
            then config.defaultImagePrefix + pname
            else container.name;
          tag = if container.tag == null
            then config.defaultImageTag
            else container.tag;
          config = mergedOCIConfig;
        };

    in {

      _containers = mapAttrs (pname: container: rec {
        sanitizedConfig = sanitizeConfig pname container;
        finalConfig = sanitizedConfig;
        passthru = container.passthru;
      }) config.containers;

      packages = let 
        buildImage = localFlake.buildImageWithSystem system;
        buildImageFor = pname: data:
          buildImage data.finalConfig // data.passthru;
      in mapAttrs buildImageFor config._containers;
    };
  };
}