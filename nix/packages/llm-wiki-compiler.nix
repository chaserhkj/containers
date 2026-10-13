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

  # npm pack omits the workspace packages (root package.json `files` lists only
  # dist/, so packages/*/ is pruned), yet node_modules keeps npm's relative
  # symlinks to them. Copy the built packages into $out so those symlinks resolve.
  postInstall = ''
    for ws in llmwiki-core llmwiki-local-workflows; do
      target="$out/lib/node_modules/llm-wiki-compiler/packages/$ws"
      mkdir -p "$(dirname "$target")"
      cp -r "packages/$ws" "$target"
    done
  '';
}
