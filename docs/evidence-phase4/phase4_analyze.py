#!/usr/bin/env python3
# 阶段4 API 取证分析器：读取 Windows 路径 JSON，输出断言行。
import json, sys

def load(p):
    with open(p, encoding='utf-8') as f:
        return json.load(f)

def listall(p):
    d = load(p)
    rows = d.get('rows', [])
    sd = [r for r in rows if r.get('alarm_type') == 'SLEEP_DUTY' or r.get('alarm_type_name') == '睡岗告警']
    print(f"[04-01] total={d.get('total')} sleep_duty_in_page={len(sd)}")
    for r in sd:
        print(f"  -> w_id={r.get('w_id')} device={r.get('device_id')} device_type={r.get('device_type')} type={r.get('alarm_type_name')} behavior={r.get('sva_behavior_type')} has_pic={bool(r.get('picture_absolute_url'))}")

def filtersleep(p):
    d = load(p)
    rows = d.get('rows', [])
    print(f"[04-02] total={d.get('total')}")
    for r in rows:
        print(f"  -> w_id={r.get('w_id')} device={r.get('device_id')} device_type={r.get('device_type')} type={r.get('alarm_type_name')} has_pic={bool(r.get('picture_absolute_url'))}")

def typelist(p):
    d = load(p)
    hits = []
    def walk(o):
        if isinstance(o, dict):
            txt = json.dumps(o, ensure_ascii=False)
            if 'SLEEP_DUTY' in txt or '睡岗' in txt:
                hits.append({k: o[k] for k in o if k in ('alarm_type', 'alarmType', 'alarm_type_name', 'alarmTypeName', 't_id', 'type_id', 'id', 'name', 'type_name')})
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for x in o:
                walk(x)
    walk(d)
    print(f"[04-03] code={d.get('code') if isinstance(d, dict) else '?'} sleep_hits={len(hits)}")
    for h in hits[:5]:
        print("  hit:", h)

def detail(p):
    d = load(p)
    print(f"[04-04] code={d.get('code')} keys_present device_type={'device_type' in d.get('data', {}) if isinstance(d.get('data'), dict) else '?'}")
    if isinstance(d.get('data'), dict):
        data = d['data']
        print(f"  -> w_id={data.get('w_id')} device={data.get('device_id')} device_type={data.get('device_type')} type={data.get('alarm_type_name')} pic={bool(data.get('picture_absolute_url'))}")

if __name__ == '__main__':
    cmd = sys.argv[1]
    p = sys.argv[2]
    {'listall': listall, 'filtersleep': filtersleep, 'typelist': typelist, 'detail': detail}[cmd](p)
