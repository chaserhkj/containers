{ 
  rustPlatform,
  extraSources,
} : let 
  pname = "smart-commit-rs";
  source = extraSources.${pname};
in rustPlatform.buildRustPackage {
  inherit pname;
  inherit (source) version src;
  cargoLock = source.cargoLock."Cargo.lock";
  doCheck = false;
  meta.mainProgram = "cgen";
}