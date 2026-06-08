{
  perSystem = {pkgs, ...}: let 
    cliPkg = pkgs.callPackage ../packages/litellm-rust.nix {};
  in { 
    containers.litellm-rust = {
      name = "ghcr.io/chaserhkj/containers/litellm-rust";
      tag = "latest";
      config.Entrypoint = [
        "${cliPkg}/bin/lite"
      ];
      config.Cmd = [
        "--config" "/config.yaml"
      ];
      buildFixedEntrypointVariant = true;
      passthru = {
        cli = cliPkg;
      };
    };
  };
}