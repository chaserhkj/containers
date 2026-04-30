{
  lib,
  fetchFromGithub,
  buildGoModule
}: buildGoModule (finalAttrs: {
  pname = "amd-ctk";
  version = "1.3.0";
  src = fetchFromGithub {
    owner = "ROCm";
    repo = "container-toolkit";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  vendorHash = null;

  subPackages = [
    "cmd/amd-ctk"
  ];
})