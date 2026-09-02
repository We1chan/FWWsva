#!/usr/bin/env bash
# easySVA 阶段2 E2E：GB28181 设备同步、媒体状态刷新、预览/启停分流、剔除离线
# 在 Windows Git Bash 下执行；依赖 curl.exe 与 wsl.exe（DB 取证）。
set -u
BASE=http://127.0.0.1/prod-api
OUT=/c/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase2
export WSL_UTF8=1
WSL="wsl.exe -d Ubuntu-22.04-easySVA -u root -- bash -lc"
MYSQL="mysql -uroot -peasySVA.EZ easySVA"
PY="C:/Users/19904/.workbuddy/binaries/python/versions/3.13.12/python.exe"
TS=$(date +%Y%m%d-%H%M%S)
echo "[$(date '+%F %T')] E2E start; TS=$TS"

# ---------- 0. 登录 ----------
LOGIN=$(curl.exe -sS -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}')
TOKEN=$(printf '%s' "$LOGIN" | sed -E 's/.*"token":"([^"]+)".*/\1/')
echo "$LOGIN" > "$OUT/00-login-$TS.json"
echo "[login] code=$(printf '%s' "$LOGIN" | sed -E 's/.*"code":([0-9]+).*/\1/') token_len=${#TOKEN}"

# ---------- 1. 目录同步：2 个国标通道（cam-01 绑定真实流 / cam-02 绑定幽灵流） ----------
BODY='[
 {"platformId":"34020000002000000001","deviceId":"34020000001320000001","channelId":"34020000001310000001",
  "name":"主井口-国标01","catalogOnline":true,"zlmServerId":1,"vhost":"__defaultVhost__","app":"live",
  "stream":"dev_mock_camera_001","playUrl":"ws://127.0.0.1:9992/live/dev_mock_camera_001.live.flv"},
 {"platformId":"34020000002000000001","deviceId":"34020000001320000001","channelId":"34020000001310000002",
  "name":"副井口-国标02(幽灵流)","catalogOnline":true,"zlmServerId":1,"vhost":"__defaultVhost__","app":"live",
  "stream":"gb-ghost-cam-0002","playUrl":"ws://127.0.0.1:9992/live/gb-ghost-cam-0002.live.flv"}
]'
curl.exe -sS -X POST "$BASE/waring/device/gb28181/catalog/sync?zlmServerId=1" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "$BODY" > "$OUT/01-sync-create-$TS.json"
echo "[01-sync-create] $(cat "$OUT/01-sync-create-$TS.json")"

# ---------- 2. DB 取证：gb28181_channel 与 h_device 镜像 ----------
$WSL "$MYSQL -e \"SELECT device_id,channel_id,channel_name,zlm_server_id,vhost,app,stream,catalog_online,media_online FROM gb28181_channel ORDER BY channel_id;\" 2>&1 | grep -v Warning" > "$OUT/02-db-channels-$TS.txt"
$WSL "$MYSQL -e \"SELECT ape_id,name,device_type,stream_source_type,is_online,monitor_status,gb_device_id,gb_channel_id,zlm_server_id,sync_source FROM h_device WHERE device_type='GB28181' ORDER BY gb_channel_id;\" 2>&1 | grep -v Warning" > "$OUT/03-db-hdevice-after-sync-$TS.txt"
echo "[02-db-channels]"; cat "$OUT/02-db-channels-$TS.txt"
echo "[03-db-hdevice-after-sync]"; cat "$OUT/03-db-hdevice-after-sync-$TS.txt"

# ---------- 3. 状态刷新：available=1（真实流） unavailable=1（幽灵流） ----------
curl.exe -sS -X POST "$BASE/waring/device/gb28181/status/refresh?zlmServerId=1" \
  -H "Authorization: Bearer $TOKEN" > "$OUT/04-refresh-$TS.json"
echo "[04-refresh] $(cat "$OUT/04-refresh-$TS.json")"

