{
  buildGoApplication,
  extraSources,
  llama-swap-ui,
}: let 
  pname = "llama-swap";
  source = extraSources.${pname};

in buildGoApplication {
  inherit pname;
  inherit (source) version src;
  modules = builtins.dirOf source.extract."go.sum" + "/gomod2nix.toml";
  # enables fully static build
  CGO_ENABLED = 0;

  preBuild = ''
    cp -rv ${llama-swap-ui} internal/server/ui_dist
  '';

  tags = ["embed_ui"];

  doCheck = false;
}