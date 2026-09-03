#!/bin/bash
export WSL_UTF8=1
BASE=http://127.0.0.1:9114
MYSQL="mysql -uroot -p'easySVA.EZ' easySVA -N"

# 1. login
curl -s -m 10 -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123"}' -o /tmp/login.json
TOKEN=$(python3 -c "import json;print(json.load(open('/tmp/login.json'))['token'])")
AUTH="Authorization: Bearer $TOKEN"

# 2. kill any prior ffmpeg pushing to office_sit
pkill -f 'rtsp://127.0.0.1:9994/live/office_sit' 2>/dev/null
sleep 2

# 3. push noon-sleep footage to office_sit
nohup ffmpeg -loglevel error -re -stream_loop -1 -i "/mnt/c/Users/19904/Documents/ChatGPT/sva/办公室各种午休睡姿大赏 - Original.mp4" \
  -c:v libx264 -preset veryfast -tune zerolatency -g 50 -an -f rtsp \
  "rtsp://127.0.0.1:9994/live/office_sit" > /tmp/noon-push.log 2>&1 &
FF_PID=$!
echo "FF_PID=$FF_PID"
sleep 5

# 4. confirm stream online + take a verification frame
ffmpeg -y -loglevel error -rtsp_transport tcp -i rtsp://127.0.0.1:9994/live/office_sit -frames:v 1 /tmp/noon-frame.jpg 2>&1
ls -la /tmp/noon-frame.jpg 2>/dev/null

# 5. before wid
BEFORE=$($MYSQL -e "select ifnull(max(w_id),0) from h_waring;" 2>/dev/null)
echo "BEFORE_MAX_WID=$BEFORE"

# 6. start deployment (DB geometry_config already has sleep rule with correct fields)
START=$(curl -s -m 20 -X POST $BASE/deployments/controlyhhccNIFcAh9pJ/start -H "$AUTH")
echo "START=$START"

# 7. wait & poll (up to 90s)
for i in $(seq 1 18); do
  sleep 5
  CNT=$($MYSQL -e "select count(*) from h_waring where w_id > $BEFORE;" 2>/dev/null)
  echo "poll#$i new_alarms=$CNT"
  if [ "$CNT" -gt 0 ] 2>/dev/null; then break; fi
done

# 8. query new alarms
echo "=== new alarms ==="
mysql -uroot -p'easySVA.EZ' easySVA -e "select w_id, alarm_type, alarm_type_name, alarm_time, picture_url from h_waring where w_id > $BEFORE order by w_id;" 2>/dev/null

# 9. analyzer log
echo "=== analyzer log ==="
journalctl -u easysva-analyzer --since '2 min ago' --no-pager 2>/dev/null | grep -iE 'sleep|controlyhh|bind-media|behaviorType' | tail -15

# 10. stop
STOP=$(curl -s -m 20 -X POST $BASE/deployments/controlyhhccNIFcAh9pJ/stop -H "$AUTH")
echo "STOP=$STOP"