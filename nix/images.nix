{
  imports = [
    ./services/nfs-ganesha.nix

    ./environments/term-agents.nix

    ./tools/amd-ctk.nix
  ];
  perSystem = {...}: {
    defaultImagePrefix = "ghcr.io/containers/";
  };
}