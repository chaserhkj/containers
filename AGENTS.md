# AGENTS.md

Personal collection of Containerfiles and image definitions: bootc host images, distrobox
images, service images, and nix2container images. Images are published to
`ghcr.io/chaserhkj/containers/`.

## Layout

| Path | Content |
|---|---|
| `bootc/` | bootable bootc host images; see `bootc/AGENTS.md` |
| `distrobox/` | distrobox images, `arch` → `arch-common-gui` → `arch-generic` / `arch-steam` |
| `base/` | reusable bases referenced by local tag (`arch-aur-builder`, `therock-rocm`, `uv-podman`, `pytorch`), plus `stdio-unix-socket/` as a scratch base |
| `build/` | package-only images consumed as build contexts (`arch-pkgs-kernel`, `therock-pytorch-wheel`) |
| `service/` | one service per directory, mostly with an entrypoint |
| `nix/` | flake-parts images, packages, and nvfetcher sources |
| `builder/`, `agent-sandbox/` | general-purpose sandbox images |

`service/crio-krun` is a git submodule; run `git submodule update --init` before building it.

## Rule: container builds and build tests use podman

Every container build, build test, and image inspection runs through **podman**. The sandboxes agents
run in are provisioned with podman only, so `docker` is either absent or a client without a working
daemon; a `docker build` is not evidence that a build works.

For image tests (does it start, does the entrypoint work) use `podman run`. Images needing nested
containers (`builder/`, `base/uv-podman`, `service/crio-krun`) need rootful podman with
`--privileged` or the host podman socket bind-mounted.

## Build entry points

`Justfile` (root) + `build-image.sh` are the generic wrapper: recipes set `CTR_*` env vars,
`build-image.sh` converts them into a podman command line.

```
just build <dir>            # tag = basename <dir>; e.g. just build build/arch-pkgs-kernel
CTR_BUILD_DRY_RUN=1 just build <dir>   # print the podman command instead of running it
```

The tag is the bare directory name, which only suits trees that reference each other by that name.
Nested trees need their own module, which supplies the tag prefix and the build contexts:
`just bootc build-image <dir>`, `just distro build <variant>`.

Wrapper env vars (all optional, `build-image.sh` documents them):

| Variable | Effect |
|---|---|
| `CTR_BUILD_TOOL` | engine, default `podman` |
| `CTR_BUILD_TOOL_SUB_CMD` | subcommand, default `build` |
| `CTR_BUILD_ARG_<NAME>` | becomes `--build-arg <NAME>` with the same value |
| `CTR_BUILD_CONTEXT_FROM_<ID>` / `CTR_BUILD_CONTEXT_IMG_<ID>` | becomes `--build-context <from>=container-image://<img>` |
| `CTR_BUILD_FROM` | `--from` (rebases the whole build onto an image id) |
| `CTR_BUILD_FLAGS` | extra flags, split on whitespace |
| `CTR_DEBUG` | `set -x` |

`.env` (committed, loaded by `just`) supplies the shared defaults: base image refs, the
kernel-ignore build args, and `CTR_PKG_OVERRIDES_IMG`.

Group-specific wrappers:
- `just bootc ...` — bootc images, tags `bootc-<dir>`. `build-variant-image` rebases a directory onto
  another image through the build context `base` (`CTR_BUILD_CONTEXT_FROM_VARIANT_BASE` /
  `_IMG_VARIANT_BASE`); `bootc/AGENTS.md` lists the chain.
- `just bootc arch-config ...` — per-host images; reads gitignored `hosts/`, decrypts
  `creds.gpg` / `ncps_cred.gpg`, pushes to `CTR_ARCH_BOOTC_HOST_TARGET_IMG_REF` (default
  `docker.io/chaserhkj/arch-bootc-host`, the one image here published to Docker Hub rather than
  GHCR). `CTR_PUSH_FLAGS`, `CTR_PUSH_RETRIES`, `CTR_PUSH_RETRY_BACKOFF` tune that push.
- `just distro build <variant>` — distrobox images, tags `distrobox-<variant>`. The recipe reads
  `CTR_BUILD_FLAGS`, which nothing exports, so it must be set (even empty) or `just` aborts.
- `service/vibevoice/build.sh` — clones a vendor repo before `podman build`.

## Build order

Containerfiles reference sibling images by local tag (`arch-aur-builder`, `bootc-arch-base`,
`therock-rocm`, `arch-pkgs-kernel`), so prerequisites must exist in the local store first:

