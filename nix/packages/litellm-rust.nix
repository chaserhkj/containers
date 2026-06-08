{
  lib,
  rustPlatform,
  fetchFromGitHub
}: rustPlatform.buildRustPackage rec {
  pname = "litellm-rust";
  version = "git";
  src = fetchFromGitHub {
    owner = "LiteLLM-Labs";
    repo = pname;
    rev = "25683a2a718e7f64c0d04dec02f00eedf73b94c0";
    hash = "sha256-Jy6y7LqFUEu1C5lTKHXwrMkDoysF5gv2kYe8btKKuQM=";
  };
  cargoHash = "sha256-xYKuy3L+58xVGuJCDyP2Qc33DLO7tokg2Gh+HaLp2D8=";
  cargoDepsName = pname;
  meta.mainProgram = pname;
}