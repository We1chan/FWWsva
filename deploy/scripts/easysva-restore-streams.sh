#!/usr/bin/env bash

set -u

DB_NAME="${EASYSVA_DB_NAME:-easySVA}"
DB_USER="${EASYSVA_DB_USER:-root}"
DB_PASSWORD="${EASYSVA_DB_PASSWORD:-easySVA.EZ}"
MAX_ATTEMPTS="${EASYSVA_STREAM_RESTORE_ATTEMPTS:-10}"

log() {
    printf '[easySVA stream restore] %s\n' "$*"
}

mysql_query() {
    MYSQL_PWD="$DB_PASSWORD" mariadb --batch --skip-column-names \
        --user="$DB_USER" "$DB_NAME" --execute="$1"
}

wait_for_database() {
    local attempt
    for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
        if mysql_query "SELECT 1" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    log "database did not become ready"
    return 1
}

restore_device() {
    local ape_id="$1"
    local source_url="$2"
    local zlm_host="$3"
    local api_port="$4"
    local media_port="$5"
    local app="$6"
    local secret="$7"
    local stream api_base response attempt play_url proxy_key

    stream="$(printf '%s' "$ape_id" | sed 's/[^A-Za-z0-9_-]/_/g')"
    api_base="http://${zlm_host}:${api_port}"

    for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
        response="$(curl --silent --show-error --max-time 20 --get \
            "${api_base}/index/api/addStreamProxy" \
            --data-urlencode "secret=${secret}" \
            --data-urlencode "vhost=__defaultVhost__" \
            --data-urlencode "app=${app}" \
            --data-urlencode "stream=${stream}" \
            --data-urlencode "url=${source_url}" \
            --data-urlencode "enable_mp4=1" \
            --data-urlencode "auto_close=0" 2>&1)" || true

        if grep -Eq '"code"[[:space:]]*:[[:space:]]*0|already exists|already existed' <<<"$response"; then
            play_url="ws://${zlm_host}:${media_port}/${app}/${stream}.live.flv"
            proxy_key="__defaultVhost__/${app}/${stream}"
            mysql_query "UPDATE h_device SET play_url='${play_url}', zlm_proxy_key='${proxy_key}', monitor_status='RUNNING' WHERE ape_id='${ape_id}'" >/dev/null
            log "restored ${ape_id} -> ${play_url}"
            return 0
        fi

        if ((attempt < MAX_ATTEMPTS)); then
            sleep 1
        fi
    done

    log "failed ${ape_id}: ${response//$'\n'/ }"
    return 1
}

wait_for_database || exit 1

query="
SELECT d.ape_id,
       d.direct_source_url,
       z.host,
       z.api_port,
       z.media_http_port,
       COALESCE(NULLIF(z.app, ''), 'live'),
       COALESCE(z.secret, '')
FROM h_device d
JOIN zlm_server z ON z.id = d.zlm_server_id AND z.enabled = 1
WHERE UPPER(d.stream_source_type) = 'DIRECT'
  AND UPPER(d.monitor_status) = 'RUNNING'
  AND d.direct_source_url IS NOT NULL
  AND d.direct_source_url <> '';
"

restored=0
failed=0
while IFS=$'\t' read -r ape_id source_url zlm_host api_port media_port app secret; do
    [[ -n "$ape_id" ]] || continue
    if restore_device "$ape_id" "$source_url" "$zlm_host" "$api_port" "$media_port" "$app" "$secret"; then
        ((restored += 1))
    else
        ((failed += 1))
    fi
done < <(mysql_query "$query")

log "finished: restored=${restored}, failed=${failed}"
# A temporarily unavailable public stream must not prevent the rest of easySVA
# from starting. Individual failures remain visible in the service journal.
exit 0
