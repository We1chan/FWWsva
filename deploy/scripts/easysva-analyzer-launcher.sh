#!/usr/bin/env bash

set -u

SERVER_DIR="/opt/SVA/server"
CPU_ORT_DIR="/usr/local/onnxruntime"
GPU_ORT_DIR="/usr/local/onnxruntime-gpu"
CUDA_LIB_DIR="/usr/local/cuda-13.1/lib64"
CUDNN_LIB_DIR="/opt/SVA/cudnn/nvidia/cudnn/lib"
WSL_GPU_LIB_DIR="/usr/lib/wsl/lib"
SYSTEM_LIB_PATH="/usr/local/lib:/usr/lib/x86_64-linux-gnu"
GPU_LIBRARY_PATH="$GPU_ORT_DIR/lib:$CUDA_LIB_DIR:$CUDNN_LIB_DIR:$WSL_GPU_LIB_DIR:$SYSTEM_LIB_PATH"

gpu_unavailable_reason=""
nvidia_smi_binary=""

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia_smi_binary="$(command -v nvidia-smi)"
elif [[ -x "$WSL_GPU_LIB_DIR/nvidia-smi" ]]; then
    nvidia_smi_binary="$WSL_GPU_LIB_DIR/nvidia-smi"
fi

if [[ ! -x "$SERVER_DIR/Analyzer-gpu" ]]; then
    gpu_unavailable_reason="Analyzer-gpu 不存在"
elif [[ ! -f "$GPU_ORT_DIR/lib/libonnxruntime_providers_cuda.so" ]]; then
    gpu_unavailable_reason="GPU 版 ONNX Runtime 不存在"
elif [[ -z "$nvidia_smi_binary" ]]; then
    gpu_unavailable_reason="未找到 nvidia-smi"
elif ! "$nvidia_smi_binary" -L >/dev/null 2>&1; then
    gpu_unavailable_reason="未检测到可用的 NVIDIA GPU/驱动"
elif LD_LIBRARY_PATH="$GPU_LIBRARY_PATH" \
    ldd "$GPU_ORT_DIR/lib/libonnxruntime_providers_cuda.so" 2>/dev/null | grep -q "not found"; then
    gpu_unavailable_reason="CUDA/cuDNN 运行库不完整"
else
    echo "[easySVA] 检测到 NVIDIA GPU，启动 Analyzer-gpu（CUDAExecutionProvider）"
    export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"
    export LD_LIBRARY_PATH="$GPU_LIBRARY_PATH"
    exec "$SERVER_DIR/Analyzer-gpu" "$@"
fi

echo "[easySVA] $gpu_unavailable_reason，自动使用 CPU Analyzer"

if [[ -x "$SERVER_DIR/Analyzer.cpu" ]]; then
    cpu_binary="$SERVER_DIR/Analyzer.cpu"
elif [[ -x "$SERVER_DIR/Analyzer" ]]; then
    cpu_binary="$SERVER_DIR/Analyzer"
else
    echo "[easySVA] 错误：未找到可执行的 CPU Analyzer" >&2
    exit 1
fi

export LD_LIBRARY_PATH="$CPU_ORT_DIR/lib:$SYSTEM_LIB_PATH"
exec "$cpu_binary" "$@"
