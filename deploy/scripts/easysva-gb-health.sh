#!/usr/bin/env bash
# 模块：流媒体协议组 / 部署后健康检查。
# 检查后端、WVP、SIP 与国标专用 ZLMediaKit 的最小可用端点。

set -u

failures=0

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
    if [[ "$code" =~ ^[1-5][0-9][0-9]$ ]]; then
        printf '[OK]   %s HTTP %s (%s)\n' "$name" "$url" "$code"
    else
        printf '[FAIL] %s HTTP %s\n' "$name" "$url" >&2
        failures=$((failures + 1))
    fi
}

check_udp_listener() {
    local name="$1"
    local port="$2"
    if ss -H -lun "sport = :${port}" 2>/dev/null | grep -q .; then
        printf '[OK]   %s UDP 0.0.0.0:%s\n' "$name" "$port"
    else
        printf '[FAIL] %s UDP 0.0.0.0:%s\n' "$name" "$port" >&2
        failures=$((failures + 1))
    fi
}

check_tcp_listener() {
    local name="$1"
    local port="$2"
    if ss -H -ltn "sport = :${port}" 2>/dev/null | grep -q .; then
        printf '[OK]   %s TCP *:%s\n' "$name" "$port"
    else
        printf '[FAIL] %s TCP *:%s\n' "$name" "$port" >&2
        failures=$((failures + 1))
    fi
}

check_tcp "easySVA后端" 127.0.0.1 9114
check_http "WVP" http://127.0.0.1:18080/
check_tcp_listener "GB28181 SIP" 5060
check_udp_listener "GB28181 SIP" 5060
check_http "GB28181 ZLMediaKit" http://127.0.0.1:9996/
check_tcp "GB28181 RTSP" 127.0.0.1 9997

if (( failures > 0 )); then
    printf 'GB28181健康检查失败，共%s项。\n' "$failures" >&2
    exit 1
fi

echo "GB28181健康检查通过。"
