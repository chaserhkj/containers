{
  buildNpmPackage,
  fetchFromGitHub,
  npm-lockfile-fix,
  nix-update-script,
  lib,
}:
buildNpmPackage rec {
  pname = "opencommit";
  version = "3.3.7";
  src = fetchFromGitHub {
    owner = "di-sukharev";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-VaFJgTwJVzq3Y5ogS8I/A/hP7qpWTV2nmYeKZ6JxGHA=";
    postFetch = ''
      cd $out
      # Fix lockfile issues with bundled dependencies
      ${lib.getExe npm-lockfile-fix} package-lock.json
    '';
  };
  passthru.updateScript = nix-update-script { };
  npmDepsHash = "sha256-j3WWBVwQldltlaZdLCXBNZdCExKgl1NDjjzP8jfn2UU=";
  meta.mainProgram = "oco";
}
