{
  lib,
  buildNpmPackage,
  extraSources,
}:
let
  inherit (builtins) readFile dirOf;
  inherit (lib.strings) trim;
  pname = "llm-wiki-compiler";
  source = extraSources.${pname};
in
buildNpmPackage {
  inherit pname;
  inherit (source) version src;
  npmDepsHash = trim (readFile (dirOf source.extract."package-lock.json" + "/npmDepsHash"));
  meta = {
    license = lib.licenses.mit;
    mainProgram = "llmwiki";
  };
}
