#!/usr/bin/env bash
set -u

# Publish the four deployed test inputs under a private app.
# easysva-restore-streams.sh creates the public live/* proxy streams consumed
# by Analyzer and the web UI.
ZLM_RTSP="${ZLM_RTSP:-127.0.0.1:9994}"
ZLM_SOURCE_APP="${ZLM_SOURCE_APP:-source}"
VDIR="${VDIR:-/opt/SVA/videos}"

CAM1_VIDEO="${CAM1_VIDEO:-$VDIR/v1-test6.mp4}"
CAM2_VIDEO="${CAM2_VIDEO:-$VDIR/v2-test8.mp4}"
CAM3_VIDEO="${CAM3_VIDEO:-$VDIR/v3-office-sleep.mp4}"
CAM4_VIDEO="${CAM4_VIDEO:-$VDIR/v4-desk-sleep.mp4}"

for video in "$CAM1_VIDEO" "$CAM2_VIDEO" "$CAM3_VIDEO" "$CAM4_VIDEO"; do
  if [[ ! -r "$video" ]]; then
    echo "fake camera input is missing: $video" >&2
    exit 1
  fi
done

run_camera() {
  local stream="$1"
  local video="$2"
  shift 2
  while true; do
    # -rw_timeout makes a dead RTSP socket terminate instead of leaving ffmpeg
    # stuck forever after ZLMediaKit is restarted. The loop then reconnects.
    ffmpeg -hide_banner -loglevel warning -rw_timeout 5000000 -re \
      -stream_loop -1 -i "$video" "$@" \
      -c:v libx264 -preset veryfast -tune zerolatency -g 50 -an -f rtsp \
      "rtsp://$ZLM_RTSP/$ZLM_SOURCE_APP/$stream"
    sleep 2
  done
}

run_camera cam1 "$CAM1_VIDEO" &
FF1=$!
run_camera cam2 "$CAM2_VIDEO" &
FF2=$!
run_camera cam3 "$CAM3_VIDEO" &
FF3=$!
run_camera cam4 "$CAM4_VIDEO" &
FF4=$!

wait "$FF1" "$FF2" "$FF3" "$FF4"
