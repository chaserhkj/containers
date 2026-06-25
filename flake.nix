{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix2container.url = "github:nlewo/nix2container";
    devshell.url = "github:numtide/devshell";
    llm-agents.url = "github:numtide/llm-agents.nix";
    git-ai = {
      url = "github:git-ai-project/git-ai";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./nix/lib/modules.nix
        ./nix/images.nix
        ./nix/packages.nix
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
}
