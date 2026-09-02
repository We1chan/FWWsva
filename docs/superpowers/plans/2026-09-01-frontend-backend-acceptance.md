# 前后端业务组验收闭环 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不破坏现有 RTSP 功能的前提下，完成 GB28181 设备业务接入、睡岗告警闭环及验收点 1–4 中属于前后端业务组的全部交付。

**Architecture:** `h_device` 继续承载既有 RTSP 和业务关联；GB28181 的身份以 SIP/GB 平台目录为准，保存到独立 `gb28181_channel` 目录表。目录记录显式绑定 `zlm_server_id/vhost/app/stream`；ZLM `getMediaList` 只核验已绑定媒体是否可用，绝不从通用流名推断设备或通道身份。Vue 2 页面在现有设备、告警、布控模块上做增量适配；睡岗告警复用 `h_waring` 和现有截图存储。

**Tech Stack:** Spring Boot 3、MyBatis、MariaDB、Redis、ZLMediaKit REST、Vue 2、Element UI、Maven/JUnit、Vue CLI。

---

## 文件结构

| 路径 | 职责 |
| --- | --- |
| `FWWsva/deploy/sql/20260901_gb28181_business.sql` | 创建 GB28181 SIP 目录及显式媒体绑定表的可重复迁移，并初始化睡岗类型。 |
| `SVA-backend/.../domain/HDevice.java` | 增加设备类型和国标通道字段。 |
| `SVA-backend/.../domain/Gb28181Channel.java` | SIP/GB 目录的权威身份和显式媒体绑定模型。 |
| `SVA-backend/.../domain/Gb28181MediaStream.java` | 不含设备身份的 ZLM 媒体记录模型。 |
| `SVA-backend/.../mapper/Gb28181CatalogMapper.*` | 目录幂等写入及按显式绑定刷新媒体可用性的持久化。 |
| `SVA-backend/.../service/Gb28181DeviceSyncService.java` | SIP 目录写入与 ZLM 媒体刷新边界。 |
| `SVA-backend/.../controller/HDeviceController.java` | 同步、刷新、设备类型筛选接口。 |
| `SVA-backend/.../service/impl/HDeviceServiceImpl.java` | 按设备类型分流监控启动和预览。 |
| `SVA-web/src/api/device.js` | 国标同步 API。 |
| `SVA-web/src/views/device/manage.vue` | 类型筛选、字段展示、同步按钮与表单校验。 |
| `SVA-web/src/views/warning/index.vue` | 睡岗筛选、类型/设备类型展示、截图详情。 |
| `SVA-web/src/views/deployment/add.vue` | 布控配置中呈现服务端提供的睡岗选项。 |
| `FWWsva/docs/验收点2-4-前后端业务组说明.md` | 演示步骤、接口样例、截图与回归证据目录。 |

### 阶段 0：基线与验收点 1 证据

**目标：** 固化可回归基线，确认后续改动不破坏 RTSP 设备、原 YOLO 布控、告警截图和页面。

- [ ] 记录当前四仓库分支、提交号与工作区状态；创建功能分支 `codex/frontend-backend-acceptance`（各仓库独立）。
- [ ] 按 `FWWsva/docs/验收点1-部署与架构说明.md` 启动服务，执行 RTSP 预览、YOLO 布控和告警截图检查。
- [ ] 将 HTTP 响应、`h_device` / `h_waring` 查询结果、网页截图写入 `FWWsva/docs/验收点2-4-前后端业务组说明.md` 的“基线”章节。
- [ ] 运行后端既有测试：`mvn -pl ruoyi-admin -am test`；运行前端静态检查：`npm ci && npm run lint`。
- [ ] **远程提交：** 将基线文档提交并推送至 `FWWsva`：`git add docs && git commit -m "docs: record frontend backend acceptance baseline" && git push -u origin codex/frontend-backend-acceptance`。

**验收：** 浏览器可登录；RTSP 预览正常；原告警记录和截图正常；基线文档包含时间、命令和截图。

### 阶段 1：数据库与后端契约

**目标：** 建立不破坏历史 RTSP 数据的统一设备模型，以及睡岗告警稳定标识。

