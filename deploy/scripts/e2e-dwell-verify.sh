#!/bin/bash
export WSL_UTF8=1
BASE=http://127.0.0.1:9114
MYSQL="mysql -uroot -p'easySVA.EZ' easySVA -N"

# 1. login
curl -s -m 10 -X POST $BASE/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123"}' -o /tmp/login.json
TOKEN=$(python3 -c "import json;print(json.load(open('/tmp/login.json'))['token'])")
echo "TOKEN_LEN=${#TOKEN}"

# 2. before max wid
BEFORE=$($MYSQL -e "select ifnull(max(w_id),0) from h_waring;" 2>/dev/null)
echo "BEFORE_MAX_WID=$BEFORE"

# 3. create dwell deployment
CREATE=$(curl -s -m 20 -X POST $BASE/deployments \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"taskName":"E2E-dwell-0903","deviceId":"dev_mock_camera_001","recordEngine":"A-SERVER","pushEnabled":false,"frontendOverlayEnabled":true,"dwellEnabled":true,"dwellThresholdMs":3000,"alarmIntervalSec":20,"aiReviewEnabled":false,"remark":"E2E dwell verification","algorithmTasks":[{"algorithmCode":"on_yolo11n_80","algorithmName":"person-yolo11n80","detectFps":8.0,"targetCodes":["person"]}],"geometryConfig":{"regions":[{"id":"region_full","name":"full-frame","primary":true,"enabled":true,"points":[[0,0],[1280,0],[1280,720],[0,720]]}],"lines":[],"behaviorRules":[]}}')
echo "CREATE=$CREATE"
DEPLOY_ID=$(echo "$CREATE" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('data',{}).get('deploymentId',''))" 2>/dev/null)
echo "DEPLOY_ID=$DEPLOY_ID"

# 4. start
START=$(curl -s -m 20 -X POST $BASE/deployments/$DEPLOY_ID/start -H "Authorization: Bearer $TOKEN")
echo "START=$START"

# 5. wait & poll (up to 90s)
for i in $(seq 1 18); do
  sleep 5
  CNT=$($MYSQL -e "select count(*) from h_waring where w_id > $BEFORE;" 2>/dev/null)
  echo "poll#$i new_alarms=$CNT"
  if [ "$CNT" -gt 0 ] 2>/dev/null; then break; fi
done

# 6. query new alarms
echo "=== new alarms ==="
mysql -uroot -p'easySVA.EZ' easySVA -e "select w_id, alarm_type, alarm_time, picture_url from h_waring where w_id > $BEFORE order by w_id;" 2>/dev/null

# 7. check screenshot files
echo "=== alarm dir files ==="
ls -la /var/www/SVA-web/upload/alarm/ 2>/dev/null

# 8. stop
STOP=$(curl -s -m 20 -X POST $BASE/deployments/$DEPLOY_ID/stop -H "Authorization: Bearer $TOKEN")
echo "STOP=$STOP"
