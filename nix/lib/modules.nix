{flake-parts-lib, withSystem, inputs, ...}: let 
  inherit(flake-parts-lib) importApply;
  importApplyLocalDeps = module: importApply module { inherit withSystem; };
  mkImageWithEntryPoint = importApplyLocalDeps ./mkImageWithEntrypoint.nix;
  containerizedApp = importApplyLocalDeps ./containerizedApp.nix;
in {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    mkImageWithEntryPoint
  ];
  flake.flakeModules = {
    inherit
      mkImageWithEntryPoint 
      containerizedApp;
  };
}