- [ ] **先写失败测试：** 新建 `SVA-backend/ruoyi-admin/src/test/java/com/ruoyi/waring/service/Gb28181DeviceSyncServiceTest.java`，断言 SIP 目录的 `(platformId,deviceId,channelId)` 幂等落库；ZLM 只按显式 `(vhost,app,stream)` 更新媒体可用性，缺流时保留目录身份和目录在线状态、仅标记不可预览。
- [ ] 运行 `mvn -pl ruoyi-admin -Dtest=Gb28181DeviceSyncServiceTest test`，确认因类/方法缺失而失败。
- [ ] 创建 `FWWsva/deploy/sql/20260901_gb28181_business.sql`：创建 `gb28181_channel`，以 `(platform_id,device_id,channel_id)` 保证目录身份唯一，保存 `zlm_server_id/vhost/app/stream` 显式媒体绑定、目录在线与媒体在线状态；向 `h_waring_type` 插入 `SLEEP_DUTY/睡岗告警`（不存在才插入）。
- [ ] 在 `HDevice`、`HDeviceMapper` 和 `HDeviceMapper.xml` 增加字段、`deviceType` 查询条件、`selectGbDevice`、`upsertGbDevice`、`markGbDevicesOffline`；所有列表、详情、插入、更新 SQL 均包含新字段。
- [ ] 实现 `Gb28181Channel`、`Gb28181MediaStream` 与 `Gb28181DeviceSyncService`：SIP/GB 平台目录写入身份；使用 `ZlmServer.host` / `secret` 调用本机 ZLM REST 时，只读取 `vhost/app/stream` 并匹配已有绑定。通用 ZLM 流绝不得创建、命名或下线 GB 通道。
- [ ] 重新运行测试，确认通过；运行 `mvn -pl ruoyi-admin -am test`。
- [ ] **远程提交：** 分别提交并推送 `FWWsva` 迁移脚本、`SVA-backend` 实体/Mapper/同步服务/测试：`feat: add GB28181 device business model`。

**验收：** 空库与已有 RTSP 数据库均可执行迁移；同一 SIP 目录通道重复写入无重复行；ZLM 缺流只使已绑定通道不可预览而不修改目录身份/在线状态；睡岗类型可从告警类型接口查询。

### 阶段 2：设备同步、状态和预览接口

**目标：** 让设备页能可靠获得、刷新和预览国标通道，且 RTSP 保持原行为。

- [ ] **先写失败测试：** 在 `Gb28181DeviceSyncServiceTest` 加入 ZLM 成功、连接失败、空通道、设备离线四个用例；在 `HDeviceControllerTest` 断言 `POST /gb28181/sync` 返回 `created/updated/offlineMarked`，不可达时返回错误且 HTTP 业务码非成功。
- [ ] 运行两项测试，确认分别因端点和分流逻辑缺失失败。
- [ ] 在 `HDeviceController` 增加 `POST /gb28181/sync` 和 `POST /gb28181/status/refresh`；仅管理员可调用，参数 `zlmServerId` 默认 1 并验证存在且已启用。
- [ ] 修改 `HDeviceServiceImpl.startMonitor`、`stopMonitor`、`previewMonitor`：`GB28181` 不调用 RTSP 代理接口；在线且有 `play_url` 时更新 `RUNNING`，离线或无 URL 返回具体原因；`RTSP` 分支保持字节级兼容。
- [ ] 增加 `@Scheduled` 状态刷新任务（默认 60 秒、配置可覆盖），每次只处理 `device_type=GB28181`；ZLM 异常只记录告警日志，不将 RTSP 状态改为离线。
- [ ] 运行测试和 `mvn -pl ruoyi-admin -am test`；在 WSL 对真实/模拟 ZLM 调用同步、预览、断线刷新，保存 JSON 与日志。
- [ ] **远程提交：** 提交并推送 `SVA-backend`：`feat: sync GB28181 devices and stream status`。

**验收：** 平台能看到 ZLM 已注册国标设备；国标设备返回可播放 URL；离线刷新后状态变为离线；现有 RTSP 启停和预览仍通过回归。

### 阶段 3：Vue 设备与预览适配

**目标：** 将新能力清晰暴露给验收人员，避免把 GB28181 当作 RTSP 手工配置。

- [ ] **先写失败测试/检查：** 在 `SVA-web/tests/unit/device-manage.spec.js`（配置 Vue CLI unit test 后）断言设备类型列、`GB28181` 筛选参数和“同步国标设备”调用；若仓库未启用 Jest，则先新增 `@vue/cli-plugin-unit-jest`、`vue-jest` 和测试脚本并让测试失败。
- [ ] 在 `src/api/device.js` 增加 `syncGb28181Devices(zlmServerId)`、`refreshGb28181Status(zlmServerId)`，保留原 API 名称与 URL。
- [ ] 在 `manage.vue` 加入设备类型筛选、表格列、同步按钮与加载态；同步成功后显示创建/更新/离线统计并重新查询；编辑表单按类型显示字段，GB28181 不允许提交 `direct_source_url`。
- [ ] 在 `realtime.vue` 和设备选择列表添加类型、在线状态标识，继续调用既有 `previewDeviceMonitor`，不得在浏览器拼接 ZLM 地址。
- [ ] 运行 `npm run lint`、单元测试和生产构建 `npm run build:prod`；通过浏览器完成 RTSP 与 GB28181 列表筛选、同步、预览截图。
- [ ] **远程提交：** 提交并推送 `SVA-web`：`feat: adapt device UI for GB28181 sync`。

**验收：** 设备管理页可区分 RTSP / GB28181、执行同步、显示在线状态；两种设备预览均正常；原 RTSP 新增和编辑功能不变。

### 阶段 4：睡岗告警与布控页面闭环

**目标：** 不改变 AI 推理职责的边界，但保证睡岗事件从 Analyzer 回传到前端可查询、可筛选、可查看截图。

