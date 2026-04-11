let 
  mkImageWithEntryPoint = import ./mkImageWithEntryPoint.nix;
  containerizedApp = import ./containerizedApp.nix;
in
{
  imports = [
    mkImageWithEntryPoint
  ];
  flake.flakeModules = {
    inherit mkImageWithEntryPoint containerizedApp;
  };
}