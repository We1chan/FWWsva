# 园区安防演示数据 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不影响既有验收链路的前提下，补全 easySVA 的园区设备、布控、报警与可预览模拟视频数据。

**Architecture:** 通过当前已登录的 easySVA 管理端和既有 HTTP 接口创建数据，而不是直接修改数据库。3 个在线设备复用当前 WSL 的 H.264 模拟 RTSP 源，另外 3 个设备保留为离线/维护状态；演示告警使用系统的 SVA 简化告警入口写入，以复用报警列表、统计和媒体字段处理逻辑。

**Tech Stack:** easySVA Vue 管理端、Spring Boot REST API、ZLMediaKit、WSL2 FFmpeg 模拟 RTSP 流。

---

### Task 1: 建立可回滚的演示数据基线

**Files:**

- Create: `docs/superpowers/records/2026-09-01-demo-park-baseline.md`
- Modify: `docs/superpowers/plans/2026-09-01-demo-park-data.md`
- Test: easySVA 管理端设备、布控、报警列表

- [ ] **Step 1: 记录原有验收对象与页面计数**

在浏览器分别打开“设备管理”“布控管理”“报警管理”，记录页面中现有“模拟RTSP摄像头”“验收点1-YOLO模拟检测”及三张列表的总数。基线文件写入日期、页面 URL、三个总数和原对象名称。

- [ ] **Step 2: 运行不存在演示数据的检查**

在三个列表的名称筛选框输入 `演示-` 并查询。预期三个列表均没有历史演示记录；若已有同名前缀记录，停止后续写入并在基线文件中列出它们，避免重复创建。

### Task 2: 添加 6 个园区设备并连接 3 路预览

**Files:**

- Modify: `docs/superpowers/records/2026-09-01-demo-park-baseline.md`
- Test: `GET /prod-api/waring/device/list`、设备管理页面预览

- [ ] **Step 1: 创建在线设备**

在“设备管理 → 新增”创建下列 3 条。每条使用 `stream_source_type=DIRECT`、`direct_source_url=rtsp://127.0.0.1:9994/live/mock-camera`、`ip_addr=127.0.0.1`、`port=9994`、`org_index=demo-park`、`org_name=演示园区`、`producer_name=easySVA 模拟摄像头`、`zlm_server_id=1`、`sva_server_id=1`、`is_online=1`：

| ape_id | name | place |
| --- | --- | --- |
| `demo-park-gate-01` | 演示-园区入口 | 园区主入口 |
| `demo-park-parking-01` | 演示-停车场 | 地面停车区 |
| `demo-park-lobby-01` | 演示-办公楼大厅 | A 座一层大厅 |

- [ ] **Step 2: 创建离线/维护设备**

使用相同组织和厂商信息创建下列 3 条，不填写 `direct_source_url` 且保持 `monitor_status=STOPPED`：

| ape_id | name | place | is_online | remark |
| --- | --- | --- | --- | --- |
| `demo-park-warehouse-01` | 演示-仓库通道 | 1 号仓库西侧通道 | `2` | 演示：网络维护中 |
| `demo-park-perimeter-01` | 演示-周界东侧 | 东侧围栏 | `2` | 演示：设备离线 |
| `demo-park-fire-01` | 演示-消防通道 | 地下车库消防通道 | `9` | 演示：巡检中 |

- [ ] **Step 3: 启动并验证在线设备监控**

对前三个 `ape_id` 执行 `POST /prod-api/waring/device/monitor/{apeId}/start`，再访问 `GET /prod-api/waring/device/monitor/{apeId}/preview`。预期每次启动成功，设备在网页上可播放同一条 H.264 模拟视频；若某一路代理失败，仅保留成功设备并记录失败信息，禁止重复创建代理。

- [ ] **Step 4: 验证设备列表**

在设备管理页以 `演示-` 筛选。预期共 6 条设备，入口、停车场和大厅可预览，其余 3 条显示离线或异常状态。

### Task 3: 创建不影响验收任务的演示布控

**Files:**

- Modify: `docs/superpowers/records/2026-09-01-demo-park-baseline.md`
- Test: `GET /prod-api/deployments`、布控管理页面

- [ ] **Step 1: 创建 3 个初始为 CREATED 的演示任务**

在“布控管理 → 新建”创建下列任务；均使用人员目标 `person`、算法 `yolo11n_80`、报警间隔 `180` 秒、录像引擎“算法服务器”、备注以“演示：”开头：

