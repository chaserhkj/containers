{
  imports = [
    ./services/nfs-ganesha.nix
    ./services/litellm-rust.nix

    ./environments/term-agents.nix

    ./tools/amd-ctk.nix
  ];
}