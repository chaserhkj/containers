{flake-parts-lib, withSystem, inputs, lib, ...}: let 
  inherit(flake-parts-lib) importApply;
  localFlakeContext = {
    importApplyContext = module: importApply module localFlakeContext;
    buildImageWithSystem = system: (withSystem system ({inputs', ...}: inputs'))
      .nix2container.packages.nix2container.buildImage;
    devshell = inputs.devshell;
    flakePartsModule = inputs.flake-parts.flakeModules.flakeModules;
  };

  inherit(localFlakeContext) importApplyContext;
  containers = importApplyContext ./containers.nix;
  mkImageWithEntryPoint = importApplyContext ./mkImageWithEntrypoint.nix;
  containerizedApps = importApplyContext ./containerizedApps.nix;
  devshellContainers = importApplyContext ./devshellContainers.nix;
in {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    containers
    mkImageWithEntryPoint
    containerizedApps
    devshellContainers
  ];
  perSystem = {...}: {
    defaultImagePrefix = "ghcr.io/chaserhkj/containers/";
  };
  flake.flakeModules = {
    inherit
      containers
      mkImageWithEntryPoint 
      containerizedApps
      devshellContainers;
  };
}