#!/usr/bin/env bash
# Exercise checksum rejection and recoverable replacement using dummy files only.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
printf 'test pose model\n' > "$test_dir/pose.onnx"
printf 'test eye model\n' > "$test_dir/eye.onnx"
sha="$(sha256sum "$test_dir/pose.onnx" | cut -d ' ' -f 1)"
installer="$repo_dir/deploy/scripts/install-sleep-models.sh"
bash "$installer" "$test_dir/pose.onnx" "$sha" "$test_dir/models" "$test_dir/eye.onnx"
cmp "$test_dir/pose.onnx" "$test_dir/models/yolo11n-pose.onnx"
cmp "$test_dir/eye.onnx" "$test_dir/models/open-closed-eye-0001.onnx"
if bash "$installer" "$test_dir/pose.onnx" "$(printf '%064d' 0)" \
    "$test_dir/models" "$test_dir/eye.onnx" >/dev/null 2>&1; then
    echo 'Invalid digest accepted.' >&2
    exit 1
fi
cmp "$test_dir/pose.onnx" "$test_dir/models/yolo11n-pose.onnx"
bash "$installer" "$test_dir/pose.onnx" "$sha" "$test_dir/models" "$test_dir/eye.onnx"
backups=("$test_dir/models/"*.backup-*)
[[ ${#backups[@]} == 2 ]]
echo 'Sleep model installation tests passed (install, reject without overwrite, backup).'
