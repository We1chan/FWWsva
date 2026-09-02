#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
easySVA phase5 ws detect.event pusher (run inside WSL, same host as backend)
Simulates the AI/media side pushing SVA rule detect events over
ws://127.0.0.1:9114/websocket/sva/noop  (see SvaNoopWebSocketEndpoint).

Usage:
  python3 phase5_ws_push.py <events.json> [ws_url]

events.json: list of dicts with fields:
  eventId, behaviorType, eventState(start|update|end), controlCode,
  eventKey(optional), image_path(optional), ruleId/regionId/regionName(optional),
  durationMs(optional), gap_ms(optional, time to sleep after this event)
Script fills startTimestampMs/timestampMs automatically from now.
"""
import json
import sys
import time

import websocket

WS_DEFAULT = "ws://127.0.0.1:9114/websocket/sva/noop"


def main():
    if len(sys.argv) < 2:
        print("usage: python3 phase5_ws_push.py <events.json> [ws_url]", file=sys.stderr)
        return 2
    events = json.load(open(sys.argv[1], encoding="utf-8"))
    ws_url = sys.argv[2] if len(sys.argv) > 2 else WS_DEFAULT

    ws = websocket.create_connection(ws_url, timeout=10)
    print("[ws] connected:", ws_url)
    now_ms = int(time.time() * 1000)
    sent = 0
    for ev in events:
        event_id = ev.get("eventId")
        state = ev.get("eventState")
        behavior = ev.get("behaviorType")
        control = ev.get("controlCode")
        duration_ms = int(ev.get("durationMs") or 0)
        start_ms = now_ms - duration_ms
        payload = {
            "type": "detect.event",
            "eventId": event_id,
            "behaviorType": behavior,
            "eventState": state,
            "controlCode": control,
            "startTimestampMs": start_ms,
            "timestampMs": now_ms,
            "durationMs": duration_ms,
        }
        for key in ("eventKey", "image_path", "imagePath", "videoPath",
                    "ruleId", "regionId", "regionName", "lineId", "lineName",
                    "businessEventId", "customEventName", "trackId"):
            if ev.get(key) is not None:
                payload[key] = ev[key]
        ws.send(json.dumps(payload, ensure_ascii=True))
        sent += 1
        print("[ws] sent #%d eventId=%s state=%s behavior=%s control=%s dur=%dms"
              % (sent, event_id, state, behavior, control, duration_ms))
        gap = float(ev.get("gap_ms", 400) or 400) / 1000.0
        if gap > 0:
            time.sleep(gap)
    ws.close()
    print("[ws] done. total_sent=%d" % sent)
    return 0


if __name__ == "__main__":
    sys.exit(main())
