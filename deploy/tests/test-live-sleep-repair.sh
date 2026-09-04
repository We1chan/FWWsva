#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fake="$repo_dir/deploy/scripts/fake-cams-push.sh"
repair="$repo_dir/deploy/scripts/install-sleep-models.sh"

# The source publisher and the monitor proxy must use different ZLM apps.
grep -q 'ZLM_SOURCE_APP=' "$fake"
grep -q 'rtsp://\$ZLM_RTSP/\$ZLM_SOURCE_APP/' "$fake"
if grep -q 'rtsp://\$ZLM_RTSP/live/cam' "$fake"; then
  echo 'fake camera publisher still writes into the monitor output app' >&2
  exit 1
fi

# The production repair path must install the pose model and verify its digest.
test -x "$repair"
grep -q 'yolo11n-pose.onnx' "$repair"
grep -q 'sha256sum -c' "$repair"

echo 'live sleep repair contract passed.'
