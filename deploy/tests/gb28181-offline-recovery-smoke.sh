#!/usr/bin/env bash
# Stop one easySVA software GB28181 camera, verify offline propagation, restart it,
# and verify registration/recovery. The EXIT trap always restores the camera.

set -euo pipefail

wvp_base_url="${GB28181_WVP_BASE_URL:-http://127.0.0.1:18080}"
backend_base_url="${EASYSVA_BACKEND_BASE_URL:-http://127.0.0.1:9114}"
device_id="${GB28181_TEST_DEVICE_ID:-44010200491320000006}"
unit_name="${GB28181_TEST_UNIT:-easysva-gb-simulator-test6.service}"
offline_timeout="${GB28181_OFFLINE_TIMEOUT_SECONDS:-75}"
online_timeout="${GB28181_ONLINE_TIMEOUT_SECONDS:-45}"
recovery_timeout="${GB28181_RECOVERY_TIMEOUT_SECONDS:-90}"
poll_interval="${GB28181_POLL_INTERVAL_SECONDS:-2}"
simulator_stopped=0
baseline_backend_state=""

for command_name in curl python3 systemctl; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing dependency: %s\n' "$command_name" >&2
        exit 1
    }
done

# Keep the destructive target narrow: this smoke test may stop only a named
# easySVA GB simulator unit, never an arbitrary system service.
if ! [[ "$unit_name" =~ ^easysva-gb-simulator-[A-Za-z0-9_.@-]+\.service$ ]]; then
    printf 'Refusing unsafe simulator unit name: %s\n' "$unit_name" >&2
    exit 1
fi

restore_camera() {
    if (( simulator_stopped == 1 )); then
        printf '[restore] starting %s\n' "$unit_name"
        systemctl start "$unit_name" || true
    fi
}
trap restore_camera EXIT INT TERM

wvp_device_json() {
    curl --noproxy '*' --silent --show-error --fail --max-time 5 \
        "$wvp_base_url/api/device/query/devices?page=1&count=100"
}

wvp_state() {
    wvp_device_json | python3 -c 'import json,sys
device_id=sys.argv[1]
result=json.load(sys.stdin)
items=(result.get("data") or {}).get("list") or []
device=next((item for item in items if item.get("deviceId")==device_id), None)
if device is None:
    print("missing")
else:
    print("online" if device.get("onLine") is True else "offline")' "$device_id"
}

wait_wvp_state() {
    local expected="$1"
    local timeout_seconds="$2"
    local deadline=$((SECONDS + timeout_seconds))
    local actual=""
    while (( SECONDS <= deadline )); do
        actual="$(wvp_state 2>/dev/null || true)"
        if [[ "$actual" == "$expected" ]]; then
            printf '[OK] WVP device %s is %s\n' "$device_id" "$expected"
            return 0
        fi
        sleep "$poll_interval"
    done
    printf '[FAIL] WVP device %s did not become %s (last state: %s)\n' \
        "$device_id" "$expected" "${actual:-unavailable}" >&2
    return 1
}

backend_token=""
login_backend() {
    local username="${EASYSVA_ADMIN_USERNAME:-}"
    local password="${EASYSVA_ADMIN_PASSWORD:-}"
    if [[ -z "$username" && -z "$password" ]]; then
        printf '[skip] backend state check (set EASYSVA_ADMIN_USERNAME and EASYSVA_ADMIN_PASSWORD)\n'
        return 0
    fi
    if [[ -z "$username" || -z "$password" ]]; then
        echo 'Both EASYSVA_ADMIN_USERNAME and EASYSVA_ADMIN_PASSWORD are required.' >&2
        return 1
    fi
    local payload response deadline
    payload="$(python3 -c 'import json,sys; print(json.dumps({"username":sys.argv[1],"password":sys.argv[2]}))' \
        "$username" "$password")"
    deadline=$((SECONDS + 60))
    while (( SECONDS <= deadline )); do
        response="$(curl --noproxy '*' --silent --fail --max-time 8 \
            -H 'Content-Type: application/json' -d "$payload" "$backend_base_url/login" 2>/dev/null || true)"
        backend_token="$(python3 -c 'import json,sys
result=json.load(sys.stdin)
print(result.get("token") or "")' <<<"$response" 2>/dev/null || true)"
        [[ -n "$backend_token" ]] && return 0
        sleep "$poll_interval"
    done
    echo 'Backend login did not become available within 60 seconds.' >&2
    return 1
}

