{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
  ];
  perSystem = {lib, inputs', pkgs, self', ...}: with pkgs; let 
      inherit (inputs'.nix2container.packages) nix2container;
      nixPkg = pkgs.nixVersions.latest;
      nixConfig = pkgs.writeTextDir "etc/nix/nix.conf"
        ''
          accept-flake-config = true
          experimental-features = nix-command flakes
          build-users-group =
          sandbox = false
        '';
      baseFS = pkgs.runCommand "base-fs" {} ''
        mkdir $out
        mkdir $out/tmp
      '';
      rootEnv = with pkgs; buildEnv {
        name = "root";
        paths = [
          bashInteractive
          coreutils-full
          util-linux
          busybox

          cacert
        ];
        pathsToLink = ["/bin" "/libexec" "/etc/ssl"];
      };
      nix-ld-compat = pkgs.runCommand "nix-ld-compat" {} ''
        install -D -m755 ${pkgs.nix-ld}/libexec/nix-ld $out/lib64/ld-linux-x86-64.so.2
      '';

      agentPkgs = with inputs'.llm-agents.packages; [
        opencode

        openskills
        tuicr
        ck
      ];
      nix-ld-script = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
      nix-ld-lib-path = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc
        pkgs.glibc
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
          env = [
            "USER=root"
            "HOME=/root"
            "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
            "NIX_LD=${nix-ld-script}"
            "NIX_LD_LIBRARY_PATH=${nix-ld-lib-path}"
          ];
        };
        initializeNixDatabase = true;
        copyToRoot = [
          baseFS
          rootEnv
          nixConfig
          nix-ld-compat
        ];
      };
    };
}