{
  lib,
  fetchFromGitHub,
  pythonInterpreters,
  callPackage,
  callPackages,
  # External inputs
  pyproject-nix,
  pyproject-build-systems,
  uv2nix,
}:
let
  pname = "openkb";
  version = "0.4.3";
  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = fetchFromGitHub {
      owner = "vectifyai";
      repo = "openkb";
      rev = "v${version}";
      hash = "sha256-uerCUku2dbl2rzJRNJzC6r/+M7OgCk95b/8c8E+aF/Q=";
    };
  };
  python = lib.head (
    pyproject-nix.lib.util.filterPythonInterpreters {
      inherit (workspace) requires-python;
      inherit pythonInterpreters;
    }
  );
  pythonBase = callPackage pyproject-nix.build.packages { inherit python; };
  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };
  pythonSet = pythonBase.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      overlay
    ]
  );
  venv = pythonSet.mkVirtualEnv "${pname}-env" {
    ${pname} = [ ];
  };
  inherit (callPackages pyproject-nix.build.util { }) mkApplication;
in
mkApplication {
  inherit venv;
  package = pythonSet.${pname};
}
