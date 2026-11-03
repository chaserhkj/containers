# AGENTS.md

Bootable bootc host images: an Arch base built up into host-ready OS images, then per-host
configuration layered on top. The build wrapper, the `CTR_*` env contract, and the podman rule are
in `../AGENTS.md`; this file covers what is specific to `bootc/`.

## Images

Each directory is a build context: a `Containerfile`, an optional `rootfs/`, optionally an ignore
file. Images consume each other by local tag, so the tag of a base image must already be in the
store when a dependent builds.

| Directory | Tag | Base | Adds |
|---|---|---|---|
| `arch-base` | `bootc-arch-base` | build context `bootc-arch` | full-file Arch, kernel overrides, container + VM tooling, `bashrc.d` hook, ssh `authorized_keys.d` |
| `arch-live` | `bootc-arch-live`, `bootc-arch-live-builder` | `bootc-arch`, `bootc-arch-base` | `bootc-live` initramfs, `liveuser`, iwd, install tooling |
| `arch-k0s` | `bootc-arch-k0s` | `bootc-arch-base` | k0s, cri-o, krun, writable `/opt` |
| `arch-common-config` | `bootc-arch-common-config` | `bootc-arch-base` | shared config `rootfs`, nix, shell and CLI tooling |
| `arch-common-home-config` | `bootc-arch-common-home-config` | `bootc-arch-common-config` | config shared between home-premises hosts |
| `arch-k0s-config` | `bootc-arch-k0s-config` | `bootc-arch-k0s` | k0s/crio unit ordering, kubelet storage mounts, cluster provisioning |
| `arch-gui` | `bootc-arch-gui` | `bootc-arch-common-home-config` | niri desktop, pipewire, GUI session units, tpm ssh agent |
| `arch-amd` | variant only | build context `base` | AMD container toolkit, ROCm tools, CDI generation unit |
| `legacy-gaming` | `bootc-legacy-gaming` | `quay.io/fedora/fedora-coreos:stable` | standalone Fedora image, no Justfile recipe |

`arch-amd` has no image of its own: its `FROM base` resolves through the `base` build context, and
it is only ever built by `build-variant-image`.

Upstream `ghcr.io/bootcrew/arch-bootc` ships thinned files. `arch-base` reinstalls every package to
recover them (`PACMAN_REINSTALL_QUERY`), reinstates the `var/` symlinks the `filesystem` package
overrides, and clears the thinned-file options from `pacman.conf`.

## Recipes

`just bootc <recipe>`, from the repo root. These recipes supply the `bootc-` tag prefix; the root
`just build bootc/<dir>` tags with the bare directory name instead.

| Recipe | Effect |
|---|---|
| `build-image <dir>` | tag `bootc-<dir>`, context `<dir>` |
| `build-live-images <distro>` | `<distro>-live` built twice: `--target builder` as `bootc-<distro>-live-builder`, then the final stage |
| `build-variant-image <dir> <new_base>` | build context `base` = `bootc-<new_base>`, tag `bootc-<new_base>-<postfix>`, postfix is `<dir>` minus its first dash-separated segment |
| `build-base-images` | `arch-base`, then `build-live-images arch` |
| `default` | the k0s chain, then the shared configs re-laid as variants |
| `build-all` | `build-base-images` then `default` |

`build-variant-image` rebases a whole directory onto another image, which is how the shared config
`rootfs` trees and `arch-amd` end up on the k0s chain without their own base images:

```
arch-k0s                        -> bootc-arch-k0s
arch-k0s-config                 -> bootc-arch-k0s-config
arch-common-config              -> bootc-arch-common-config
arch-common-home-config         -> bootc-arch-common-home-config
arch-gui                        -> bootc-arch-gui
arch-common-config + k0s-config -> bootc-arch-k0s-config-common-config
  + common-home-config          -> bootc-arch-k0s-config-common-config-common-home-config
  + arch-amd                    -> ...-amd
  + arch-gui                    -> ...-gui
```

A variant reuses its base tag as the tag prefix, so the base must be rebuilt before its variant.

## Build contexts and shared stages

`bootc/Justfile` publishes these names as build contexts, so a `FROM <name>` in a Containerfile
resolves to a local tag or to an image ref from the environment:

| Context name | Env var | Resolves to |
|---|---|---|
| `bootc-arch` | `CTR_BASE_ARCH_BOOTC` | `ghcr.io/bootcrew/arch-bootc:latest` |
| `arch-aur-builder` | `CTR_ARCH_AUR_BUILDER_IMG` | local `arch-aur-builder`; context omitted when unset |
| `base` | set by `build-variant-image` | `bootc-<new_base>` |

Stage names shared across Containerfiles; keep them stable, they are wired through
`--build-context`:

