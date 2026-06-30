{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "llm-wiki-compiler";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "atomicstrata";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-MvA3R5+tGVSeVEkmKLS/TSq4fbHFEwhRmePMf3SseJo=";
  };

  npmDepsHash = "sha256-saESo+sC2gSQ1V0KQ1FBnrS1InLfeTJ4Kq3zfaMaWsM=";

  meta = {
    license = lib.licenses.mit;
    mainProgram = "llmwiki";
  };
}
