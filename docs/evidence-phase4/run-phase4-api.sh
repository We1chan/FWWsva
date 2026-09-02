#!/usr/bin/env bash
# easySVA 阶段4 API 取证：睡岗告警（SLEEP_DUTY）列表过滤、device_type 透传、类型下拉回源
# 在 Windows Git Bash 下执行；依赖 curl.exe（管理员登录、带 token 调 /prod-api）。
set -u
BASE=http://127.0.0.1/prod-api
OUT=/c/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase4
TS=$(date +%Y%m%d-%H%M%S)
echo "[$(date '+%F %T')] phase4 api E2E start; TS=$TS"

# ---------- 0. 登录 ----------
LOGIN=$(curl.exe -sS -X POST $BASE/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}')
TOKEN=$(printf '%s' "$LOGIN" | sed -E 's/.*"token":"([^"]+)".*/\1/')
echo "$LOGIN" > "$OUT/04-00-login-$TS.json"
echo "[login] token_len=${#TOKEN}"

# ---------- 1. 告警列表（全量）：断言 SLEEP_DUTY 行带 device_type 与截图字段 ----------
curl.exe -sS "$BASE/waring/waring/list?pageNum=1&pageSize=50" -H "Authorization: Bearer $TOKEN" > "$OUT/04-01-list-all-$TS.json"
echo "[04-01-list-all] $(head -c 200 "$OUT/04-01-list-all-$TS.json")"
"C:/Users/19904/.workbuddy/binaries/python/versions/3.13.12/python.exe" - "$OUT/04-01-list-all-$TS.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
rows=d.get('rows',[])
sd=[r for r in rows if r.get('alarm_type')=='SLEEP_DUTY' or r.get('alarm_type_name')=='睡岗告警']
print(f"[04-01] total={d.get('total')} sleep_duty_in_page={len(sd)}")
for r in sd:
    print(f"  -> {r.get('w_id')} | {r.get('device_id')} | device_type={r.get('device_type')} | type={r.get('alarm_type_name')} | behavior={r.get('sva_behavior_type')} | has_pic={bool(r.get('picture_absolute_url'))}")
PY

# ---------- 2. 睡岗过滤：alarm_type_name=睡岗告警 ----------
curl.exe -sS "$BASE/waring/waring/list?pageNum=1&pageSize=50&alarm_type_name=%E7%9D%A1%E5%B2%97%E5%91%8A%E8%AD%A6" -H "Authorization: Bearer $TOKEN" > "$OUT/04-02-filter-sleep-$TS.json"
echo "[04-02-filter-sleep] $(head -c 300 "$OUT/04-02-filter-sleep-$TS.json")"
"C:/Users/19904/.workbuddy/binaries/python/versions/3.13.12/python.exe" - "$OUT/04-02-filter-sleep-$TS.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
rows=d.get('rows',[])
print(f"[04-02] total={d.get('total')}")
for r in rows:
    print(f"  -> {r.get('device_id')} | device_type={r.get('device_type')} | {r.get('alarm_type_name')}")
PY

# ---------- 3. 告警类型下拉回源：现在应含 SLEEP_DUTY ----------
curl.exe -sS "$BASE/waring/type/list" -H "Authorization: Bearer $TOKEN" > "$OUT/04-03-type-list-$TS.json"
"C:/Users/19904/.workbuddy/binaries/python/versions/3.13.12/python.exe" - "$OUT/04-03-type-list-$TS.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
def walk(o):
    if isinstance(o,dict):
        if o.get('alarm_type')=='SLEEP_DUTY' or o.get('alarmType')=='SLEEP_DUTY' or o.get('alarm_type_name')=='睡岗告警' or '睡岗' in str(o):
            print("  hit:", {k:v for k,v in o.items() if k in ('alarm_type','alarmType','alarm_type_name','alarmTypeName','t_id','type_id','id','name')})
        for v in o.values(): walk(v)
    elif isinstance(o,list):
        for x in o: walk(x)
walk(d)
print("[04-03] type list scanned code=", d.get('code') if isinstance(d,dict) else '?')
PY

# ---------- 4. 详情：睡岗告警带 device_type 描述来源字段 ----------
FID=$("C:/Users/19904/.workbuddy/binaries/python/versions/3.13.12/python.exe" -c "import json;d=json.load(open(r'$OUT/04-02-filter-sleep-$TS.json',encoding='utf-8'));print(d['rows'][0]['w_id'] if d['rows'] else '')")
echo "[04-04] first sleep w_id=$FID"
if [ -n "$FID" ]; then
  curl.exe -sS "$BASE/waring/waring/$FID" -H "Authorization: Bearer $TOKEN" > "$OUT/04-04-detail-$TS.json"
  echo "[04-04-detail] $(head -c 400 "$OUT/04-04-detail-$TS.json")"
fi

echo "[done] TS=$TS"
