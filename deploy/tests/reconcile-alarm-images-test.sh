#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_dir="$(mktemp -d)"
trap '[[ "$test_dir" == /tmp/tmp.* ]] && rm -rf -- "$test_dir"' EXIT

mkdir -p "$test_dir/upload/alarm/task"
printf 'image' > "$test_dir/upload/alarm/task/exists.jpg"
printf 'outside image' > "$test_dir/outside.jpg"
ln -s "$test_dir/outside.jpg" "$test_dir/upload/alarm/task/escape.jpg"
mkdir -p "$test_dir/upload/alarm/task/directory.jpg"

cat > "$test_dir/mysql" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
query="$(cat)"
printf '%s\n' "$query" >> "$MYSQL_QUERY_LOG"
if [[ "$query" == SELECT* ]]; then
  [[ "${FAIL_SELECT:-0}" != 1 ]] || exit 7
  prefix=''
  [[ "$query" != *"CONCAT('x'"* ]] || prefix=x
  row() { printf '%s\t%s%s\t%s%s\n' "$1" "$prefix" "$2" "$prefix" "$3"; }
  row 1 alarm/task/exists.jpg old
  row 2 /alarm/task/missing.jpg old
  row 3 https://old.example/alarm/task/exists.jpg old
  row 4 ../../etc/passwd old
  row 5 alarm/task/escape.jpg old
  row 6 alarm/task/exists.jpg https://sva.example/alarm/task/exists.jpg
  row 7 '' https://old.example/alarm/task/exists.jpg
  row 8 alarm/task/exists.jpg ''
  row 9 alarm/task/directory.jpg old
else
  [[ "${FAIL_UPDATE:-0}" != 1 ]] || exit 8
  printf '1\n'
fi
EOF
chmod +x "$test_dir/mysql"

run_script() {
  MYSQL_BIN="$test_dir/mysql" MYSQL_QUERY_LOG="$test_dir/query.log" \
  ALARM_UPLOAD_ROOT="$test_dir/upload" ALARM_PUBLIC_BASE_URL="${TEST_BASE:-https://sva.example/}" \
  MYSQL_DATABASE=easySVA bash "$repo_dir/deploy/scripts/reconcile-alarm-images.sh" "$@"
}

dry_output="$(run_script)"
grep -q 'would update: 1 -> alarm/task/exists.jpg' <<< "$dry_output"
grep -q 'missing file: 2 -> alarm/task/missing.jpg' <<< "$dry_output"
grep -q 'unsafe path: 4' <<< "$dry_output"
if grep -q '^UPDATE ' "$test_dir/query.log"; then
  echo 'dry-run issued UPDATE' >&2
  exit 1
fi

: > "$test_dir/query.log"
apply_output="$(run_script --apply)"
grep -q 'updated: 1 -> alarm/task/exists.jpg' <<< "$apply_output"
grep -q 'updated: 3 -> alarm/task/exists.jpg' <<< "$apply_output"
if grep -q 'missing.jpg\|passwd' "$test_dir/query.log"; then
  echo 'attempted to update an unavailable or unsafe image' >&2
  exit 1
fi

failures=0
check() {
  if "$@"; then return; fi
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}
check grep -q 'unsafe path: 5' <<< "$dry_output"
check grep -q 'unchanged: 6' <<< "$dry_output"
check grep -q 'would update: 7 -> alarm/task/exists.jpg' <<< "$dry_output"
check grep -q 'would update: 8 -> alarm/task/exists.jpg' <<< "$dry_output"
check grep -q 'missing file: 9' <<< "$dry_output"
check test "$(grep -c '^UPDATE ' "$test_dir/query.log")" = 4
check grep -q 'picture_absolute_url = CONVERT(0x68747470733a2f2f7376612e6578616d706c652f616c61726d2f7461736b2f6578697374732e6a7067 USING utf8mb4)' "$test_dir/query.log"

expect_failure() {
  if "$@" > "$test_dir/error.log" 2>&1; then
    printf 'FAIL: command unexpectedly succeeded: %s\n' "$*" >&2
    failures=$((failures + 1))
  fi
}
expect_failure env FAIL_SELECT=1 MYSQL_BIN="$test_dir/mysql" MYSQL_QUERY_LOG="$test_dir/query.log" ALARM_UPLOAD_ROOT="$test_dir/upload" bash "$repo_dir/deploy/scripts/reconcile-alarm-images.sh"
expect_failure env FAIL_UPDATE=1 MYSQL_BIN="$test_dir/mysql" MYSQL_QUERY_LOG="$test_dir/query.log" ALARM_UPLOAD_ROOT="$test_dir/upload" bash "$repo_dir/deploy/scripts/reconcile-alarm-images.sh" --apply
expect_failure run_script --apply unexpected
TEST_BASE="https://sva.example/x';UPDATE h_waring SET picture_url='evil'--"
expect_failure run_script --apply

[[ "$failures" == 0 ]] || exit 1

echo 'reconcile-alarm-images tests passed.'
