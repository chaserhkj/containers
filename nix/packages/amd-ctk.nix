{
  lib,
  fetchFromGitHub,
  buildGoModule
}: buildGoModule (finalAttrs: {
  pname = "amd-ctk";
  version = "1.3.0";
  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "container-toolkit";
    tag = "v${finalAttrs.version}";
    hash = "sha256-+YqVm/u0PYvyoHUSwRapByvmIunZUfcPV5rYDFW7Ifs=";
  };

  vendorHash = "sha256-w7QJBSRRsvxUaXNiXw3OnkZCcKJgwp/WTJQcDJ1msaA=";

  subPackages = [
    "cmd/amd-ctk"
  ];
  
  preCheck = ''
    export AMD_CTK_PATH=$GOPATH/bin/amd-ctk
  '';
})