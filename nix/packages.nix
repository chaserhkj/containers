{ inputs, ... }: {
  perSystem =
    { pkgs, inputs', ... }:
    let
      extendedPkgs = (pkgs.extend (
        final: prev: {
          inherit(inputs) pyproject-nix pyproject-build-systems uv2nix;
          extraSources = prev.callPackage ./_sources/generated.nix { };
        }
      )).extend inputs.gomod2nix.overlays.default;
      inherit (extendedPkgs) callPackage;
    in
    {
      inherit extendedPkgs;
      packages = {
        graphrag = callPackage ./packages/graphrag.nix { };
        openkb = callPackage ./packages/openkb.nix { };
        open-code-review = callPackage ./packages/open-code-review.nix { };
        opencommit = callPackage ./packages/opencommit.nix { };
        llm-wiki-compiler = callPackage ./packages/llm-wiki-compiler.nix { };
        mozilla-cq = callPackage ./packages/mozilla-cq.nix { };
      };
    };
  transposition.extendedPkgs.adHoc = true;
}
