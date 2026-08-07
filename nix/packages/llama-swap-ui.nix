{
  lib,
  buildNpmPackage,
  extraSources,
}:
let
  inherit (builtins) readFile dirOf;
  inherit (lib.strings) trim;
  pname = "llama-swap";
  source = extraSources.${pname};
in
buildNpmPackage {
  pname = "llama-swap-ui";
  inherit (source) version;
  src = source.src + "/ui-svelte";
  npmDepsHash = trim (readFile (dirOf source.extract."ui-svelte/package-lock.json" + "/npmDepsHash"));
  installPhase = ''
    mkdir -p $out
    cp -rvf ../internal/server/ui_dist/. $out/.
  '';
}
