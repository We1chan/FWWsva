#!/usr/bin/env bash
# 定时刷新取证：将 cam-01 强制置为离线，等待一个 @Scheduled(60s) 周期，观察自动恢复。
set -u
export MYSQL_PWD=easySVA.EZ
DB="mysql -uroot easySVA"
Q1="UPDATE h_device SET is_online='2', monitor_status='STOPPED' WHERE ape_id='gb-34020000001320000001-34020000001310000001';"
Q2="UPDATE gb28181_channel SET media_online=0, last_media_seen_at=NULL WHERE device_id='34020000001320000001' AND channel_id='34020000001310000001';"

echo "[flip $(date '+%F %T')] 强制 cam-01 离线"
$DB -e "$Q1" 2>/dev/null
$DB -e "$Q2" 2>/dev/null
$DB -e "SELECT ape_id,is_online,monitor_status FROM h_device WHERE device_type='GB28181' AND gb_channel_id='34020000001310000001';" 2>/dev/null
$DB -e "SELECT channel_id,media_online,last_media_seen_at FROM gb28181_channel WHERE channel_id='34020000001310000001';" 2>/dev/null

echo "[wait $(date '+%F %T')] 等待 80 秒（@Scheduled 60s 周期）..."
sleep 80

echo "[check $(date '+%F %T')] 期望被定时任务自动恢复"
$DB -e "SELECT ape_id,is_online,monitor_status FROM h_device WHERE device_type='GB28181' AND gb_channel_id='34020000001310000001';" 2>/dev/null
$DB -e "SELECT channel_id,media_online,last_media_seen_at FROM gb28181_channel WHERE channel_id='34020000001310000001';" 2>/dev/null
echo "[done]"
