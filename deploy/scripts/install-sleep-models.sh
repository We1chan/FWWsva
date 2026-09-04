#!/usr/bin/env bash
# 模块：CPU/GPU 共用的睡岗模型部署。只复制经过摘要校验的模型，不启动任务或服务。
# 用法：install-sleep-models.sh <pose.onnx> <sha256> [model-dir] [eye.onnx]
set -euo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
    echo "Usage: $0 <pose.onnx> <sha256> [model-dir] [eye.onnx]" >&2
    exit 2
fi
pose_source="$1"
expected_sha="$2"
model_dir="${3:-/opt/SVA/models}"
eye_source="${4:-/opt/SVA/SVA-server/prototypes/sleep_pose/models/open-closed-eye-0001.onnx}"
if [[ ! "$expected_sha" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo 'Expected pose SHA-256 must contain exactly 64 hex digits.' >&2
    exit 2
fi
for model in "$pose_source" "$eye_source"; do
    [[ -s "$model" ]] || { echo "Missing or empty model: $model" >&2; exit 1; }
done

# Verify before changing any deployed model. A differently exported model needs
# its own trusted digest; never silently fall back to an unchecked download.
printf '%s  %s\n' "$expected_sha" "$pose_source" | sha256sum -c -
install -d "$model_dir"
stamp="$(date +%Y%m%d-%H%M%S)-$$"
for filename in yolo11n-pose.onnx open-closed-eye-0001.onnx; do
    if [[ -f "$model_dir/$filename" ]]; then
        cp -p -- "$model_dir/$filename" "$model_dir/$filename.backup-$stamp"
    fi
done
if [[ "$(readlink -f "$pose_source")" != "$(readlink -m "$model_dir/yolo11n-pose.onnx")" ]]; then
    install -m 0644 "$pose_source" "$model_dir/yolo11n-pose.onnx"
fi
if [[ "$(readlink -f "$eye_source")" != "$(readlink -m "$model_dir/open-closed-eye-0001.onnx")" ]]; then
    install -m 0644 "$eye_source" "$model_dir/open-closed-eye-0001.onnx"
fi
printf '%s  %s\n' "$expected_sha" "$model_dir/yolo11n-pose.onnx" | sha256sum -c -
echo 'Models installed. Restart Analyzer explicitly, verify its provider/load logs, then start one task.'
