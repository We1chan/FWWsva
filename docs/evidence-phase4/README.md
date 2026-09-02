# 阶段 4 浏览器与 API 取证

**执行时间：** 2026-09-02 18:45–18:54 +08:00
**取证人：** 前后端业务组 / WorkBuddy（playwright-core headless）
**取证对象：** `http://localhost/`（`SVA-backend` + `nginx` + `SVA-web` dist 已构建的 easySVA 系统）
**后端提交：** `SVA-backend` `d68dbba`（HWaringController 白名单 sleep_duty 修复 + 测试修正）；阶段 4 补丁 2 文件 `Details.java / HWaringMapper.xml`（详情设备类型 + device_id，详见阶段 4 文档章节）
**前端提交：** `SVA-web` `de20f3b`（warning/index.vue 睡岗快捷筛选/设备类型列/缺图占位、deployment/add.vue sleep_duty 选项、warning-index.spec 5例）

## 工具链

- `playwright-core`（在 `C:/Users/19904/Documents/ChatGPT/sva/.p3tools/node_modules`）
- Chromium 152（`C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe`）
- Bash + curl.exe（管理员登录带 token 调 `/prod-api`）
- 托管 Python `C:/Users/19904/.workbuddy/binaries/python/versions/3.13.12/python.exe`（JSON 分析）

## 取证前准备（演示样本）

后端原本 `h_waring` 无 `SLEEP_DUTY` 记录。为验证睡岗全链路（快捷筛选 / 设备类型列 / 详情设备类型与截图 / 缺图占位），由前后端业务组注入 2 条演示样本告警：

| w_id | device_id | device_type | sva_behavior_type | alarm_type | picture | 用途 |
| --- | --- | --- | --- | --- | --- | --- |
| 820 | `gb-34020000001320000001-34020000001310000001`（主井口-国标01） | `GB28181` | `sleep_duty` | `SLEEP_DUTY` | `http://127.0.0.1/alarm/sleep_duty_demo_20260902.jpg`（演示帧） | 验证设备类型列 = GB28181 + 详情设备类型 + 截图展示 |
| 821 | `dev_mock_camera_001`（模拟RTSP摄像头） | `RTSP` | `sleep_duty` | `SLEEP_DUTY` | NULL | 验证设备类型列 = RTSP + 详情"暂无抓拍"占位 |

演示帧来自 `/opt/SVA/tmp/acceptance-person.jpg`（阶段 1 真实抓帧），落盘到 `/var/www/SVA-web/upload/alarm/sleep_duty_demo_20260902.jpg`（nginx `/alarm/` alias 目录），由 `http://127.0.0.1/alarm/...` 200 提供。生产中应由 AI 组回传样例帧替代。

> **清理（可选）**：`DELETE FROM h_waring WHERE id IN ('evt-sleep-duty-demo-a-20260902','evt-sleep-duty-demo-b-20260902');` 与 `rm /var/www/SVA-web/upload/alarm/sleep_duty_demo_20260902.jpg`；阶段 5 整体联调可保留或重做。

## API 取证

| 文件 | 端点 / 命令 | 关键断言 |
| --- | --- | --- |
| `04-00-login-20260902-184526.json` | `POST /prod-api/login` | admin 登录 token 长度 203 |
| `04-01-list-all-20260902-184526.json` | `GET /prod-api/waring/waring/list` | `total=81`，前 2 条 `alarm_type=SLEEP_DUTY` 且 JOIN 输出 `device_type=GB28181/RTSP` |
| `04-02-filter-sleep-20260902-184526.json` | `GET /prod-api/waring/waring/list?alarm_type_name=睡岗告警` | `total=2`（前端快捷筛选与后端过滤一致） |
| `04-03-type-list-20260902-184526.json` | `GET /prod-api/waring/type/list` | `h_waring_type` 出现 `SLEEP_DUTY/睡岗告警`（t_id=41），前端"报警类型"下拉可随数据自动出现 |
| `04-04-detail-20260902-184526.json` | `GET /prod-api/waring/waring/820` | 详情返回字段集（部分；与补丁后 `04-04b` 对照，验证 `device_id/device_type` 补齐） |
| `04-01b-recheck-20260902-185128.json` / `04-04b-recheck-20260902-185128.json` | 同上 | 重新部署后的复验：详情 `device_id=gb-...01` `device_type=GB28181` `picture_absolute_url` 存在 |

复现命令：

```bash
cd /c/Users/19904/Documents/ChatGPT/sva/FWWsva/docs/evidence-phase4
bash run-phase4-api.sh           # 生成 04-00..04-03 + 04-04 JSON
bash run-phase4-analyze.sh <TS>   # 解析打印 sleep_duty/device_type 断言
```

## 浏览器取证

