#!/usr/bin/env bash
# 模块：演示视频 RTSP 推流。
# 在 NVIDIA 编码器可实际使用时选择 NVENC，否则自动回退到 CPU libx264。

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "用法: $0 <视频文件> <RTSP 推流地址>" >&2
    exit 2
fi

source_file="$1"
target_url="$2"
# Source installs use /usr/local/bin; distro packages usually use /usr/bin.
ffmpeg_bin="${EASYSVA_FFMPEG_BIN:-$(command -v ffmpeg || true)}"
requested_encoder="${EASYSVA_FFMPEG_H264_ENCODER:-auto}"

if [[ ! -r "$source_file" ]]; then
    echo "模拟摄像头素材不可读: $source_file" >&2
    exit 1
fi
if [[ ! -x "$ffmpeg_bin" ]]; then
    echo "FFmpeg 不可执行: $ffmpeg_bin" >&2
    exit 1
fi

nvenc_works() {
    command -v nvidia-smi >/dev/null 2>&1 &&
        nvidia-smi -L >/dev/null 2>&1 &&
        "$ffmpeg_bin" -hide_banner -loglevel error \
            -f lavfi -i color=size=64x64:rate=1 -frames:v 1 \
            -c:v h264_nvenc -f null - >/dev/null 2>&1
}

case "$requested_encoder" in
    auto)
        if nvenc_works; then
            encoder="h264_nvenc"
        else
            encoder="libx264"
        fi
        ;;
    h264_nvenc)
        if ! nvenc_works; then
            echo "已指定 h264_nvenc，但 NVIDIA 驱动或 NVENC 不可用。" >&2
            exit 1
        fi
        encoder="h264_nvenc"
        ;;
    libx264)
        encoder="libx264"
        ;;
    *)
        echo "不支持的 EASYSVA_FFMPEG_H264_ENCODER: $requested_encoder" >&2
        exit 2
        ;;
esac

echo "模拟摄像头使用 ${encoder}: ${source_file} -> ${target_url}"

common_args=(
    -hide_banner -loglevel warning -re -stream_loop -1 -i "$source_file"
    -map 0:v:0 -an -vf "scale='min(1280,iw)':-2,format=yuv420p"
)

if [[ "$encoder" == "h264_nvenc" ]]; then
    codec_args=(-c:v h264_nvenc -preset p1 -tune ll -g 30 -bf 0)
else
    codec_args=(-c:v libx264 -preset ultrafast -tune zerolatency
        -threads "${EASYSVA_FFMPEG_THREADS:-2}" -g 30 -bf 0)
fi

exec "$ffmpeg_bin" "${common_args[@]}" "${codec_args[@]}" \
    -f rtsp -rtsp_transport tcp "$target_url"
