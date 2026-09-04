#!/usr/bin/env bash
# Test encoder selection without requiring NVIDIA hardware or opening a stream.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
mkdir "$test_dir/bin"
touch "$test_dir/input.mp4"
cat > "$test_dir/bin/nvidia-smi" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
cat > "$test_dir/bin/ffmpeg" <<'MOCK'
#!/usr/bin/env bash
if [[ "$*" == *'-frames:v 1'* ]]; then
    [[ "${MOCK_NVENC:-0}" == '1' ]]
    exit $?
fi
printf '%s\n' "$@"
MOCK
chmod +x "$test_dir/bin/ffmpeg" "$test_dir/bin/nvidia-smi"
export PATH="$test_dir/bin:$PATH"
unset EASYSVA_FFMPEG_BIN EASYSVA_FFMPEG_H264_ENCODER
simulator="$repo_dir/deploy/scripts/easysva-rtsp-simulator.sh"

output="$(MOCK_NVENC=0 bash "$simulator" "$test_dir/input.mp4" rtsp://localhost:9994/live/test)"
grep -qx libx264 <<< "$output"
grep -q "min(1280,iw)" <<< "$output"
output="$(MOCK_NVENC=1 bash "$simulator" "$test_dir/input.mp4" rtsp://localhost:9994/live/test)"
grep -qx h264_nvenc <<< "$output"
output="$(MOCK_NVENC=1 EASYSVA_FFMPEG_H264_ENCODER=libx264 bash "$simulator" "$test_dir/input.mp4" rtsp://localhost:9994/live/test)"
grep -qx libx264 <<< "$output"
if MOCK_NVENC=0 EASYSVA_FFMPEG_H264_ENCODER=h264_nvenc \
    bash "$simulator" "$test_dir/input.mp4" rtsp://localhost:9994/live/test >/dev/null 2>&1; then
    echo 'Explicit unusable NVENC was accepted.' >&2
    exit 1
fi
echo 'RTSP simulator encoder-selection tests passed (CPU, GPU mock, override, rejection).'
