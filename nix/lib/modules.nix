let 
  mkImageWithEntryPoint = import ./mkImageWithEntrypoint.nix;
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