#!/bin/bash
export WSL_UTF8=1
MYSQL="mysql -uroot -p'easySVA.EZ' easySVA -N"

# 清空旧的（表当前为空，保险起见）
$MYSQL -e "DELETE FROM h_screen_wall_stream;" 2>/dev/null

$MYSQL -e "INSERT INTO h_screen_wall_stream (wall_code, source_type, source_id, device_id, play_url, title, slot_index, enabled) VALUES
('main','stream','cam1','dev_mock_camera_001','/live/dev_mock_camera_001.live.flv','模拟RTSP摄像头-街景',1,1),
('main','stream','cam2','cam2','/live/cam2.live.flv','测试视频-BigBuckBunny',2,1),
('main','stream','cam3','cam3','/live/cam3.live.flv','测试视频-Jellyfish',3,1),
('main','stream','cam4','cam4','/live/cam4.live.flv','测试视频-Jellyfish镜像',4,1);" 2>/dev/null

echo "=== 落库结果 ==="
mysql -uroot -p'easySVA.EZ' easySVA -e "select id,slot_index,source_type,device_id,play_url,title,enabled from h_screen_wall_stream;" 2>/dev/null
