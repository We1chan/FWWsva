#!/usr/bin/env bash
# Reconcile h_waring image URLs with files that actually exist on the nginx alarm volume.
# Default is report-only.  Pass --apply to update only rows with a non-empty local image.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: reconcile-alarm-images.sh [--apply]

Environment (optional):
  MYSQL_BIN                 mysql client path (default: mysql)
  MYSQL_HOST/PORT/USER      database connection settings
  MYSQL_DATABASE            database name (default: easySVA)
  MYSQL_PASSWORD            password; supplied to mysql through MYSQL_PWD
  ALARM_UPLOAD_ROOT         upload root containing alarm/ (default: /var/www/SVA-web/upload)
  ALARM_PUBLIC_BASE_URL     public site base URL (default: http://127.0.0.1)
EOF
}

apply=false
[[ "$#" -le 1 ]] || { usage >&2; exit 2; }
case "${1:-}" in
    '') ;;
    --apply) apply=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

mysql_bin="${MYSQL_BIN:-mysql}"
database="${MYSQL_DATABASE:-easySVA}"
upload_root="${ALARM_UPLOAD_ROOT:-/var/www/SVA-web/upload}"
public_base="${ALARM_PUBLIC_BASE_URL:-http://127.0.0.1}"
public_base="${public_base%/}"

public_base_pattern='^https?://([-A-Za-z0-9.]+|\[[0-9A-Fa-f:]+\])(:[0-9]+)?(/[A-Za-z0-9._~%/-]*)?$'
if [[ ! "$public_base" =~ $public_base_pattern ]]; then
    echo "ALARM_PUBLIC_BASE_URL must be an http(s) origin (optionally one path prefix)." >&2
    exit 2
fi
upload_root="$(realpath -e -- "$upload_root")"
[[ -d "$upload_root/alarm" ]] || { echo 'Upload root must contain alarm/.' >&2; exit 2; }

mysql_args=(--batch --skip-column-names)
[[ -n "${MYSQL_HOST:-}" ]] && mysql_args+=(--host "$MYSQL_HOST")
[[ -n "${MYSQL_PORT:-}" ]] && mysql_args+=(--port "$MYSQL_PORT")
[[ -n "${MYSQL_USER:-}" ]] && mysql_args+=(--user "$MYSQL_USER")
export MYSQL_PWD="${MYSQL_PASSWORD:-${MYSQL_PWD:-}}"

mysql_query() {
    "$mysql_bin" "${mysql_args[@]}" --database="$database"
}

# Hex literals are independent of quote/backslash SQL modes and never interpolate SQL.
sql_string() {
    local hex
    hex="$(printf '%s' "$1" | od -An -v -tx1 | tr -d ' \n')"
    if [[ -z "$hex" ]]; then printf "''"; else printf 'CONVERT(0x%s USING utf8mb4)' "$hex"; fi
}

# Echo a normalized path relative to ALARM_UPLOAD_ROOT, or return non-zero.
normalize_alarm_path() {
    local raw="$1" path
    path="${raw%%\?*}"
    path="${path%%\#*}"
    if [[ "$path" =~ ^https?://[^/]+(/.*)?$ ]]; then
        path="${path#http://}"
        path="${path#https://}"
        [[ "$path" == */* ]] || return 1
        path="${path#*/}"
    fi
    path="${path#/}"
    [[ "$path" == alarm/* ]] || return 1
    [[ "$path" != *'..'* && "$path" != *\\* && "$path" != *'//' ]] || return 1
    [[ "$path" =~ ^alarm/[A-Za-z0-9._/-]+$ ]] || return 1
    printf '%s\n' "$path"
}

if $apply; then
    echo 'Apply mode: updating only existing, non-empty files.'
else
    echo 'Dry-run: no database rows will be changed. Use --apply to update eligible rows.'
fi

# Prefix nullable text columns so Bash does not collapse empty tab-separated fields.
# Capture and check the SELECT before processing; process substitution hides its exit code.
if ! rows="$(mysql_query <<'SQL'
SELECT w_id, CONCAT('x', COALESCE(picture_url, '')), CONCAT('x', COALESCE(picture_absolute_url, ''))
FROM h_waring
WHERE COALESCE(picture_url, '') <> '' OR COALESCE(picture_absolute_url, '') <> ''
ORDER BY w_id;
SQL
)"; then
    echo 'Image inventory SELECT failed; no updates attempted.' >&2
    exit 1
fi

selected=0 eligible=0 missing=0 unsafe=0 updated=0 unchanged=0 conflicted=0
while IFS=$'\t' read -r w_id picture_url picture_absolute_url; do
    [[ -n "$w_id" ]] || continue
    [[ "$w_id" =~ ^[0-9]+$ ]] || { echo "invalid row id skipped: $w_id" >&2; continue; }
    [[ "$picture_url" == x* && "$picture_absolute_url" == x* ]] || { echo 'Malformed inventory row.' >&2; exit 1; }
    picture_url="${picture_url#x}"
    picture_absolute_url="${picture_absolute_url#x}"
    ((selected+=1))
    raw_path="${picture_url:-${picture_absolute_url:-}}"
    if ! relative_path="$(normalize_alarm_path "$raw_path")"; then
        echo "unsafe path: $w_id -> ${raw_path:-<empty>}"
        ((unsafe+=1))
        continue
    fi
    image_path="$upload_root/$relative_path"
    if [[ ! -f "$image_path" || ! -s "$image_path" ]]; then
        echo "missing file: $w_id -> $relative_path"
        ((missing+=1))
        continue
    fi
    resolved_path="$(realpath -e -- "$image_path")"
    if [[ "$resolved_path" != "$upload_root/alarm/"* ]]; then
        echo "unsafe path: $w_id -> $relative_path (outside alarm directory)"
        ((unsafe+=1))
        continue
    fi
    absolute_url="$public_base/$relative_path"
    if [[ "$picture_url" == "$relative_path" && "$picture_absolute_url" == "$absolute_url" ]]; then
        echo "unchanged: $w_id -> $relative_path"
        ((unchanged+=1))
        continue
    fi
    ((eligible+=1))
    if ! $apply; then
        echo "would update: $w_id -> $relative_path"
        continue
    fi
    # Do not overwrite a concurrent edit after the inventory snapshot.
    sql="UPDATE h_waring SET picture_url = $(sql_string "$relative_path"), picture_absolute_url = $(sql_string "$absolute_url") WHERE w_id = $w_id AND BINARY COALESCE(picture_url, '') = $(sql_string "$picture_url") AND BINARY COALESCE(picture_absolute_url, '') = $(sql_string "$picture_absolute_url"); SELECT ROW_COUNT();"
    affected="$(printf '%s\n' "$sql" | mysql_query)"
    if [[ "$affected" == 0 ]]; then
        echo "concurrent change skipped: $w_id"
        ((conflicted+=1))
        continue
    fi
    [[ "$affected" == 1 ]] || { echo "Unexpected update result for $w_id." >&2; exit 1; }
    echo "updated: $w_id -> $relative_path"
    ((updated+=1))
done <<< "$rows"

echo "summary: selected=$selected eligible=$eligible missing=$missing unsafe=$unsafe unchanged=$unchanged updated=$updated conflicted=$conflicted"
