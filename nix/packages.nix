{
  perSystem = {pkgs, ...}: {
    packages = {
      open-code-review = pkgs.callPackage ./packages/open-code-review.nix {};
      mozilla-cq = pkgs.callPackage ./packages/mozilla-cq.nix {};
    };
  };
}