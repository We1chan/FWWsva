#!/bin/bash
# Fake camera pool: loop-push local test videos into ZLMediaKit as extra RTSP streams.
# Creates distinct pictures for the screen wall: cam2 (BBB), cam3 (jellyfish), cam4 (jellyfish hflip).
ZLM_RTSP=127.0.0.1:9994
VDIR=/opt/SVA/videos
ffmpeg -loglevel error -re -stream_loop -1 -i "$VDIR/bbb.mp4" \
  -c:v libx264 -preset veryfast -tune zerolatency -g 50 -an -f rtsp "rtsp://$ZLM_RTSP/live/cam2" &
FF1=$!
ffmpeg -loglevel error -re -stream_loop -1 -i "$VDIR/jellyfish.mp4" \
  -c:v libx264 -preset veryfast -tune zerolatency -g 50 -an -f rtsp "rtsp://$ZLM_RTSP/live/cam3" &
FF2=$!
ffmpeg -loglevel error -re -stream_loop -1 -i "$VDIR/jellyfish.mp4" -vf hflip \
  -c:v libx264 -preset veryfast -tune zerolatency -g 50 -an -f rtsp "rtsp://$ZLM_RTSP/live/cam4" &
FF3=$!
wait $FF1 $FF2 $FF3
