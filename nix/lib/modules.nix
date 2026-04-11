{flake-parts-lib, withSystem, ...}: let 
  inherit(flake-parts-lib) importApply;
  importApplyLocalDeps = module: importApply module { inherit withSystem; };
  mkImageWithEntryPoint = importApplyLocalDeps ./mkImageWithEntrypoint.nix;
  containerizedApp = importApplyLocalDeps ./containerizedApp.nix;
in {
  imports = [
    mkImageWithEntryPoint
  ];
  flake.flakeModules = {
    inherit
      mkImageWithEntryPoint 
      containerizedApp;
  };
}