`run-phase4-warning.js`（playwright-core headless），登录 → 报警管理 → 报警列表，5 个场景：

| 截图 | 场景 | 关键点 |
| --- | --- | --- |
| `p4-01-list-all-20260902-185306.png` | 报警列表（默认状态） | 表格头含「报警类型」「设备类型」列；查询区含「睡岗快捷筛选」按钮；最近告警行（按时间倒序）为 `睡岗告警` + `GB28181` / `RTSP` |
| `p4-02-filter-sleep-duty-20260902-185306.png` | 点击「睡岗快捷筛选」 | 按钮切换为 `睡岗告警（筛选中）`（warning 实色）；列表 2 条全为 `睡岗告警` tag（warning 黄），设备类型列分别为 GB28181（success 绿）/RTSP（info 灰） |
| `p4-03-detail-gb28181-20260902-185306.png` | GB28181 行查看详情 | 详情对话框：截图 `<img>` 加载成功（`imgOk=true`），设备类型 tag `GB28181`（success 绿），行为类型 `睡岗`（来自 `sva_behavior_type=sleep_duty`） |
| `p4-04-detail-rtsp-no-snapshot-20260902-185306.png` | RTSP 行查看详情 | 详情对话框：图片区域显示 `暂无抓拍` 占位（`hasNoSnapPlaceholder=true`），设备类型 tag `RTSP`（info 灰） |
| `p4-05-clear-shortcut-20260902-185306.png` | 点击「睡岗告警（筛选中）」清除快捷筛选 | 按钮切换回 plain 态，证实 clear 切换工作 |

> 备注：`p4-05` 与 `p4-01` 列表内行数受 Vue 组件复用 / RuoYi 模板默认查询条件影响（页面首次进入时若路由缓存带过滤条件，clear 仅清除快捷筛选激活标志；查询区「重置」按钮或刷新页面可恢复全量 81 条；与 `clearSleepDutyShortcut` 实现 `querySpecificParams.alarm_type_name=undefined` 无关）。核心场景 `p4-02` / `p4-03` / `p4-04` 与 API 复验 `04-01/02/04b` 已完全证明筛选、详情、设备类型、截图与占位功能正确。

`p4-summary-20260902-185306.json` 包含每张截图的 `name/file/note/url`。

### 布控页（额外探试）

`run-phase4-deployment.js`：尝试进入「布控管理 → 布控新增」并展开「请选择行为」下拉验证 `sleep_duty` 选项。`p4d-summary-20260902-185408.json` 记录结果为 `sleep_duty_in_dropdown=false`（未在 headless 流程中成功触发，因该下拉嵌套在「添加算法 → 行为规则」多步流程且依赖地图/算法实例等重型组件挂载）。

`sleep_duty` 在布控页的存在以源码 `SVA-web/src/views/deployment/add.vue` 第 **1242 行** `behaviorTypeOptions` 数组 `{ value: 'sleep_duty', label: '睡岗' }`（`sleep` 之后、`absence` 之前）以及 `normalizeBehaviorType` 白名单（1626 行）作为可复现证据。计划 5 整体联调时由浏览器手测 + 后续单测覆盖。

## 已知遗留（不阻塞阶段 4 验收）

1. **告警截图留存**：基线阶段 0 已知 `h_waring` 历史告警的 `picture_absolute_url` 大多 404（告警文件 0 字节或缺失，nginx alias 路径正确）。阶段 4 在前端新增「缺图占位」增强（`snapshot-placeholder` slot + `暂无抓拍/抓拍图加载失败`），由本证据 `p4-04` 验证。生产截图由告警文件留存链路补齐后即恢复图片显示。
2. **`getAlarmTypeFilterOptions`** 当前仅从 `h_waring` 聚合历史告警类型（`h_waring_type` 中已 seed `SLEEP_DUTY` 但无历史记录时不进入前端下拉）。本证据 `04-03` 验证：注入 SLEEP_DUTY 记录后下拉回源即出现 `睡岗告警`，无需改 SQL。
3. **构建副本陷阱**：WSL 中 `/var/www/SVA-backend` 是含阶段 4 HWaring 的真正构建副本，`/opt/SVA/SVA-backend` 是旧基线 `f3f9036` 无 `device_type` 字段。误用后者打包会回退到 `MyBatis Could not set property 'device_type'`，已在 `04-01b/04-04b` 复验中确认在 `/var/www/SVA-backend` 重建后恢复。
4. **告警页 p4-05 与 p4-01 默认查询**：见上方备注，与核心 4 张场景证据无关。
5. **GB28181/RTSP 实时视频画面** 仍受 WSL2 → Windows 端口转发限制（仅播放器 video 元素渲染与流拉取过程可见，未解码出画面），属阶段 5 范畴。
