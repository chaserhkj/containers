{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
  ];
  perSystem = {pkgs, self', ...}: with pkgs; let 
      nixPkg = pkgs.nixVersions.latest;
      nixConfig = pkgs.writeTextDir "etc/nix/nix.conf"
        ''
          accept-flake-config = true
          experimental-features = nix-command flakes
          build-users-group =
          sandbox = false
        '';
    in {
      devshells.term-agents = {
        packages = [
          pkgs.hello
        ];
      };
      imagesWithFixedEntrypointVariant.term-agents = {
        name = "term-agents";
        config = {
          entrypoint = ["${nixPkg}/bin/nix"];
          cmd = [];
        };
        copyToRoot = [
          nixConfig
        ];
      };
    };
}