| taskName | deviceId | 规则说明 |
| --- | --- | --- |
| 演示-入口人员停留检测 | `demo-park-gate-01` | 全画面人员停留，阈值 5 秒 |
| 演示-停车场区域入侵 | `demo-park-parking-01` | 停车区全画面区域入侵 |
| 演示-大厅越界检测 | `demo-park-lobby-01` | 大厅入口单向越界 |

- [ ] **Step 2: 启动入口人员停留检测**

仅对“演示-入口人员停留检测”执行 `POST /prod-api/deployments/{deploymentId}/start`。另两条保持 `CREATED`，避免额外占用分析器。预期该任务为 `RUNNING`，原“验收点1-YOLO模拟检测”仍为 `RUNNING`。

### Task 4: 注入 20 条近期演示告警并关联可用媒体

**Files:**

- Modify: `docs/superpowers/records/2026-09-01-demo-park-baseline.md`
- Test: `POST /prod-api/waring/waring/addFromSvaSimple`、报警管理页面、首页统计

- [ ] **Step 1: 发送一条可验证的 SVA 简化告警**

向 `POST /prod-api/waring/waring/addFromSvaSimple` 提交：

```json
{
  "control_code": "Step 3 创建的‘演示-入口人员停留检测’返回的 deploymentId",
  "alarm_time": "2026-09-01 12:00:00",
  "alarm_type": "DEMO_DWELL",
  "alarm_type_name": "人员停留",
  "alarm_level": "2",
  "alarm_level_name": "中",
  "image_path": "",
  "video_path": "",
  "sva_event_key": "demo-park-20260901-001",
  "sva_behavior_type": "dwell",
  "sva_event_state": "CLOSED"
}
```

预期 HTTP 200 且报警管理页出现“演示-园区入口”的人员停留告警。不得使用外部图片或视频 URL。

- [ ] **Step 2: 发送余下 19 条带时间分布的告警**

以 10–15 分钟间隔将告警分布在 2026-09-01 08:10–12:40。类型配额为人员停留 6 条、区域入侵 5 条、越界 5 条、安全帽识别 4 条；等级配额为高 4 条、中 9 条、低 7 条。设备轮换使用前三个在线设备，`sva_event_key` 依次为 `demo-park-20260901-002` 至 `demo-park-20260901-020`。

- [ ] **Step 3: 形成四种处置状态**

使用报警管理的“处置”操作，将 20 条演示告警分为：8 条未处理、4 条处理中、6 条已确认、2 条误报。处置备注依次使用“演示：待值班员确认”“演示：已派保安巡查”“演示：现场已确认并闭环”“演示：复核为误报”。

- [ ] **Step 4: 验证报警页面和首页**

在报警管理页以 `演示-` 筛选并按时间倒序排列。预期 20 条记录的类型、等级、设备和处置状态符合上述配额，且告警详情不显示失效外链；返回首页，待处理报警、当日报警和趋势统计均高于基线。

### Task 5: 最终验证与清理索引

**Files:**

- Modify: `docs/superpowers/records/2026-09-01-demo-park-baseline.md`
- Test: 首页、设备管理、布控管理、报警管理和 systemd 服务状态

- [ ] **Step 1: 执行端到端回归检查**

检查首页、3 路演示设备预览、演示布控、演示报警、原模拟摄像头和原验收布控。运行：

```powershell
C:\Windows\System32\wsl.exe -d Ubuntu-22.04-easySVA -u root -- systemctl is-active mariadb redis-server nginx easysva-backend easysva-media easysva-analyzer easysva-rtsp-simulator
```

预期所有服务均输出 `active`。

- [ ] **Step 2: 写入最终记录和清理索引**

在基线文件记录 6 个 `ape_id`、3 个 `deploymentId`、20 个 `sva_event_key` 和每条新增告警的 `w_id`。清理顺序固定为：停止并删除 3 个演示布控，删除关联演示告警及处置记录，最后删除 6 个演示设备。

- [ ] **Step 3: 提交记录文档**

运行 `git add docs/superpowers/records/2026-09-01-demo-park-baseline.md docs/superpowers/plans/2026-09-01-demo-park-data.md`，再运行 `git commit -m "docs: record demo park seed data"`。预期提交只包含演示数据的计划与记录文档，不包含运行时数据库、视频或凭据。
