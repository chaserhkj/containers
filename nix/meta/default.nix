{
  perSystem = {pkgs, inputs', ... }: let 
    gomod2nix = inputs'.gomod2nix.packages.default;
  in {
    packages.update-extra-deps = pkgs.writeShellScriptBin "update-extra-deps" ''
      set -ex
      export PATH="$PATH:${pkgs.go}/bin"
      [[ -f flake.nix ]] || { echo "must be called from flake root" >&2; exit 1; }
      cd nix
      ${pkgs.nvfetcher}/bin/nvfetcher
      for src in _sources/sha256-*; do
        [[ -f $src/go.mod ]] || continue
        [[ -f $src/go.sum ]] || continue
        (cd $src && ${gomod2nix}/bin/gomod2nix)
      done
    '';
  };
}