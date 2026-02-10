mod bootc 'bootc/'
mod distro 'distrobox/'


build_flags := env("PODMAN_BUILD_FLAGS", "")

build context:
    tag=$(basename {{context}}) && \
    podman build {{context}} -t $tag {{build_flags}}

build-all-bootc:
    just build base/arch-aur-builder
    just bootc build-all
    just bootc arch-config prepare-all-images