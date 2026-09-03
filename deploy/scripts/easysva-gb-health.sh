#!/usr/bin/env bash
# 模块：流媒体协议组 / 部署后健康检查。
# 检查后端、WVP、SIP 与国标专用 ZLMediaKit 的最小可用端点。

set -u

failures=0
env_file="${EASYSVA_GB_ENV_FILE:-/etc/easySVA/gb28181.env}"
if [[ -r "$env_file" ]]; then
    set -a
    # The installer creates this root-owned file with mode 0600.
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
fi
zlm_secret="${GB28181_ZLM_SECRET:-easySVA.GB28181.ZLM}"
web_health_url="${EASYSVA_WEB_HEALTH_URL:-http://127.0.0.1/}"

check_tcp() {
    local name="$1"
    local host="$2"
    local port="$3"
    if timeout 3 bash -c "</dev/tcp/${host}/${port}" 2>/dev/null; then
        printf '[OK]   %s TCP %s:%s\n' "$name" "$host" "$port"
    else
        printf '[FAIL] %s TCP %s:%s\n' "$name" "$host" "$port" >&2
        failures=$((failures + 1))
    fi
}

check_http() {
    local name="$1"
    local url="$2"
    local code
    code="$(curl --noproxy '*' --silent --show-error --output /dev/null --max-time 5 \
        --write-out '%{http_code}' "$url" 2>/dev/null || true)"
    if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
        printf '[OK]   %s HTTP %s (%s)\n' "$name" "$url" "$code"
    else
        printf '[FAIL] %s HTTP %s\n' "$name" "$url" >&2
        failures=$((failures + 1))
    fi
}

check_wvp_api() {
    local endpoint="$1"
    local response
    response="$(curl --noproxy '*' --silent --show-error --fail --max-time 5 \
        "$endpoint" 2>/dev/null || true)"
    if python3 -c 'import json,sys
try:
    result=json.load(sys.stdin)
    data=result.get("data",result)
    valid=result.get("code",0)==0 and isinstance(data,dict) and isinstance(data.get("list"),list)
except (ValueError,AttributeError,TypeError):
    valid=False
sys.exit(0 if valid else 1)' <<<"$response"; then
        printf '[OK]   WVP 设备目录 API %s\n' "$endpoint"
    else
        printf '[FAIL] WVP 设备目录不可用（服务、认证或响应异常）%s\n' "$endpoint" >&2
        failures=$((failures + 1))
    fi
}

check_zlm_api() {
    local endpoint="$1"
    local response
    response="$(curl --noproxy '*' --silent --show-error --fail --get \
        --max-time 5 --data-urlencode "secret=$zlm_secret" "$endpoint" 2>/dev/null || true)"
    if python3 -c 'import json,sys
try:
    result=json.load(sys.stdin)
    valid=isinstance(result,dict) and result.get("code")==0
except (ValueError,TypeError):
    valid=False
sys.exit(0 if valid else 1)' <<<"$response"; then
        printf '[OK]   GB28181 ZLMediaKit API %s\n' "$endpoint"
    else
        printf '[FAIL] GB28181 ZLMediaKit API %s（服务或密钥错误）\n' "$endpoint" >&2
        failures=$((failures + 1))
    fi
}

check_sip_transports() {
    local port="$1"
    local tcp=0
    local udp=0
    ss -H -ltn "sport = :${port}" 2>/dev/null | grep -q . && tcp=1
    ss -H -lun "sport = :${port}" 2>/dev/null | grep -q . && udp=1

    if (( tcp == 1 )); then
        printf '[OK]   GB28181 SIP TCP *:%s\n' "$port"
    else
        printf '[WARN] GB28181 SIP TCP *:%s 未监听\n' "$port"
    fi
    if (( udp == 1 )); then
        printf '[OK]   GB28181 SIP UDP *:%s\n' "$port"
    else
        printf '[WARN] GB28181 SIP UDP *:%s 未监听\n' "$port"
    fi
    if (( tcp == 0 && udp == 0 )); then
        printf '[FAIL] GB28181 SIP %s 无可用传输协议\n' "$port" >&2
        failures=$((failures + 1))
    fi
}

check_tcp "easySVA后端" 127.0.0.1 9114
check_http "easySVA Web" "$web_health_url"
check_tcp "原 RTSP" 127.0.0.1 9994
check_wvp_api 'http://127.0.0.1:18080/api/device/query/devices?page=1&count=1'
check_sip_transports 5060
check_zlm_api http://127.0.0.1:9996/index/api/getApiList
check_tcp "GB28181 RTSP" 127.0.0.1 9997

if (( failures > 0 )); then
    printf 'GB28181健康检查失败，共%s项。\n' "$failures" >&2
    exit 1
fi

echo "GB28181健康检查通过。"
