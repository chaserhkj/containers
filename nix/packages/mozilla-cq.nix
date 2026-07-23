{
  buildGoApplication,
  extraSources,
  lib,
}:
let
  pname = "cq";
  source = extraSources.${pname};
in
buildGoApplication {
  inherit pname;
  version = lib.strings.removePrefix "cli/" source.version;
  src = source.src + "/cli";
  modules = builtins.dirOf source.extract."cli/go.sum" + "/gomod2nix.toml";

  postInstall = "mv $out/bin/cli $out/bin/cq";
  meta.mainProgram = "cq";
}
