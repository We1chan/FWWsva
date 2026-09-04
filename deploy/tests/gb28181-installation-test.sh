#!/usr/bin/env bash
# 模块：流媒体协议组 / 安装集成测试。
# 以测试替身验证脚本、服务依赖、配置透传与输入校验，不修改真实部署目录。

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
launcher="$repo_dir/deploy/scripts/easysva-wvp-launcher.sh"
simulator_launcher="$repo_dir/deploy/scripts/easysva-gb-simulator-launcher.sh"
health="$repo_dir/deploy/scripts/easysva-gb-health.sh"

bash -n "$repo_dir/install_source.sh"
bash -n "$launcher"
bash -n "$simulator_launcher"
bash -n "$health"

grep -q 'EASYSVA_MEDIA_SERVER_REF:-95eda58fcf3e8ed401d404f825cfbc434362af34' "$repo_dir/install_source.sh"
grep -q 'EASYSVA_SERVER_REF:-f49d60183014117152607be2b592a72776db6f9f' "$repo_dir/install_source.sh"
grep -q 'EASYSVA_BACKEND_REF:-bc978100a6c3bdcea0d6da542ca064c83dde1369' "$repo_dir/install_source.sh"
grep -q 'EASYSVA_WEB_REF:-6012ed5dc2d2a10b9948af84bb23168ce59306f8' "$repo_dir/install_source.sh"
grep -q 'EASYSVA_GB_SIMULATOR_REF:-1da9bc62134d4cb1fd4374f733583fb5997c3f0a' "$repo_dir/install_source.sh"
grep -q 'sbgb28181-fixed-local-port.patch' "$repo_dir/install_source.sh"
grep -q 'git -C "$target_dir" fetch --depth=1 origin "$ref"' "$repo_dir/install_source.sh"
grep -q 'java-17-openjdk-amd64' "$repo_dir/deploy/systemd/easysva-backend.service"
grep -q '001_extend_h_device.sql' "$repo_dir/install_source.sh"
grep -q '20260901_gb28181_business.sql' "$repo_dir/install_source.sh"
grep -q '20260903_mixed_gb_rtsp_sources.sql' "$repo_dir/install_source.sh"
grep -q '002_add_gb_stream_url.sql' "$repo_dir/install_source.sh"
grep -q 'easysva-gb-media easysva-wvp' "$repo_dir/install_source.sh"
grep -q 'easysva-gb-simulator-test6' "$repo_dir/install_source.sh"
grep -q 'easysva-gb-simulator-test3' "$repo_dir/install_source.sh"
grep -q 'GB28181_LOCAL_PORT=15066' "$repo_dir/deploy/systemd/easysva-gb-simulator-test6.service"
grep -q 'GB28181_LOCAL_PORT=15063' "$repo_dir/deploy/systemd/easysva-gb-simulator-test3.service"
grep -q 'location /gb-media/' "$repo_dir/install_source.sh"
grep -q 'location /live/' "$repo_dir/install_source.sh"
grep -q 'location /analyzer/' "$repo_dir/install_source.sh"
grep -q 'proxy_pass http://127.0.0.1:9996/' "$repo_dir/deploy/nginx-easysva.conf"
grep -q -- '--local-port "$local_port"' "$simulator_launcher"
grep -q 'EASYSVA_GB_ENV_FILE:-/etc/easySVA/gb28181.env' "$health"
grep -q 'EASYSVA_WEB_HEALTH_URL:-http://127.0.0.1/' "$health"
grep -q -- '--data-urlencode "secret=$zlm_secret"' "$health"
grep -q 'check_tcp "原 RTSP" 127.0.0.1 9994' "$health"

if EASYSVA_WVP_DB_NAME='invalid-name' bash "$repo_dir/install_source.sh" \
    > /dev/null 2>&1; then
    echo "安装器接受了非法数据库名。" >&2
    exit 1
fi

test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

if command -v systemd-analyze >/dev/null 2>&1; then
    unit_dir="$test_dir/systemd"
    mkdir -p "$unit_dir"
    cp "$repo_dir/deploy/systemd/easysva-gb-media.service" \
        "$repo_dir/deploy/systemd/easysva-wvp.service" \
        "$repo_dir/deploy/systemd/easysva-gb-simulator-test6.service" \
        "$repo_dir/deploy/systemd/easysva-gb-simulator-test3.service" \
        "$repo_dir/deploy/systemd/easysva-rtsp-simulator.service" \
        "$repo_dir/deploy/systemd/easysva-rtsp-simulator-3.service" \
        "$repo_dir/deploy/systemd/easysva-media.service" \
        "$repo_dir/deploy/systemd/easysva-backend.service" "$unit_dir/"
    chmod 0644 "$unit_dir"/*.service
    sed -i 's#^ExecStart=.*#ExecStart=/bin/true#' "$unit_dir"/*.service
    for dependency in mariadb redis-server; do
        cat > "$unit_dir/${dependency}.service" <<EOF
[Unit]
Description=Test double for ${dependency}
[Service]
Type=oneshot
ExecStart=/bin/true
EOF
    done
    systemd-analyze verify "$unit_dir"/*.service
fi

touch "$test_dir/wvp.jar" "$test_dir/wvp.yml"
cat > "$test_dir/gb28181.env" <<'EOF'
WVP_DB_USERNAME=wvp_test
WVP_DB_PASSWORD=test_password
GB28181_SIP_PASSWORD=test_sip_password
GB28181_ZLM_SECRET=test_zlm_secret
SPRING_DATASOURCE_URL=jdbc:mysql://127.0.0.1:3306/wvp_test
GB28181_HOST_IP=192.0.2.10
EOF

cat > "$test_dir/java" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$WVP_DB_USERNAME" "$WVP_DB_PASSWORD" "$GB28181_SIP_PASSWORD" \
    "$GB28181_ZLM_SECRET" "$SPRING_DATASOURCE_URL" "$GB28181_HOST_IP" "$*"
EOF
chmod +x "$test_dir/java"

launcher_output="$(
    EASYSVA_GB_ENV_FILE="$test_dir/gb28181.env" \
    EASYSVA_JAVA21_BIN="$test_dir/java" \
    EASYSVA_WVP_JAR="$test_dir/wvp.jar" \
    EASYSVA_WVP_CONFIG="$test_dir/wvp.yml" \
    EASYSVA_SKIP_DEPENDENCY_WAIT=1 \
        "$launcher" --acceptance-test
)"

grep -q '^wvp_test$' <<< "$launcher_output"
grep -q '^test_password$' <<< "$launcher_output"
grep -q '^test_sip_password$' <<< "$launcher_output"
grep -q '^test_zlm_secret$' <<< "$launcher_output"
grep -q '^jdbc:mysql://127.0.0.1:3306/wvp_test$' <<< "$launcher_output"
grep -q '^192.0.2.10$' <<< "$launcher_output"
grep -q -- '-jar .*wvp.jar --spring.config.additional-location=file:.*wvp.yml --acceptance-test' \
    <<< "$launcher_output"

echo "GB28181安装集成测试通过。"
