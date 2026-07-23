{
  buildGoApplication,
  extraSources,
}: let 
  pname = "amd-ctk";
  source = extraSources.${pname};
in buildGoApplication {
  inherit pname;
  inherit (source) version src;
  modules = builtins.dirOf source.extract."go.sum" + "/gomod2nix.toml";
  subPackages = [
    "cmd/amd-ctk"
  ];
  
  preCheck = ''
    export AMD_CTK_PATH=$GOPATH/bin/amd-ctk
  '';
}