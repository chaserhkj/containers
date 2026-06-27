{
  fetchFromGitHub,
  buildGoModule,
}: buildGoModule rec {
  pname = "open-code-review";
  version = "1.2.6";
  src = fetchFromGitHub {
    owner = "alibaba";
    repo = "open-code-review";
    tag = "v${version}";
    hash = "sha256-CoVh8FHP16RqNbP6Ev0CpsGvos3ei+IkcXeV2dpTUdQ=";
  };
  vendorHash = "sha256-ILvC95XbaM86StJdC2Xt3ayWxXG3FqgOzz8x7puO5sA=";
  subPackages = [
    "cmd/opencodereview"
  ];
  doCheck = false;
  postInstall = ''mv $out/bin/opencodereview $out/bin/ocr'';
  meta.mainProgram = "ocr";
}