{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages = {
      graphrag = pkgs.callPackage ./packages/graphrag.nix {
        inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;
      };
      openkb = pkgs.callPackage ./packages/openkb.nix {
        inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;
      };
      open-code-review = pkgs.callPackage ./packages/open-code-review.nix { };
      opencommit = pkgs.callPackage ./packages/opencommit.nix { };
      llm-wiki-compiler = pkgs.callPackage ./packages/llm-wiki-compiler.nix { };
      mozilla-cq = pkgs.callPackage ./packages/mozilla-cq.nix { };
    };
  };
}
