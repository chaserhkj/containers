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
  pname = "graphrag";
  version = "3.1.1";
  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = fetchFromGitHub {
      owner = "microsoft";
      repo = "graphrag";
      rev = "v${version}";
      hash = "sha256-SE4n8d2N9HKygxeRIZrDy7T127/aKIokzAbWey8UUmk=";
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