backend_state() {
    curl --noproxy '*' --silent --show-error --fail --get --max-time 5 \
        -H "Authorization: Bearer $backend_token" \
        --data-urlencode 'pageNum=1' --data-urlencode 'pageSize=100' \
        --data-urlencode "gb_device_id=$device_id" \
        "$backend_base_url/waring/device/list" |
        python3 -c 'import json,sys
device_id=sys.argv[1]
result=json.load(sys.stdin)
rows=result.get("rows") or []
row=next((item for item in rows if item.get("gb_device_id")==device_id), None)
if row is None:
    print("missing")
else:
    online=str(row.get("is_online", ""))
    monitor=str(row.get("monitor_status", ""))
    print(("online" if online=="1" else "offline") + ":" + monitor)' "$device_id"
}

wait_backend_online_flag() {
    local expected="$1"
    local timeout_seconds="$2"
    [[ -n "$backend_token" ]] || return 0
    local deadline=$((SECONDS + timeout_seconds))
    local actual=""
    while (( SECONDS <= deadline )); do
        actual="$(backend_state 2>/dev/null || true)"
        if [[ "$actual" == "$expected":* ]]; then
            printf '[OK] backend device %s state is %s\n' "$device_id" "$actual"
            return 0
        fi
        sleep "$poll_interval"
    done
    printf '[FAIL] backend device %s did not become %s (last state: %s)\n' \
        "$device_id" "$expected" "${actual:-unavailable}" >&2
    return 1
}

wait_backend_state() {
    local expected="$1"
    local timeout_seconds="$2"
    [[ -n "$backend_token" ]] || return 0
    local deadline=$((SECONDS + timeout_seconds))
    local actual=""
    while (( SECONDS <= deadline )); do
        actual="$(backend_state 2>/dev/null || true)"
        if [[ "$actual" == "$expected" ]]; then
            printf '[OK] backend device %s state is %s\n' "$device_id" "$actual"
            return 0
        fi
        sleep "$poll_interval"
    done
    printf '[FAIL] backend device %s did not become %s (last state: %s)\n' \
        "$device_id" "$expected" "${actual:-unavailable}" >&2
    return 1
}

systemctl is-active --quiet "$unit_name" || {
    printf 'Simulator unit must already be active: %s\n' "$unit_name" >&2
    exit 1
}
# A cold WSL/systemd boot may need tens of seconds for Java/WVP and the
# simulator's dependency wait to settle before the first registration.
wait_wvp_state online 60
login_backend
wait_backend_online_flag online 20
if [[ -n "$backend_token" ]]; then
    baseline_backend_state="$(backend_state)"
fi

# Make WVP learn the simulator's configured heartbeat interval/count now. This
# also updates devices that were registered before fast smoke-test heartbeats
# were introduced.
printf '[setup] querying heartbeat configuration from %s\n' "$device_id"
heartbeat_response="$(curl --noproxy '*' --silent --show-error --fail --max-time 10 --get \
    --data-urlencode "deviceId=$device_id" \
    "$wvp_base_url/api/device/config/query/basicParam")"
python3 -c 'import json,sys
result=json.load(sys.stdin)
data=result.get("data") or {}
valid=result.get("code")==0 and int(data.get("heartBeatInterval") or 0)>0 and int(data.get("heartBeatCount") or 0)>0
if not valid:
    raise SystemExit("WVP did not learn a valid heartbeat configuration")' <<<"$heartbeat_response"

printf '[test] stopping %s\n' "$unit_name"
systemctl stop "$unit_name"
simulator_stopped=1
wait_wvp_state offline "$offline_timeout"
wait_backend_state offline:STOPPED "$offline_timeout"

printf '[test] restarting %s\n' "$unit_name"
systemctl start "$unit_name"
simulator_stopped=0
wait_wvp_state online "$online_timeout"
wait_backend_online_flag online "$online_timeout"
if [[ "$baseline_backend_state" == "online:RUNNING" ]]; then
    # A persisted RUNNING deployment must trigger re-INVITE and return its
    # monitor session to RUNNING after the device registers again.
    wait_backend_state online:RUNNING "$recovery_timeout"
fi

printf 'GB28181 offline/recovery smoke test passed for %s.\n' "$device_id"
