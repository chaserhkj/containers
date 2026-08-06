{
  buildGoApplication,
  extraSources,
}: let 
  pname = "llama-swap";
  source = extraSources.${pname};
in buildGoApplication {
  inherit pname;
  inherit (source) version src;
  modules = builtins.dirOf source.extract."go.sum" + "/gomod2nix.toml";

  doCheck = false;
}