```
just pull-bootc-base-images            # archlinux + bootc base
just build base/arch-aur-builder
just build build/arch-pkgs-kernel      # .env: CTR_PKG_OVERRIDES_IMG
just bootc build-all                   # base images, live images, host image set
```

`just upgrade-all-bootc-images` chains the whole sequence. Source for shared stages is layered
under stage names inside each Containerfile (`pkg-overrides`, `builder-pkg-overrides`,
`pkg-builder`, `bashrc.d`); keep those names stable, they are wired through build contexts.

## Verifying a change

A change is verified when the affected image builds with podman and, for services, runs:

```
CTR_BUILD_DRY_RUN=1 just build <dir>   # confirm flags/contexts/args
just build <dir>                       # real podman build
podman run --rm -it <tag>              # entrypoint smoke test
podman run --rm -it <tag> bash         # images without an entrypoint
```

Images here carry no `ENTRYPOINT` or `CMD` except where a service needs one; `bootc/`, `distrobox/`,
and `build/` are all of that kind, as are several `service/` images.

Rebuild dependents when a shared stage changes (arch-base change → every bootc image and distrobox
image consuming it).

## Nix images

`flake.nix` wires flake-parts modules from `nix/lib`:

- `nix/lib/containers.nix` — `containers.<name>`, nix2container definitions, default prefix
  `ghcr.io/chaserhkj/containers/`, `buildFixedEntrypointVariant` adds a `/bin/entrypoint.sh`
  wrapper variant.
- `nix/lib/containerizedApps.nix` — wraps a package with tini + its entrypoint.
- `nix/lib/devshellContainers.nix` — devshell wrapped as an image.
- `nix/images.nix` — image declarations (`nix/services/`, `nix/tools/`, `nix/environments/`).

Commands: `nix build .#<name>` for the image, `nix run .#<name>.copyToRegistry` to push,
`nix run .#<name>.fixedEntrypointVariant.copyTo -- oci:/oci:latest` for an OCI layout.
`Containerfile.nix2container` builds one of these with podman from a plain container engine
(`--build-arg TARGET=<name>`).

Packages in `nix/packages/` are built from `extraSources` in `nix/_sources/generated.nix`, generated
by nvfetcher from `nix/nvfetcher.toml`. After editing `nvfetcher.toml`, run
`nix run .#update-extra-deps` (`nix/meta/default.nix`) — it runs nvfetcher and regenerates the
`gomod2nix.toml` / `npmDepsHash` lock files under each `nix/_sources/sha256-*/`. Those lock files and
`generated.nix` are script output: edit `nvfetcher.toml`, never the generated files.

## CI

`.github/workflows/` builds and pushes to GHCR. Each workflow is path-filtered, so a new image
directory needs both a job and a `paths:` entry, otherwise CI never sees it. `build-weekly.yaml`,
`build-the-rock.yaml`, and `build-rocm-prebuilt.yaml` also run on a Tue/Fri cron;
`build-rocm-arch.yaml` is `workflow_call`-only, invoked by `build-the-rock.yaml` and
`build-rocm-prebuilt.yaml`. For a nix image, `paths:` lists its defining file individually
(`nix/services/<name>.nix`, `nix/tools/<name>.nix`, `nix/environments/<name>.nix`) — a new one needs
its own entry, `nix/lib/**` does not cover it. Push/publish logic lives in the workflow, not in the
Containerfile.

## Conventions

- Commit subjects: conventional commits, scope is the image or area directory —
  `build(arch-base): ...`, `fix(amd-ctk): ...`, `feat(term-agents): ...`, `chore(gitignore): ...`.
  Types in use: `feat`, `fix`, `build`, `refactor`, `chore`, `ci`, `docs`.
- Containerfile naming: `Containerfile` (plus `Dockerfile` only where an upstream build expects it).
- Nix: 2-space indent, `nixfmt`-ish layout. No formatter or linter is wired up; match surrounding
  style.
- Validation steps that look repeatable get a `just` recipe, not a shell script in the repo root.

## Never commit

- `bootc/arch-host-config/hosts/`, `*.id`, `creds.gpg`, `ncps_cred.gpg` — real host config and
  credentials (listed in `bootc/arch-host-config/.gitignore`).
- `.bwsand.profile.bash`, `.envrc` — local sandbox/shell config.

## Task tracking

Tasks live in `backlog/` (Backlog.md). Load the `backlog` skill before touching them; use the
`backlog` CLI rather than editing task markdown directly.