| Stage | Users | Purpose |
|---|---|---|
| `pkg-overrides` | `arch-base`, `arch-live` | kernel and kernel-module packages; `.env` sets `CTR_PKG_OVERRIDES_IMG=arch-pkgs-kernel` |
| `builder-pkg-overrides` | `arch-base`, `arch-live`, `arch-k0s`, `arch-amd`, `arch-common-config` | toolchain packages for `arch-aur-builder` |
| `pkg-builder` | same | `arch-aur-builder` with builder overrides applied |
| `bashrc.d` | `arch-base` | `bashrc.d.sh` appended to `/etc/bash.bashrc` |

AUR packages are built into `/var/build/repo` in a builder stage and installed from
`/etc/pacman-local-repo.conf` (`sitepkgs`), which `arch-base` writes for downstream images.

## Kernel handling

The root `.env` passes `PACMAN_FULL_SYNC_FLAGS` and `PACMAN_REINSTALL_QUERY` that ignore `linux`, so
the base image never installs a distro kernel; `arch-pkgs-kernel` supplies it through
`pkg-overrides`. After any kernel change the build asserts a single `/usr/lib/modules/*` directory
remains and regenerates the initramfs: `dracut` in `arch-base`, the `bootc-live` `initrd-all-mods`
copy in `arch-live`. Kernel arguments go to `/usr/lib/bootc/kargs.d/` (`10-` in `arch-base`, `20-`
in `arch-common-config`).

`/boot` is emptied in both images; the initramfs lives in `/usr/lib/modules/<kver>/initramfs.img`.

## rootfs conventions

- `COPY rootfs /` is the last layer of each image; paths inside `rootfs/` are absolute paths in the
  image.
- Empty directories carry `.gitkeep`, excluded from the build context by a `.containerignore`
  containing `.gitkeep`.
- systemd drop-ins: `<unit>.d/<nn>-<what>.conf`.
- first-boot provisioning chains off `provision-pre.target` or `provision.target` through
  `/usr/lib/systemd/system` units in `arch-common-config`; per-user home content goes to
  `/usr/share/factory/var/home/...` (`arch-gui`) or `/usr/share/user-tmpfiles.d` when the image
  must be able to re-create it.
- runtime state belongs in `/var`; `/opt` is a symlink into `/var`, so images that need a real
  `/opt` (k0s, ROCm) replace the symlink before installing.

## Per-host images

`arch-host-config` is a nested Just module (`just bootc arch-config <recipe>`) that turns a host
directory into a pushed image. `hosts/` is gitignored and holds one directory per host:

| File | Effect |
|---|---|
| `BASE` | base image ref for the first build; `--from` rebases the whole build onto it |
| `PKGS` | newline-separated packages installed from the build context |
| `rootfs/` | host-specific files |
| `setup.sh` | script run at the end of the config stage |
| `Containerfile` | optional extra stage built on the config stage, passed as build context `base` |
| `LIVE` | marker: finish with `Containerfile.live` instead |

`Containerfile` applies host config only: packages, `rootfs`, then the `creds` and `ncps_cred`
secrets (decrypted `creds.gpg`, `ncps_cred.gpg`) — it assumes `bootc-arch-base` unless `BASE` says
otherwise. `Containerfile.live` swaps in a `bootc-live` initramfs built from `bootc-arch-live-builder`.

The chain is config stage → optional host `Containerfile` → optional `Containerfile.live`, each
handing its image id to the next through `*.id` files, staged as
`localhost/bootc-arch-host:<host>` and tagged/pushed to `CTR_ARCH_BOOTC_HOST_TARGET_IMG_REF`.
`prepare-all-persistent` skips `LIVE` hosts, `prepare-all-live` takes only those.

## Verifying

```
just pull-bootc-base-images                      # bootc-arch context, archlinux
just build base/arch-aur-builder
just bootc build-base-images                     # arch-base, arch-live
CTR_BUILD_DRY_RUN=1 just bootc build-image <dir> # confirm flags, args, contexts
just bootc build-image <dir>                     # real podman build
just bootc build-all                             # full image set
just bootc arch-config prepare-all-persistent    # per-host images
```

These images have no entrypoint; inspect with `podman run --rm -it <tag> bash`. Rebuild dependents
when a shared stage changes: `arch-base` feeds every image here, `pkg-overrides` feeds `arch-base`
and `arch-live`, `bashrc.d` feeds `arch-base`.

`just upgrade-all-bootc-images` at the root chains pull → `arch-aur-builder` → `build-all` → pause →
host images.

## Conventions

Commit scopes use the image directory: `fix(arch-base): ...`, `feat(arch-k0s): ...`,
`build(bootc): ...` for `Justfile` changes. Never commit `arch-host-config/hosts/`,
`*.id`, `creds.gpg`, or `ncps_cred.gpg`.
