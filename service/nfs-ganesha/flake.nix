{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages.default = with pkgs; dockerTools.buildImage {
          name = "nfs-ganesha";
          config = {
            Cmd = [
              "${tini}/bin/tini" "--"
              "${nfs-ganesha}/bin/ganesha.nfsd" "-F"
              "-x" "-L" "/dev/stdout" "-f" "/config/ganesha.conf"
            ];
          };
        };
      };
    };
}
