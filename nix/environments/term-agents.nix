{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
  ];
  perSystem = {inputs', pkgs, self', ...}: with pkgs; let 
      inherit (inputs'.nix2container.packages) nix2container;
      nixPkg = pkgs.nixVersions.latest;
      nixConfig = pkgs.writeTextDir "etc/nix/nix.conf"
        ''
          accept-flake-config = true
          experimental-features = nix-command flakes
          build-users-group =
          sandbox = false
        '';
      corePkgs = with pkgs; [
        coreutils-full
        util-linux
        busybox
        curl
        nixPkg
        git
      ];
      agentPkgs = with inputs'.llm-agents.packages; [
        opencode

        openskills
        tuicr
        ck
      ];
    in {
      devshells.term-agents = {
        packages = corePkgs ++ agentPkgs ++ [
        ];
      };
      imagesWithFixedEntrypointVariant.term-agents = {
        name = "ghcr.io/chaserhkj/containers/term-agents";
        tag = "latest";
        config = {
          entrypoint = ["${self'.devShells.term-agents.flakeApp.program}"];
        };
        initializeNixDatabase = true;
        copyToRoot = [
          nixConfig
        ];
      };
    };
}