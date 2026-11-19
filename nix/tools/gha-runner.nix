# Basic nix-flake based image to be used in github action runners
# nix-ld is setup for running node as provided by the runners
# User is set to runner(1001) and home set to /home/runner, but runtime
# dependencies for other workflows still need to be installed by
# `sudo nix profile add`
{
  perSystem = {self', config, pkgs, inputs', lib, ...}: let 
    nix2container = inputs'.nix2container.packages.nix2container;
    pamPermit = "${pkgs.linux-pam}/lib/security/pam_permit.so";
    pamPolicy = ''
      auth       sufficient ${pamPermit}
      account    sufficient ${pamPermit}
      password   sufficient ${pamPermit}
      session    required   ${pamPermit}
    '';
    pamSudo = pkgs.writeTextDir "etc/pam.d/sudo" pamPolicy;
    pamOther = pkgs.writeTextDir "etc/pam.d/other" pamPolicy;
    sudoers = pkgs.writeTextDir "etc/sudoers" ''
      Defaults env_keep += "NIX_SSL_CERT_FILE SSL_CERT_FILE"
      Defaults env_keep += "ENV BASH_ENV"
      Defaults env_keep += "NIX_PATH NIX_PROFILES NIX_BUILD_SHELL"
      Defaults env_keep += "NIX_LD NIX_LD_LIBRARY_PATH"
      root ALL=(ALL:ALL) ALL
      runner ALL=(ALL:ALL) NOPASSWD: ALL
    '';
    # Patched based on base image config file
    passwd = pkgs.writeTextDir "etc/passwd" ''
      root:x:0:0:System administrator:/root:/bin/bash
      runner:x:1001:1001:Github action runner:/home/runner:/bin/bash
      nixbld1:x:30001:30000:Nix build user 1:/var/empty:/run/current-system/sw/bin/nologin
      nixbld2:x:30002:30000:Nix build user 2:/var/empty:/run/current-system/sw/bin/nologin
      nixbld3:x:30003:30000:Nix build user 3:/var/empty:/run/current-system/sw/bin/nologin
      nixbld4:x:30004:30000:Nix build user 4:/var/empty:/run/current-system/sw/bin/nologin
      nixbld5:x:30005:30000:Nix build user 5:/var/empty:/run/current-system/sw/bin/nologin
      nixbld6:x:30006:30000:Nix build user 6:/var/empty:/run/current-system/sw/bin/nologin
      nixbld7:x:30007:30000:Nix build user 7:/var/empty:/run/current-system/sw/bin/nologin
      nixbld8:x:30008:30000:Nix build user 8:/var/empty:/run/current-system/sw/bin/nologin
      nixbld9:x:30009:30000:Nix build user 9:/var/empty:/run/current-system/sw/bin/nologin
      nixbld10:x:30010:30000:Nix build user 10:/var/empty:/run/current-system/sw/bin/nologin
      nixbld11:x:30011:30000:Nix build user 11:/var/empty:/run/current-system/sw/bin/nologin
      nixbld12:x:30012:30000:Nix build user 12:/var/empty:/run/current-system/sw/bin/nologin
      nixbld13:x:30013:30000:Nix build user 13:/var/empty:/run/current-system/sw/bin/nologin
      nixbld14:x:30014:30000:Nix build user 14:/var/empty:/run/current-system/sw/bin/nologin
      nixbld15:x:30015:30000:Nix build user 15:/var/empty:/run/current-system/sw/bin/nologin
      nixbld16:x:30016:30000:Nix build user 16:/var/empty:/run/current-system/sw/bin/nologin
      nixbld17:x:30017:30000:Nix build user 17:/var/empty:/run/current-system/sw/bin/nologin
      nixbld18:x:30018:30000:Nix build user 18:/var/empty:/run/current-system/sw/bin/nologin
      nixbld19:x:30019:30000:Nix build user 19:/var/empty:/run/current-system/sw/bin/nologin
      nixbld20:x:30020:30000:Nix build user 20:/var/empty:/run/current-system/sw/bin/nologin
      nixbld21:x:30021:30000:Nix build user 21:/var/empty:/run/current-system/sw/bin/nologin
      nixbld22:x:30022:30000:Nix build user 22:/var/empty:/run/current-system/sw/bin/nologin
      nixbld23:x:30023:30000:Nix build user 23:/var/empty:/run/current-system/sw/bin/nologin
      nixbld24:x:30024:30000:Nix build user 24:/var/empty:/run/current-system/sw/bin/nologin
      nixbld25:x:30025:30000:Nix build user 25:/var/empty:/run/current-system/sw/bin/nologin
      nixbld26:x:30026:30000:Nix build user 26:/var/empty:/run/current-system/sw/bin/nologin
      nixbld27:x:30027:30000:Nix build user 27:/var/empty:/run/current-system/sw/bin/nologin
      nixbld28:x:30028:30000:Nix build user 28:/var/empty:/run/current-system/sw/bin/nologin
      nixbld29:x:30029:30000:Nix build user 29:/var/empty:/run/current-system/sw/bin/nologin
      nixbld30:x:30030:30000:Nix build user 30:/var/empty:/run/current-system/sw/bin/nologin
      nixbld31:x:30031:30000:Nix build user 31:/var/empty:/run/current-system/sw/bin/nologin
      nixbld32:x:30032:30000:Nix build user 32:/var/empty:/run/current-system/sw/bin/nologin
      nobody:x:65534:65534:Unprivileged account (don't use!):/var/empty:/run/current-system/sw/bin/nologin
    '';
    # Patched based on base image config file
    group = pkgs.writeTextDir "etc/group" ''
      root:x:0:
      wheel:x:1:
      kmem:x:2:
      tty:x:3:
      messagebus:x:4:
      disk:x:6:
      audio:x:17:
      floppy:x:18:
      uucp:x:19:
      lp:x:20:
      cdrom:x:24:
      tape:x:25:
      video:x:26:
      dialout:x:27:
      utmp:x:29:
      adm:x:55:
      keys:x:96:
      users:x:100:
      docker:x:123:runner
      input:x:174:
      runner:x:1000:
      nixbld:x:30000:nixbld1,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld2,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld3,nixbld30,nixbld31,nixbld32,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9
      nogroup:x:65534:
    '';

    sudoBin = pkgs.runCommand "sudo-bin-only" {} ''
      mkdir -p $out/bin
      ln -sf ${pkgs.sudo}/bin/sudo $out/bin/sudo
    '';

    configFiles = pkgs.buildEnv {
      name = "config-files";
      paths = [
        pamSudo pamOther sudoers passwd group
        sudoBin
      ];
      pathsToLink = ["/bin" "/etc"];
    };

    nixLDLink = pkgs.runCommand "nix-ld-link" {} ''
      mkdir -p $out/lib64
      ln -sf ${pkgs.nix-ld}/libexec/nix-ld $out/lib64/ld-linux-x86-64.so.2
    '';

    rootFS = pkgs.runCommand "root-fs" {} ''
      mkdir -p $out
      cp -dR ${configFiles}/* $out/
      cp -dR ${nixLDLink}/* $out/
    '';
    baseImage = nix2container.pullImageFromManifest {
      imageName = "nix-community/docker-nixpkgs/nix-flakes";
      imageManifest = ./nix-flakes.image.manifest.json;
      imageTag = "latest-${pkgs.stdenv.hostPlatform.system}";
      registryUrl = "ghcr.io";
    };
    NIX_LD = pkgs.stdenv.cc.bintools.dynamicLinker;
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
    ];

    baseTools = nix2container.buildLayer {
      copyToRoot = pkgs.buildEnv {
        name = "base-tools";
        paths = with pkgs; [
          git gh
        ];
        pathsToLink = [
          "/bin"
        ];
      };
    };

  in {
    containers.gha-runner = {
      name = "ghcr.io/chaserhkj/containers/gha-nix-flake-runner";
      tag = "latest";
      fromImage = baseImage;
      fromImageEnv = true;
      initializeNixDatabase = true;
      config = {
        cmd = ["/bin/bash"];
        env = [
          "NIX_LD=${NIX_LD}"
          "NIX_LD_LIBRARY_PATH=${NIX_LD_LIBRARY_PATH}"
          "USER=runner"
          "HOME=/home/runner"
          "XDG_RUNTIME_DIR=/run/user/1001"
        ];
        user = "runner";
      };
      copyToRoot = rootFS;
      layers = [baseTools];
      perms = [
        {
          path = pkgs.sudo;
          regex = "bin/sudo";
          mode = "4755";
        }
        {
          path = sudoers;
          regex = "etc/sudoers";
          mode = "0440";
        }
      ];
      overlayContainerfile = builtins.readFile ./Containerfile.gha-runner;
    };
  };
}