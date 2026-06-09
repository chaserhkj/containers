localFlake@{importApplyContext, flakePartsModule, ...}:
{...}:
{
  imports = [
    flakePartsModule
  ];
  perSystem = {config, lib, system, pkgs, ...}: {
    options.containerizedApps = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.package;
      default = {};
      description = "package to build as containerized app";
    };
    config.containers = let 
      inherit (builtins) mapAttrs;

      buildImageFor = pname: package: {
        config.Entrypoint = (lib.mkIf (package.useTini or false) [
          "${pkgs.tini}/bin/tini" "--"
        ])
          ++ [ (lib.getExe package) ];
        passthru.app = package;
      };
    in mapAttrs buildImageFor config.containerizedApps;
  };
}