# ---------- 4. DB 取证：刷新后在线状态（cam-01 在线 / cam-02 离线） ----------
$WSL "$MYSQL -e \"SELECT ape_id,is_online,monitor_status,gb_channel_id FROM h_device WHERE device_type='GB28181' ORDER BY gb_channel_id;\" 2>&1 | grep -v Warning" > "$OUT/05-db-hdevice-after-refresh-$TS.txt"
$WSL "$MYSQL -e \"SELECT channel_id,media_online,last_media_seen_at FROM gb28181_channel ORDER BY channel_id;\" 2>&1 | grep -v Warning" > "$OUT/06-db-channel-media-$TS.txt"
echo "[05-db-after-refresh]"; cat "$OUT/05-db-hdevice-after-refresh-$TS.txt"
echo "[06-db-channel-media]"; cat "$OUT/06-db-channel-media-$TS.txt"

# ---------- 5. 预览：cam-01 应返回 playUrl；cam-02 离线应报具体原因 ----------
curl.exe -sS "$BASE/waring/device/monitor/gb-34020000001320000001-34020000001310000001/preview" \
  -H "Authorization: Bearer $TOKEN" > "$OUT/07-preview-online-$TS.json"
curl.exe -sS "$BASE/waring/device/monitor/gb-34020000001320000001-34020000001310000002/preview" \
  -H "Authorization: Bearer $TOKEN" > "$OUT/08-preview-offline-$TS.json"
echo "[07-preview-online] $(cat "$OUT/07-preview-online-$TS.json" | head -c 400)"
echo "[08-preview-offline] $(cat "$OUT/08-preview-offline-$TS.json" | head -c 300)"

# ---------- 6. 监控启停分流 ----------
curl.exe -sS -X POST "$BASE/waring/device/monitor/gb-34020000001320000001-34020000001310000001/start" \
  -H "Authorization: Bearer $TOKEN" > "$OUT/09-start-online-$TS.json"
curl.exe -sS -X POST "$BASE/waring/device/monitor/gb-34020000001320000001-34020000001310000002/start" \
  -H "Authorization: Bearer $TOKEN" > "$OUT/10-start-offline-$TS.json"
echo "[09-start-online] $(cat "$OUT/09-start-online-$TS.json" | head -c 400)"
echo "[10-start-offline] $(cat "$OUT/10-start-offline-$TS.json" | head -c 300)"
curl.exe -sS -X POST "$BASE/waring/device/monitor/gb-34020000001320000001-34020000001310000001/stop" \
  -H "Authorization: Bearer $TOKEN" > "$OUT/11-stop-online-$TS.json"
echo "[11-stop-online] $(cat "$OUT/11-stop-online-$TS.json" | head -c 400)"

# ---------- 7. 剔除同步：仅上报 cam-01，cam-02 应被标记离线（目录身份保留） ----------
BODY1='[
 {"platformId":"34020000002000000001","deviceId":"34020000001320000001","channelId":"34020000001310000001",
  "name":"主井口-国标01","catalogOnline":true,"zlmServerId":1,"vhost":"__defaultVhost__","app":"live",
  "stream":"dev_mock_camera_001","playUrl":"ws://127.0.0.1:9992/live/dev_mock_camera_001.live.flv"}
]'
curl.exe -sS -X POST "$BASE/waring/device/gb28181/catalog/sync?zlmServerId=1" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "$BODY1" > "$OUT/12-sync-drop-$TS.json"
echo "[12-sync-drop] $(cat "$OUT/12-sync-drop-$TS.json")"

# ---------- 8. 设备列表回归：全部设备 与 device_type=GB28181 过滤 ----------
curl.exe -sS "$BASE/waring/device/list?pageNum=1&pageSize=20" -H "Authorization: Bearer $TOKEN" > "$OUT/13-list-all-$TS.json"
curl.exe -sS "$BASE/waring/device/list?pageNum=1&pageSize=20&device_type=GB28181" -H "Authorization: Bearer $TOKEN" > "$OUT/14-list-gb28181-$TS.json"
echo "[13-list-all total] $("$PY" -c "import json,sys; d=json.load(open(r'$OUT/13-list-all-$TS.json')); print(d.get('total'))" 2>/dev/null || echo n/a)"
echo "[14-list-gb28181 total] $("$PY" -c "import json,sys; d=json.load(open(r'$OUT/14-list-gb28181-$TS.json')); print(d.get('total'))" 2>/dev/null || echo n/a)"

echo "[$(date '+%F %T')] E2E done -> $OUT"
