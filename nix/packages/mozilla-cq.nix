{ buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "cq";
  version = "0.15.0";

  src = (fetchFromGitHub {
    owner = "mozilla-ai";
    repo = "cq";
    rev = "cli/v${version}";
    hash = "sha256-vMgrSsdh38ZL76B/j/iNK7VqUw+aNPxDZKPZE90CUXE=";
  }) + "/cli";

  postInstall = "mv $out/bin/cli $out/bin/cq";

  vendorHash = "sha256-tbvDJ8+sPpp7y+PxeHd7KW6qQB0x+upbdDvah9tqZck=";

  meta.mainProgram = "cq";
}
