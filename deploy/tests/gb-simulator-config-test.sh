#!/usr/bin/env bash
# Verify cross-machine SIP configuration without opening sockets or using GStreamer.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/simulator/gst-gb28181sink/build"
touch "$test_dir/simulator/gb28181_pusher.py" \
    "$test_dir/simulator/gst-gb28181sink/build/libgstgb28181sink.so"
cat > "$test_dir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
printf '{"code":0}\n'
MOCK
cat > "$test_dir/bin/gst-inspect-1.0" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
cat > "$test_dir/bin/python3" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$@"
MOCK
cat > "$test_dir/bin/ip" <<'MOCK'
#!/usr/bin/env bash
echo '1.1.1.1 via 192.0.2.1 dev eth0 src 192.0.2.20 uid 0'
MOCK
chmod +x "$test_dir/bin/"*
export PATH="$test_dir/bin:$PATH"
export EASYSVA_GB_SIMULATOR_DIR="$test_dir/simulator"
export EASYSVA_GB_ENV_FILE="$test_dir/camera.env"
export GB28181_DEVICE_ID=44010200491320000003 GB28181_CHANNEL_ID=44010200491320000013
export GB28181_SIMULATOR_SOURCE=test GB28181_SIP_PASSWORD=test-only
unset GB28181_HOST_IP GB28181_SERVER_IP GB28181_LOCAL_IP GB28181_SIP_PORT \
    GB28181_HEARTBEAT_INTERVAL GB28181_HEARTBEAT_COUNT
cat > "$EASYSVA_GB_ENV_FILE" <<'CONFIG'
GB28181_HOST_IP=192.0.2.30
GB28181_SIP_PORT=15060
CONFIG
launcher="$repo_dir/deploy/scripts/easysva-gb-simulator-launcher.sh"
output="$(bash "$launcher")"
[[ "$(grep -c '^192.0.2.30$' <<< "$output")" == 2 ]]
grep -qx 15060 <<< "$output"
grep -qx 60 <<< "$output"
grep -qx 3 <<< "$output"
output="$(GB28181_SERVER_IP=192.0.2.40 GB28181_LOCAL_IP=192.0.2.41 bash "$launcher")"
grep -qx 192.0.2.40 <<< "$output"
grep -qx 192.0.2.41 <<< "$output"
output="$(EASYSVA_GB_ENV_FILE="$test_dir/missing.env" bash "$launcher")"
[[ "$(grep -c '^192.0.2.20$' <<< "$output")" == 2 ]]
output="$(GB28181_HEARTBEAT_INTERVAL=10 GB28181_HEARTBEAT_COUNT=2 bash "$launcher")"
grep -qx 10 <<< "$output"
grep -qx 2 <<< "$output"
if GB28181_HEARTBEAT_INTERVAL=0 bash "$launcher" >/dev/null 2>&1; then
    echo 'GB simulator launcher accepted an invalid heartbeat interval.' >&2
    exit 1
fi
echo 'GB simulator configuration tests passed (env file, IPs, heartbeat and auto detection).'
