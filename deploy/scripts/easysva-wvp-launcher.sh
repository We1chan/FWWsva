#!/usr/bin/env bash

set -euo pipefail

env_file="${EASYSVA_GB_ENV_FILE:-/etc/easySVA/gb28181.env}"
java_bin="${EASYSVA_JAVA21_BIN:-/usr/lib/jvm/java-21-openjdk-amd64/bin/java}"
wvp_jar="${EASYSVA_WVP_JAR:-/opt/SVA/wvp/wvp-pro.jar}"
wvp_config="${EASYSVA_WVP_CONFIG:-/opt/SVA/gb28181/wvp.yml}"

if [[ ! -r "$env_file" ]]; then
    echo "[easySVA] 无法读取GB28181环境文件: $env_file" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$env_file"

if [[ -z "${GB28181_HOST_IP:-}" ]]; then
    GB28181_HOST_IP="$(ip -4 route get 1.1.1.1 2>/dev/null |
        awk '{for (i = 1; i <= NF; i++) if ($i == "src") {print $(i + 1); exit}}')"
fi
if [[ -z "${GB28181_HOST_IP:-}" ]]; then
    GB28181_HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

required_vars=(
    WVP_DB_USERNAME
    WVP_DB_PASSWORD
    GB28181_SIP_PASSWORD
    GB28181_ZLM_SECRET
    SPRING_DATASOURCE_URL
    GB28181_HOST_IP
)
for var_name in "${required_vars[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
        echo "[easySVA] 缺少必需配置: $var_name" >&2
        exit 1
    fi
done

if [[ ! -x "$java_bin" ]]; then
    echo "[easySVA] Java 21不可执行: $java_bin" >&2
    exit 1
fi
if [[ ! -r "$wvp_jar" ]]; then
    echo "[easySVA] WVP程序不存在: $wvp_jar" >&2
    exit 1
fi
if [[ ! -r "$wvp_config" ]]; then
    echo "[easySVA] WVP配置不存在: $wvp_config" >&2
    exit 1
fi

export WVP_DB_USERNAME WVP_DB_PASSWORD
export GB28181_SIP_PASSWORD GB28181_ZLM_SECRET GB28181_HOST_IP
export SPRING_DATASOURCE_URL

wait_for_tcp() {
    local name="$1"
    local host="$2"
    local port="$3"
    local attempt
    for attempt in $(seq 1 60); do
        if timeout 1 bash -c "</dev/tcp/${host}/${port}" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    echo "[easySVA] 等待${name}超时: ${host}:${port}" >&2
    return 1
}

if [[ "${EASYSVA_SKIP_DEPENDENCY_WAIT:-0}" != "1" ]]; then
    wait_for_tcp "MariaDB" 127.0.0.1 3306
    wait_for_tcp "Redis" 127.0.0.1 6379
    wait_for_tcp "GB28181 ZLMediaKit" 127.0.0.1 9996
fi

echo "[easySVA] 启动WVP，SIP监听地址: ${GB28181_HOST_IP}:5060"
exec "$java_bin" -jar "$wvp_jar" \
    "--spring.config.additional-location=file:${wvp_config}" "$@"
