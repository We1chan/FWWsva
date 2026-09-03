#!/usr/bin/env bash
# Verify health failures with HTTP/API responses without touching live services.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin"
cat > "$test_dir/bin/timeout" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$test_dir/bin/ss" <<'EOF'
#!/usr/bin/env bash
echo 'LISTEN 0 128 *:5060'
EOF
cat > "$test_dir/bin/curl" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *18080*)
    if [[ "$*" == *write-out* ]]; then printf '%s' "${TEST_HTTP_STATUS:-200}";
    else printf '%s' "${TEST_WVP_BODY}"; fi ;;
  *9996*) printf '%s' "${TEST_ZLM_BODY}" ;;
  *) printf '%s' '200' ;;
esac
EOF
chmod +x "$test_dir/bin/"*
export PATH="$test_dir/bin:$PATH" EASYSVA_GB_ENV_FILE="$test_dir/missing.env"
export TEST_WVP_BODY='{"code":0,"data":{"list":[],"total":0}}'
export TEST_ZLM_BODY='{"code":0,"data":["getApiList"]}'
health="$repo_dir/deploy/scripts/easysva-gb-health.sh"
bash "$health" > "$test_dir/result.log" 2>&1
export TEST_HTTP_STATUS=500 TEST_WVP_BODY='{"code":500,"msg":"database unavailable"}'
if bash "$health" > "$test_dir/result.log" 2>&1; then
  echo 'FAIL: WVP HTTP/API 500 was reported healthy'; exit 1
fi
export TEST_HTTP_STATUS=200 TEST_WVP_BODY='{"code":401,"msg":"login required"}'
if bash "$health" > "$test_dir/result.log" 2>&1; then
  echo 'FAIL: WVP authentication failure was reported healthy'; exit 1
fi
export TEST_WVP_BODY='<html>login</html>'
if bash "$health" > "$test_dir/result.log" 2>&1; then
  echo 'FAIL: WVP HTML response was reported healthy'; exit 1
fi
export TEST_WVP_BODY='{"code":0,"data":{"list":[],"total":0}}' TEST_ZLM_BODY='{"code":0BROKEN}'
if bash "$health" > "$test_dir/result.log" 2>&1; then
  echo 'FAIL: malformed ZLM JSON was reported healthy'; exit 1
fi
echo 'GB28181 health response tests passed (success, HTTP/API error, authentication, HTML, malformed JSON).'
