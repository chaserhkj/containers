{
  lib,
  pythonInterpreters,
  callPackage,
  callPackages,
  # External inputs
  pyproject-nix,
  pyproject-build-systems,
  uv2nix,
  extraSources,
}:
let
  pname = "graphrag";
  source = extraSources.${pname};
  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = source.src;
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
