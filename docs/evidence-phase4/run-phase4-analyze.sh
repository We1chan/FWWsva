#!/usr/bin/env bash
# easySVA 阶段4 API 取证（分析入口）：复用已生成 JSON 断言行输出
# 用法：bash run-phase4-analyze.sh <TS>   —— TS 来自 run-phase4-api.sh 打印的 TS=...
set -u
TS=${1:?need TS from run-phase4-api.sh output}
OUT=/c/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase4
PY="C:/Users/19904/.workbuddy/binaries/python/versions/3.13.12/python.exe"
AN_WIN=$(cygpath -w "$OUT/phase4_analyze.py")
WIN_OUT=$(cygpath -w "$OUT")
echo "=== analyze TS=$TS ==="
"$PY" "$AN_WIN" listall "$WIN_OUT/04-01-list-all-$TS.json"
"$PY" "$AN_WIN" filtersleep "$WIN_OUT/04-02-filter-sleep-$TS.json"
"$PY" "$AN_WIN" typelist "$WIN_OUT/04-03-type-list-$TS.json"
if [ -f "$OUT/04-04-detail-$TS.json" ]; then
  "$PY" "$AN_WIN" detail "$WIN_OUT/04-04-detail-$TS.json"
fi
