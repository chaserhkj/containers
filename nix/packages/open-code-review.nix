{
  buildGoApplication,
  extraSources,
}: let 
  pname = "open-code-review";
  source = extraSources.${pname};
in buildGoApplication {
  inherit pname;
  inherit (source) version src;
  modules = builtins.dirOf source.extract."go.sum" + "/gomod2nix.toml";

  subPackages = [
    "cmd/opencodereview"
  ];
  doCheck = false;
  postInstall = ''mv $out/bin/opencodereview $out/bin/ocr'';
  meta.mainProgram = "ocr";
}