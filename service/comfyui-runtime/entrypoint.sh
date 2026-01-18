#!/bin/bash
set -eu

CLI_ARGS="$@"
CLI_ARGS+=" --listen 127.8.8.1 --port 8000"
CLI_ARGS+=" --log-stdout"
CLI_ARGS+=" --use-pytorch-cross-attention"
# This enables bf16 to fp16 conversion
# On some platforms this is faster, but might create precision problems with vae
#CLI_ARGS+=" --fast"
# Disable mmap and model unload for UMA platforms
#CLI_ARGS+=" --disable-mmap"
#CLI_ARGS+=" --highvram"
# Force non blocking loading of weights
# This makes sense on most platforms, but not much on UMA
CLI_ARGS+=" --force-non-blocking"

# ROCM-specific optimizations
# These are architecture and device dependent
# Enable by need
# Some cards (gfx1151) heavily relies on AOTRITON to work
# export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
# export FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE"
# export FLASH_ATTENTION_TRITON_AMD_AUTOTUNE="TRUE"

# Memory allocation, mainly for stability of some cards
# export PYTORCH_HIP_ALLOC_CONF=expandable_segments:True

# Auto Tuning in pytorch, sometimes helpful
# export PYTORCH_TUNABLEOP_ENABLED=1

# MIOpen is auto tuning dispatcher library for ROCm (cudnn)
# ComfyUI disables MIOpen on AMD for default
# Set to enable
# export COMFYUI_ENABLE_MIOPEN=1
# Force a backend for GEMM, some cards need this to avoid crash
# export MIOPEN_GEMM_ENFORCE_BACKEND=5
# MIOpen find mode
# export MIOPEN_FIND_MODE=5
# MIOpen logging
# export MIOPEN_LOG_LEVEL=5
# export MIOPEN_ENABLE_LOGGING=1
# export MIOPEN_ENABLE_LOGGING_CMD=1

# MIGraphX is graph optimization library (TensorRT)
# MIGraphX on ROCm is used by ONNX as backend
# Force MIGraphX to do listed optimizations regardless of hardware
# export MIGRAPHX_MLIR_USE_SPECIFIC_OPS="attention"
# Force a backend for GEMM, some cards need this to avoid crash
# export MIGRAPHX_SET_GEMM_PROVIDER=hipblaslt


# General logging for AMD platforms
# export AMD_LOG_LEVEL=3

source /venv/bin/activate
echo "[INFO] Prestart ENV exported"

# Run custom install script, as provided by the mount point
if [[ -f /app/install.sh ]]; then
    echo "[INFO] Running custom install script"
    bash /app/install.sh
fi

if [[ ! -f /venv/COMFYUI_CUSTOM_NODES_FIXED ]] || 
    [[ ! -f /app/COMFYUI_CUSTOM_NODES_UPDATED ]] || 
    [[ /app/COMFYUI_CUSTOM_NODES_UPDATED -nt /venv/COMFYUI_CUSTOM_NODES_FIXED ]]; then
    echo "[INFO] Running ComfyUI-Manager fix"
    python3 /app/ComfyUI/custom_nodes/ComfyUI-Manager/cm-cli.py fix all
    touch /venv/COMFYUI_CUSTOM_NODES_FIXED
fi
echo "[INFO] Running ComfyUI-Manager update"
python3 /app/ComfyUI/custom_nodes/ComfyUI-Manager/cm-cli.py update all

echo "[INFO] Starting main ComfyUI process"
exec python3 /app/ComfyUI/main.py $CLI_ARGS