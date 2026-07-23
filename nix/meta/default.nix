{
  perSystem = {pkgs, inputs', ... }: let 
    gomod2nix = inputs'.gomod2nix.packages.default;
  in {
    packages.update-extra-deps = pkgs.writeShellScriptBin "update-extra-deps" ''
      set -ex
      shopt -s nullglob

      export PATH="$PATH:${pkgs.go}/bin"

      gen_lock_files() {
        local src=$1
        if [[ -f $src/go.mod ]] && [[ -f $src/go.sum ]]; then
          (cd $src && ${gomod2nix}/bin/gomod2nix)
        fi
        if [[ -f $src/package-lock.json ]]; then
          ${pkgs.prefetch-npm-deps}/bin/prefetch-npm-deps $src/package-lock.json > $src/npmDepsHash
        fi
        for subdir in $src/*; do
          [[ -d $subdir ]] && gen_lock_files $subdir || :
        done
      }

      [[ -f flake.nix ]] || { echo "must be called from flake root" >&2; exit 1; }

      cd nix
      ${pkgs.nvfetcher}/bin/nvfetcher
      for src in _sources/sha256-*; do
        gen_lock_files $src
      done
    '';
  };
}