- [ ] **先写失败测试：** 在 `HWaringServiceImplTest` 构造 `alarm_type=SLEEP_DUTY`、带 `picture_absolute_url` 的事件，断言成功持久化、列表按类型过滤后返回、详情保留设备/截图；在 Vue 告警页测试中断言“睡岗告警”快捷筛选传递 `alarm_type_name=睡岗告警`。
- [ ] 运行测试，确认失败原因是睡岗映射/前端筛选尚不存在。
- [ ] 修改 `HWaring`、`HWaringMapper.xml` 与告警服务：标准化 `SLEEP_DUTY` / `睡岗告警`，校验截图路径，保留现有 YOLO 告警字段、列表和详情 SQL；不得专门新建睡岗告警表。
- [ ] 在 `warning/index.vue` 增加睡岗快捷筛选、类型标签、设备类型列与详情字段；图片优先使用后端已规范化的绝对 URL，缺图时显示明确占位状态。
- [ ] 在 `deployment/add.vue` 使用后端算法/规则选项呈现 `SLEEP_DUTY`，保存时写入现有 `geometryConfig.behaviorRules`，不在前端计算姿态或持续时间。
- [ ] 使用 AI 组提供的回传样例和真实 RTSP 流做告警接口测试；运行后端测试、`npm run lint`、`npm run build:prod`。
- [ ] **远程提交：** 分别提交并推送 `SVA-backend` 与 `SVA-web`：`feat: complete sleep-duty alarm business flow`。

**验收：** 普通低头不产生睡岗告警（由 AI 组原型证据证明）；睡岗事件已入 `h_waring`、带截图、可在页面筛选和详情查看；既有 YOLO 告警回归正常。

### 阶段 5：整体联调、回归和交付

**目标：** 取得验收点 2–4 的可演示证据，并完成可复现交付。

- [ ] 按“RTSP + 睡岗”“GB28181 + 睡岗”“GB28181 离线/重连”“两种设备布控启停”“原 YOLO 回归”五条场景执行端到端测试；每条记录设备 ID、控制任务 ID、告警 ID、SQL、接口响应、页面截图和日志位置。
- [ ] 更新 `FWWsva/docs/验收点2-4-前后端业务组说明.md`：补充数据库迁移、ZLM 配置、同步与预览 API、故障处理、演示步骤及所有证据链接。
- [ ] 更新 `FWWsva/README.md` 和部署手册，加入迁移命令、国标设备注册前置条件、同步按钮使用方法、睡岗告警检查步骤和回滚说明（仅删除新增列/索引前先备份）。
- [ ] 重新运行 `mvn -pl ruoyi-admin -am test`、`npm run lint`、`npm run build:prod`；在 WSL 重启服务后重复关键场景，确认状态恢复与告警链路。
- [ ] **远程提交：** 分别提交并推送三个仓库的最终代码与文档：`docs: complete acceptance 2-4 delivery evidence`；创建同名标签 `acceptance-frontend-backend-v1` 并推送标签。

**验收：** 通过 PDF 中验收点 2、3、4 的全部前后端业务项，且验收点 1 基线和原功能无回归；源码、迁移脚本、设计/部署文档、截图和演示视频清单齐全。

## 阶段依赖与远程策略

阶段必须按 0 → 5 执行。每个阶段结束前必须通过本阶段测试，再分别向 `FWWsva`、`SVA-backend`、`SVA-web` 各自已配置的 `origin` 推送；若仓库没有写入权限或缺少远程地址，停止在本地提交并记录阻塞原因，不能伪造“已推送”。所有提交前先执行 `git status --short`，只暂存本阶段文件，避免提交用户已有的未跟踪截图或其他改动。

**推送前先拉取最新远程（避免冲突的强制步骤）：** 每次提交并推送前，必须先从远程拉取最新演进，本地改动基于最新远程提交演进，禁止强推覆盖：
1. `git fetch origin <branch>`——确认远程分支最新状态；若 `git status` 显示本地落后于 `origin/<branch>`，说明有他人推送，先处理。
2. 本地落后时执行 `git pull --rebase origin <branch>`，把本阶段提交变基到远程最新提交之上；若有冲突，停止推送并人工裁决（不得 `push --force`）。
3. 本地与远程无分叉（本地仅领先）时可直接推送：`git push origin <branch>`（首次推送 `-u origin <branch>` 建立上游）。
4. 若拉取失败或发现远程与本地针对同一文件有他人改动，停止并记录，不得强行合并覆盖他人提交。

## 计划自检

- 验收点 1：阶段 0 覆盖部署链路、RTSP 回归与分工证据。
- 验收点 2：阶段 1、4、5 覆盖睡岗类型、告警入库、截图、页面与原功能回归。
- 验收点 3：阶段 1、2、3、5 覆盖字段、同步、预览、状态与 RTSP 兼容。
- 验收点 4：阶段 4、5 覆盖两类设备睡岗、告警展示、断线/布控及交付物。
