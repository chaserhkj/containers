{
  fetchFromGitHub,
  buildGoModule,
}: buildGoModule rec {
  pname = "open-code-review";
  version = "1.7.5";
  src = fetchFromGitHub {
    owner = "alibaba";
    repo = "open-code-review";
    tag = "v${version}";
    hash = "sha256-a61duWHPBemfsFfPfJXkBx6mZbUKgZ3otrb6Q1ZkzJw=";
  };
  vendorHash = "sha256-/1pHXdQler4mZd8wHEyfsmLmpEUKVge1m4774X9c9/w=";
  subPackages = [
    "cmd/opencodereview"
  ];
  doCheck = false;
  postInstall = ''mv $out/bin/opencodereview $out/bin/ocr'';
  meta.mainProgram = "ocr";
}