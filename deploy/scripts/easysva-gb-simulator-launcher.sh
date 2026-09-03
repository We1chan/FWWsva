#!/usr/bin/env bash
# Run one pinned sbgb28181 software camera from systemd.
# The media source may be an internal RTSP loop, but the easySVA-facing path is
# SIP registration -> WVP INVITE -> PS/RTP -> the dedicated GB ZLMediaKit.

set -euo pipefail

env_file="${EASYSVA_GB_ENV_FILE:-/etc/easySVA/gb28181.env}"
simulator_root="${EASYSVA_GB_SIMULATOR_DIR:-/opt/SVA/sbgb28181}"
plugin_build="$simulator_root/gst-gb28181sink/build"
wvp_base_url="${GB28181_WVP_BASE_URL:-http://127.0.0.1:18080}"
server_ip="${GB28181_SERVER_IP:-127.0.0.1}"
local_ip="${GB28181_LOCAL_IP:-127.0.0.1}"
local_port="${GB28181_LOCAL_PORT:-0}"

if [[ -r "$env_file" ]]; then
    # shellcheck disable=SC1090
    source "$env_file"
fi

: "${GB28181_DEVICE_ID:?GB28181_DEVICE_ID is required}"
: "${GB28181_CHANNEL_ID:?GB28181_CHANNEL_ID is required}"
: "${GB28181_SIMULATOR_SOURCE:?GB28181_SIMULATOR_SOURCE is required}"
: "${GB28181_SIP_PASSWORD:?GB28181_SIP_PASSWORD is required}"

server_id="${GB28181_SERVER_ID:-44010200492000000001}"
domain="${GB28181_DOMAIN:-4401020049}"

for command_name in curl gst-inspect-1.0 python3; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing GB28181 simulator dependency: %s\n' "$command_name" >&2
        exit 1
    }
done

[[ -f "$simulator_root/gb28181_pusher.py" ]] || {
    printf 'GB28181 simulator is not installed at %s\n' "$simulator_root" >&2
    exit 1
}
[[ -f "$plugin_build/libgstgb28181sink.so" ]] || {
    printf 'GB28181 GStreamer plugin is not built at %s\n' "$plugin_build" >&2
    exit 1
}

for _ in $(seq 1 60); do
    if curl --noproxy '*' --fail --silent --max-time 2 \
        "$wvp_base_url/api/device/query/devices?page=1&count=1" >/dev/null; then
        break
    fi
    sleep 1
done
curl --noproxy '*' --fail --silent --max-time 2 \
    "$wvp_base_url/api/device/query/devices?page=1&count=1" >/dev/null

export GST_PLUGIN_PATH="$plugin_build${GST_PLUGIN_PATH:+:$GST_PLUGIN_PATH}"
export GST_REGISTRY="/run/easysva-gst-${GB28181_DEVICE_ID}.bin"
gst-inspect-1.0 gb28181sink >/dev/null
gst-inspect-1.0 x264enc >/dev/null
gst-inspect-1.0 mpegpsmux >/dev/null

# Registration happens after the Python process starts. Pin the media transport
# to UDP as soon as WVP sees this software device.
(
    for _ in $(seq 1 60); do
        response="$(curl --noproxy '*' --silent --max-time 2 -X POST \
            "$wvp_base_url/api/device/query/transport/${GB28181_DEVICE_ID}/UDP" 2>/dev/null || true)"
        if grep -Eq '"code"[[:space:]]*:[[:space:]]*0' <<<"$response"; then
            exit 0
        fi
        sleep 1
    done
) &

exec python3 "$simulator_root/gb28181_pusher.py" \
    --server-ip "$server_ip" \
    --server-port 5060 \
    --server-id "$server_id" \
    --domain "$domain" \
    --agent-id "$GB28181_DEVICE_ID" \
    --agent-password "$GB28181_SIP_PASSWORD" \
    --channel-id "$GB28181_CHANNEL_ID" \
    --source "$GB28181_SIMULATOR_SOURCE" \
    --udp \
    --local-ip "$local_ip" \
    --local-port "$local_port"
