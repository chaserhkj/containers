{flake-parts-lib, withSystem, inputs, lib, ...}: let 
  inherit(flake-parts-lib) importApply;
  localFlakeContext = {
    importApplyContext = module: importApply module localFlakeContext;
    buildImageWithSystem = system: (withSystem system ({inputs', ...}: inputs'))
      .nix2container.packages.nix2container.buildImage;
  };

  inherit(localFlakeContext) importApplyContext;
  mkImageWithEntryPoint = importApplyContext ./mkImageWithEntrypoint.nix;
  containerizedApps = importApplyContext ./containerizedApps.nix;
in {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    mkImageWithEntryPoint
  ];
  flake.flakeModules = {
    inherit
      mkImageWithEntryPoint 
      containerizedApps;
  };
}