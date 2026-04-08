{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix2container.url = "github:nlewo/nix2container";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./nix/lib/mkImageWithEntrypoint.nix ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        images.nfs-ganesha = {
            name = "nfs-ganesha";
            config = with pkgs; {
              Entrypoint = [ 
                "${tini}/bin/tini" "--"
                "${nfs-ganesha}/bin/ganesha.nfsd"
              ];
              Cmd = [
                "-F" "-x" "-L" "/dev/stdout" "-f"
                "/config/ganesha.conf"
              ];
            };
          };
      };
    };
}
