# 阶段 5：整体联调 E2E 取证

**执行时间：** 2026-09-02 18:55–19:18 +08:00
**目标环境：** WSL `Ubuntu-22.04-easySVA`（7 个 systemd 服务 active）+ Windows 11 工作区（浏览器取证 + git）

## 范围

阶段 4 闭环之后按 5 条 E2E 场景验证：

1. **RTSP + 睡岗**（ws 链路告警）
2. **GB28181 + 睡岗**（ws 链路告警，设备类型 JOIN）
3. **GB28181 离线/重连**（同步 + 预览 + 定时器自愈）
4. **两种设备布控启停**（RTSP + GB28181 各 1 个 sleep_duty 布控，start/stop 终态）
5. **原 YOLO 回归**（dwell 告警仍能在 UI 列表/详情查看）

## 产物清单

| 类型 | 文件 | 说明 |
| --- | --- | --- |
| API 落库 | `05-01-put-gb-task-20260902-190940.json` | GB28181 布控创建请求响应（`taskName=P5-GB28181-睡岗布控`） |
| API 落库 | `05-01-deployments-list-20260902-190940.json` | 布控创建后列表查询（含 3 条 RUNNING） |
| API 落库 | `05-01-tasks-db.txt` | `deployment_task` 三条关键字段（task_id/controlId/device_id/algorithm/status） |
| API 落库 | `05-02-stop-controlBVwDyFaFSi7WyW-20260902-191123.json` | GB28181 任务 stop 响应（成功 STOPPED） |
| API 落库 | `05-02-stop-controlDrwhlzWGKy6DaS-20260902-191123.json` | RTSP 任务 stop 响应（集成缺口见下，已绕行重 start） |
| 请求体 | `req-rtsp-sleep.json` | RTSP 布控创建请求体（`deviceId=dev_mock_camera_001`） |
| 请求体 | `req-gb-sleep.json` | GB28181 布控创建请求体（`deviceId=gb-34020000001320000001-34020000001310000001`） |
| 请求体 | `smoke-create-req.json` | 早期冒烟用（已替代） |
| 事件脚本 | `events-s1s2s5.json` | 9 条 `detect.event`（RTSP sleep_duty 30/45/60s + GB sleep_duty 25/40/55s + YOLO dwell 15/30/45s） |
| 事件脚本 | `phase5_ws_push.py` | WSL 内 `python3 phase5_ws_push.py events-s1s2s5.json`（自动连 `ws://127.0.0.1:9114/websocket/sva/noop`、填 `startTimestampMs`/`timestampMs`） |
| 浏览器取证 | `run-phase5-ui.js` | playwright-core headless + Chromium 152 自动化脚本（NODE_PATH 指向 `.p3tools/node_modules`） |
| 浏览器取证 | `p5-01-alarm-list-all-20260902-191730.png` | 报警列表全量 5 行（含设备类型 tag 与最新 ws 事件置顶） |
| 浏览器取证 | `p5-02-sleep-filter-20260902-191730.png` | 睡岗快捷筛选 4 行（GB28181 + RTSP + 2 条历史） |
| 浏览器取证 | `p5-03-sleep-detail-1st-20260902-191730.png` | 第 1 条睡岗详情（GB28181 设备、`<img>` 加载成功、规则 `rule-sleep-gb-a`、55s） |
| 浏览器取证 | `p5-04-sleep-detail-2nd-20260902-191730.png` | 第 2 条睡岗详情（RTSP 设备、`<img>` 加载成功、规则 `rule-sleep-rtsp-a`、1 分） |
| 浏览器取证 | `p5-05-alarm-list-dwell-regression-20260902-191730.png` | 清除快捷筛选后全量（YOLO 停留告警在第 1 行） |
| 浏览器取证 | `p5-06-dwell-detail-20260902-191730.png` | 停留告警详情（YOLO 回归，行为类型 `dwell`、45s） |
| 浏览器取证 | `p5-07-deploy-list-20260902-191730.png` | 布控列表 3 条 RUNNING（GB28181/RTSP 睡岗 + YOLO 历史任务） |
| 浏览器取证 | `p5-08-lixian-gb-offline-20260902-191730.png` | 离线设备页 1 条（副井口-国标02 幽灵流离线） |
| 浏览器取证 | `p5-summary-20260902-191730.json` | 截图清单（name/file/note/url）+ 完整菜单 dump |

## 复现命令

