{
  perSystem = {inputs', config, lib, ...}: {
    options.defaultImagePrefix = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "default image prefix to add to package names";
    };
    options.defaultImageTag = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      description = "default image tag to use";
    };
    options.containerizedApp = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.package;
      default = {};
      description = "package to build as containerized app";
    };
    config.packages = let 
      inherit (inputs'.nix2container.packages.nix2container) buildImage;
      buildImageFor = pname: package: (buildImage {
        name = "${config.defaultImagePrefix}${pname}";
        tag = config.defaultImageTag;
        config = {
          entrypoint = [ (lib.getExe package) ];
        };
      }) // {
        app = package;
      };
    in builtins.mapAttrs buildImageFor config.containerizedApp;
  };
}