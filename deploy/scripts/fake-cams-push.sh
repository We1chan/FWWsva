#!/bin/bash
# Fake camera pool v2: push real-scene footage into ZLMediaKit.
# cam1=dev_mock_camera_001 (street view, kept by rtsp-simulator)
# cam2=noon-sleep (office napping)   cam3=hflip variant   cam4=zoom close-up
ZLM_RTSP="${EASYSVA_ZLM_RTSP:-127.0.0.1:9994}"
# Input publishers must not collide with the monitor proxies under app=live.
ZLM_SOURCE_APP="${EASYSVA_ZLM_SOURCE_APP:-source}"
VDIR="${EASYSVA_VIDEO_DIR:-/opt/SVA/videos}"

# cam2: office noon-sleep (original 1920x1080)
ffmpeg -loglevel error -re -stream_loop -1 -i "$VDIR/noon-sleep.mp4" \
  -c:v libx264 -preset veryfast -tune zerolatency -g 50 -an -f rtsp "rtsp://$ZLM_RTSP/$ZLM_SOURCE_APP/cam2" &
FF1=$!

# cam3: mirror variant (looks like a second camera)
ffmpeg -loglevel error -re -stream_loop -1 -i "$VDIR/noon-sleep.mp4" -vf hflip \
  -c:v libx264 -preset veryfast -tune zerolatency -g 50 -an -f rtsp "rtsp://$ZLM_RTSP/$ZLM_SOURCE_APP/cam3" &
FF2=$!

# cam4: center zoom close-up variant (third camera view)
ffmpeg -loglevel error -re -stream_loop -1 -i "$VDIR/noon-sleep.mp4" \
  -vf "crop=864:486:528:297,scale=1920:1080" \
  -c:v libx264 -preset veryfast -tune zerolatency -g 50 -an -f rtsp "rtsp://$ZLM_RTSP/$ZLM_SOURCE_APP/cam4" &
FF3=$!

wait $FF1 $FF2 $FF3