```bash
# 1) 复制 ws 推送脚本与事件到 WSL
cp FWWsva/docs/evidence-phase5/phase5_ws_push.py  /opt/SVA/tmp/
cp FWWsva/docs/evidence-phase5/events-s1s2s5.json  /opt/SVA/tmp/

# 2) WSL 内推送 9 条 detect.event（自动落库 h_waring，3 条 canonical）
wsl -d Ubuntu-22.04-easySVA
sudo apt install -y python3-websocket
python3 /opt/SVA/tmp/phase5_ws_push.py /opt/SVA/tmp/events-s1s2s5.json

# 3) 创建两个 P5 睡岗布控
curl -X POST 'http://127.0.0.1:9114/deployment/create' \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  --data-binary @FWWsva/docs/evidence-phase5/req-rtsp-sleep.json --noproxy '*'
curl -X POST 'http://127.0.0.1:9114/deployment/create' \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  --data-binary @FWWsva/docs/evidence-phase5/req-gb-sleep.json  --noproxy '*'

# 4) 启动
curl -X POST 'http://127.0.0.1:9114/deployment/start' \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"controlId":"controlDrwhlzWGKy6DaS"}' --noproxy '*'
curl -X POST 'http://127.0.0.1:9114/deployment/start' \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"controlId":"controlBVwDyFaFSi7WyW"}' --noproxy '*'

# 5) DB 验证
mysql -uroot -peasySVA.EZ easySVA -e "SELECT w_id, w_name, behavior_type, device_name, hd.device_type, duration_ms, picture_absolute_url FROM h_waring hw LEFT JOIN h_device hd ON hd.ape_id = hw.device_id WHERE w_id IN (SELECT w_id FROM h_waring WHERE w_name LIKE 'ev-p5-%') ORDER BY w_id DESC;"

# 6) UI 取证
cd C:/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase5
NODE_PATH=C:/Users/19904/Documents/ChatGPT/sva/.p3tools/node_modules \
  C:/Users/19904/.workbuddy/binaries/node/versions/22.22.2-2/node.exe run-phase5-ui.js
```

## 已知遗留与故障处理

### 1. analyzer 控制态不持久化（集成缺口）

`easysva-analyzer` 在后端 jar 重建（19:09 附近）期间重启，**内存控制表清空**；DB `deployment_task.status` 仍记 `RUNNING` 但 analyzer 报 `there is no such control` 导致 stop 失败。

- **触发条件**：后端 `easysva-backend` 重启（jar 重部署），analyzer 不联动重启。
- **临时处置**：再调一次 start 重建控制，DB RUNNING 恢复。
- **建议改造**：
  1. analyzer 控制表持久化（DB/Redis），重启后从持久层重建。
  2. 后端 `DeploymentAnalyzerClient.addControl` 启动前若 DB RUNNING + analyzer 报无此 control，自动重建（`upsert` 而非纯 `add`）。
  3. 在 `easysva-backend.service` 单元 `After=` / `Wants=` 加入 `easysva-analyzer.service`，并在 `ExecStartPost=` 触发 analyzer 重启 + DB 控制表重建。

### 2. GB28181 布控 `pull stream connect error`（已修复）

`DeploymentAnalyzerClient.buildStreamUrl` 原实现对所有设备都用 `ape_id` 当 ZLM 流名（如 `rtsp://127.0.0.1:9994/live/gb-34020000001320000001-34020000001310000001`），GB28181 设备 `ape_id` 在 ZLM 中**并非有效流名**——真实流由 GB 信令通道产生，流名是 `gb28181_channel.play_url` 解析后的 `dev_mock_camera_001`。

- **修复**（已合入 `SVA-backend` `fix: resolve GB28181 device media stream for deployment start`）：按 `device_type` 分流，GB28181 设备走 `play_url` 解析路径；RTSP 设备维持原 `ape_id` 协议。
- **影响范围**：所有 GB28181 设备的布控启动，阶段 5 E2E 才发现并修复。

### 3. 浏览器侧预览画面 WSL2 → Windows 端口转发限制

GB28181/RTSP 预览 `video` 元素已渲染、加载圈与控制条可见，正在拉流（p3-18 证明），但画面未解码属 WSL2→Windows 端口转发限制。`wsl --update` 启用镜像网络后补图。

### 4. `npm run lint` 与告警截图 404

仍为既有基线门禁（阶段 1–4 记录一致），与本次改动无关。
