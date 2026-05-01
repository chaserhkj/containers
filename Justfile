mod bootc 'bootc/'
mod distro 'distrobox/'

set dotenv-load := true

export CTR_BUILD_TOOL := env("CTR_BUILD_TOOL", "podman")
export CTR_BUILD_FLAGS := env("CTR_BUILD_FLAGS", "")

build context:
    tag=$(basename {{context}}) && \
    ${CTR_BUILD_TOOL} build {{context}} -t $tag ${CTR_BUILD_FLAGS}

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