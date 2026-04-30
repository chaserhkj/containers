{
  perSystem = {pkgs, self', ...}: let 
    cliPkg = pkgs.callPackage ../packages/amd-ctk.nix {};
  in {
    imagesWithFixedEntrypointVariant.amd-ctk = {
      name = "ghcr.io/chaserhkj/containers/amd-ctk";
      tag = "latest";
      config = {
        Entrypoint = [
          "${cliPkg}/bin/amd-ctk"
        ];
      };
      extra = {
        cli = cliPkg;
      };
    };
  };
}