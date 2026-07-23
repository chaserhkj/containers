{
  perSystem = {self', config, ...}: let 
    cliPkg = config.extendedPkgs.callPackage ../packages/amd-ctk.nix { };
  in {
    containers.amd-ctk = {
      name = "ghcr.io/chaserhkj/containers/amd-ctk";
      tag = "latest";
      config = {
        Entrypoint = [
          "${cliPkg}/bin/amd-ctk"
        ];
      };
      buildFixedEntrypointVariant = true;
      passthru = {
        cli = cliPkg;
      };
    };
  };
}