{
  perSystem = {pkgs, ...}: {
    packages = {
      amd-ctk = pkgs.callPackage ./packages/amd-ctk.nix {};
    };
  };
}