# Adapted and changed from https://github.com/dryvist/nix-ai/blob/main/modules/cecli/package.nix
# which is licensed under Apache 2.0
#
# cecli — Nix Python derivation
#
# cecli (cecli-dev on PyPI) is the maintained fork of Aider. Built from
# the PyPI sdist via buildPythonApplication. Mirrors the shape of
# modules/fabric/package.nix.
#
# One inline let-bound mini-derivation remain:
#
#   - py-cymbal (wheel) — Cymbal code-indexing native bindings; not in
#     nixpkgs at all. Wheel selection is platform-conditional (darwin
#     macOS arm64 vs linux manylinux2014 x86_64).
#
# Usage: pkgs.callPackage ./package.nix { }

{
  lib,
  stdenv,
  python3Packages,
  fetchPypi,
  fetchurl,
}:

let
  pyCymbalVersion = "0.1.24";
  py-cymbal = python3Packages.buildPythonPackage {
    pname = "py-cymbal";
    version = pyCymbalVersion;
    format = "wheel";
    src =
      if stdenv.isDarwin then
        fetchurl {
          url = "https://files.pythonhosted.org/packages/d9/02/58e39f04acbd2bd344f2f6dbdd70d191346817e0cade3c8c0311d3eeca95/py_cymbal-0.1.24-py3-none-macosx_11_0_arm64.whl";
          hash = "sha256-2A7libnzODdew8aOvZbOe3a2ZWlFlvhRj/kmXxeF01Q=";
        }
      else
        fetchurl {
          url = "https://files.pythonhosted.org/packages/70/52/646d527a501468562110aa10ca8805b01f11cada5b9de87fad428c0b8ab4/py_cymbal-0.1.24-py3-none-manylinux_2_17_x86_64.whl";
          hash = "sha256-QXLcVLGk0Qcrx+8fdiq9HWOcLQUmYd+QeRKjiJCrcvE=";
        };
    doCheck = false;
    pythonImportsCheck = [ "cymbal" ];
  };
  ngramVersion = "4.0.3";
  ngram = python3Packages.buildPythonPackage rec {
    pname = "ngram";
    version = ngramVersion;
    pyproject = true;
    build-system = with python3Packages; [ setuptools ];
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-BtGAnuL+3dztYGXc0ZgmxhMYeH1Hv08QscAReD1BmqY=";
    };
  };

  version = "0.100.9";
in
python3Packages.buildPythonApplication {
  pname = "cecli";
  inherit version;
  pyproject = true;

  # PyPI normalizes the dist filename underscore (cecli_dev) but the
  # canonical package name uses a hyphen. fetchPypi takes the file-side
  # name; pname above is what shows up in `pip list`.
  src = fetchPypi {
    pname = "cecli_dev";
    inherit version;
    hash = "sha256-wrt5AfcM+6q+wEYiWF+LmcsaK1pujYZqggbTW9RV1HU=";
  };

  # Relaxing soft pins from cecli for versions that might not exist in nixpkgs
  #
  # cecli's pyproject.toml uses dynamic deps sourced from
  # requirements/requirements.in (NOT inline pin strings), so the
  # substitutions target that file.
  postPatch = ''
    substituteInPlace requirements/requirements.in \
      --replace-quiet 'tree-sitter-language-pack<=0.13.0' 'tree-sitter-language-pack' \
      --replace-quiet 'json-repair>=0.60.1' 'json-repair'
  '';

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
    wheel
  ];

  dependencies =
    (with python3Packages; [
      pydub
      configargparse
      gitpython
      jsonschema
      rich
      prompt-toolkit
      backoff
      pathspec
      diskcache
      packaging
      sounddevice
      soundfile
      beautifulsoup4
      pyyaml
      pypandoc
      litellm
      flake8
      importlib-resources
      pyperclip
      pexpect
      json5
      psutil
      watchfiles
      socksio
      json-repair
      marisa-trie
      rapidfuzz
      pillow
      shtab
      oslex
      textual
      tomlkit
      truststore
      xxhash
      rustworkx
      scipy
      importlib-metadata
      tree-sitter
      diff-match-patch
      tree-sitter-c-sharp
      tree-sitter-embedded-template
      tree-sitter-yaml
      tree-sitter-language-pack
      mcp
    ])
    ++ [
      ngram
      py-cymbal
    ];

  # Tests need network (litellm provider calls) and audio devices
  # (pydub/sounddevice). Skip in Nix sandbox. The pythonImportsCheck
  # of the entry point at $out/bin/cecli runs separately as a smoke
  # test of the install layout.
  doCheck = false;
  pythonImportsCheck = [ "cecli" ];

  meta = with lib; {
    description = "AI pair-programming CLI (maintained fork of Aider)";
    homepage = "https://github.com/cecli-dev/cecli";
    license = licenses.asl20;
    mainProgram = "cecli";
    platforms = [
      "x86_64-linux"
    ];
  };
}
