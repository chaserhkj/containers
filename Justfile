mod bootc 'bootc/'
mod distro 'distrobox/'

set dotenv-load := true

export buildImageScript := justfile_directory() / "build-image.sh"

export CTR_BUILD_TOOL := env("CTR_BUILD_TOOL", "podman")

export CTR_BUILD_CONTEXT_FROM_ARCH_BASE := "archlinux"
export CTR_BUILD_CONTEXT_IMG_ARCH_BASE := env(
    "CTR_BASE_ARCH",
    "docker.io/archlinux/archlinux:latest"
    )

build context:
    tag=$(basename {{context}}) && \
    ${buildImageScript} {{context}} -t $tag

pull-bootc-base-images:
    ${CTR_BUILD_TOOL} pull \
        archlinux/archlinux:latest \
        ghcr.io/bootcrew/arch-bootc:latest

upgrade-all-bootc-images:
    just pull-bootc-base-images
    just build base/arch-aur-builder
    just bootc build-all
    echo "Enter to continue" && read
    just bootc arch-config prepare-all-images