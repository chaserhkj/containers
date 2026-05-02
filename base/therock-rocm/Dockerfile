# Variant that uses docker/buildkit specific features
# Use ubuntu 24.04 as base image
# Since this is what used by llama.cpp
FROM docker.io/library/ubuntu:24.04 as base

FROM base as therock-base

ARG TARGET_GPU_ARCH=gfx1151
ARG THE_ROCK_VERSION=7.12.0a20260202
ARG THE_ROCK_VARIANT=${TARGET_GPU_ARCH}

ADD --unpack https://therock-nightly-tarball.s3.amazonaws.com/therock-dist-linux-${THE_ROCK_VARIANT}-${THE_ROCK_VERSION}.tar.gz /opt/rocm/

ENV PATH="${PATH}:/opt/rocm/bin" LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/rocm/lib:/opt/rocm/lib/llvm/lib" HIP_PLATFORM=amd

RUN --mount=type=bind,target=/run/mnt bash /run/mnt/deps.sh

FROM therock-base as migraphx
ARG TARGET_GPU_ARCH

COPY --from=ghcr.io/astral-sh/uv:latest / /usr/bin/

RUN --mount=type=bind,target=/run/mnt bash /run/mnt/deps-migraphx.sh

RUN uv venv --python 3.12 /usr/python-env

ENV PATH=/usr/python-env/bin:$PATH VIRTUAL_ENV=/usr/python-env

RUN uv pip install cget git+https://github.com/ROCm/rbuild

RUN git clone https://github.com/ROCm/AMDMIGraphX /work

WORKDIR /work

RUN rbuild package -d depend -B build -DGPU_TARGETS=${TARGET_GPU_ARCH}

RUN mkdir -p /target && \
    tar -C /target -xf /work/build/migraphx-*-Linux-devel.tar.gz && \
    tar -C /target -xf /work/build/migraphx-*-Linux-runtime.tar.gz

FROM therock-base

COPY --from=migraphx /target /