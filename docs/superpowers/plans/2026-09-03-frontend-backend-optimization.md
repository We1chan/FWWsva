# 前后端体验与结构优化实施计划

> 执行方式：使用 `make-plan` 编写计划、`do` 分阶段执行，由独立子代理承担实现、验证和审查；每阶段通过验证后提交并立即正常推送。用户已授权编写后直接执行。

**Goal:** 让 easySVA 管理界面更加统一、清楚、适应不同屏幕，并使设备监控操作的后端职责更清晰。

**Architecture:** 保留 Vue 2 / Element UI 与现有 Spring Boot 接口。在管理布局内建立统一视觉规范，整理首页信息层级与异步状态；将设备启动/停止监控的业务编排移出 Controller，以类型化结果保持原 JSON 契约。

**Tech Stack:** Vue 2.6、Element UI 2.15、ECharts 5、Vuex、Jest、ESLint；Java 17、Spring Boot 4、JUnit 5、Maven。

## 0. 现状与设计依据

- [x] 检查仓库、远程、现有改动和运行工具。
- [x] 同步三个目标仓库的 `origin`，确认 `master` 无远程落后。
- [x] 阅读既有实现及验收文档，明确允许使用的接口与组件。

| 仓库 | 开始提交 | 本轮责任 |
| --- | --- | --- |
| `FWWsva` | `dd37f45` | 计划、实施记录、验证证据 |
| `SVA-web` | `ebfcddb` | 管理布局、首页与必要回归测试 |
| `SVA-backend` | `bd242f2` | 设备监控业务编排、契约回归测试 |

前端已有未提交的 `src/views/dping/components/realtime-warning.vue` 修改（轮播行数、间隔、模式），本轮保留原状，不将其混入本次提交。

### 现有实现与可复用模式

| 来源（行号为初始版本） | 已确认用法 / 问题 |
| --- | --- |
| `SVA-web/src/layout/index.vue:1` | 管理页都包裹在 `.app-wrapper`；使用 Vuex `sidebar`、`device`、`theme` 控制布局。新增主题应限制在管理布局内。 |
| `SVA-web/src/assets/styles/variables.scss:12` | 侧栏色与宽度由 SCSS 变量集中控制，并导出给 Vue 组件。 |
| `SVA-web/src/assets/styles/element-variables.scss:7`、`src/store/modules/settings.js:8` | Element 主色与 Vuex 默认色需一致；尊重已有用户保存的设置。 |
| `SVA-web/src/views/home/index.vue:1` | 70/30 固定比例、缺少页标题、挂载时修改父节点背景；公示表通过额外 `wids` 数组定位告警。 |
| `SVA-web/src/views/home/components/hazard-count.vue:1` | 四类指标已有 API 和跳转语义，优先使用现有数据，不填充演示数字。 |
| `SVA-web/src/views/home/components/hazard-trend.vue:228`、`hazard-distribution.vue:135` | 已使用 ECharts；匿名 resize 监听和组件释放需核查，补齐销毁与容器尺寸变化处理。 |
| `SVA-web/src/api/system/kanban.js:1` | `getMonthWaring/getMonthMajorWaring/getMonthOverdueWaring/getMonthHandle/getTrend/getGrowth/getColumn/getTypeSpread/getHandleData/getDeptList` 为本轮可用接口。 |
| `SVA-web/tests/unit/device-manage.spec.js`、`warning-index.spec.js` | 现有 Vue Test Utils 与 API mock 风格；保留设备、告警及播放器回归。 |
| `SVA-backend/ruoyi-admin/src/main/java/com/ruoyi/waring/controller/HDeviceController.java:141` | 启停接口重复查询、调用、异常映射、结果组装；HTTP 外层成功、内层业务成功的契约必须保留。 |
| 同文件 `:216` | 返回结构为 `AjaxResult.success({ success, shortMessage, data })`；设备不存在、0 行结果和流媒体错误均已有行为。 |
| `SVA-backend/ruoyi-admin/src/test/java/com/ruoyi/waring/controller/HDeviceControllerTest.java:1` | JUnit 5、直接调用 Controller、动态代理隔离设备服务，测试无需启动数据库。 |
| `FWWsva/docs/验收点1-部署与架构说明.md:5` | 现有本地站点 `http://localhost/`、后端 `9114`；开发预览单独端口，不覆盖运行部署。 |

### 方案选择

1. **采用：局部视觉体系 + 首页梳理 + 设备监控服务提取。** 有直接可见收益，变更边界可测试，可分仓独立发布。
2. 仅调整 CSS：投入较少，但无法处理首页异步状态、图表释放和后端职责问题。
3. 全量迁移 Vue 3 / 重写业务层：范围和兼容风险较大，不作为此次优化内容。

### 视觉规范与交互

- 深墨绿色侧栏、灰白工作区、白色内容面板，青绿色用于主操作和选中状态；告警继续使用红/橙语义色。
- 统一标题、说明、边框、圆角、阴影和间距；数据使用清晰数字层级，减少装饰性图片。
- 首页顺序：页标题与组织筛选 → 四项月度指标 → 趋势与分布 → 报警挂牌公示。公示采用适合侧栏/窄屏的布局，保留跳转告警详情。
- 桌面采用明确的内容网格；平板缩为两列，手机单列；图表随实际容器尺寸变化调整。
- 数据加载、空数据、请求失败须可区分；刷新失败不伪装成“0 条告警”。键盘焦点可见，按钮名称明确。

## 1. 计划落库与远程同步

- [ ] 自审本计划的接口、范围与验收条件。
- [ ] 在 `FWWsva` 仅暂存本文件，提交 `docs: plan frontend and backend optimization`。
- [ ] 执行 `git push origin master`，核对远程分支与本地提交一致。

## 2. 管理布局与视觉规范

**文件范围：** `SVA-web/src/layout/**`、`src/assets/styles/{index,variables,element-variables,admin-workspace}.scss`、`src/store/modules/settings.js`。可按需创建 `admin-workspace.scss`。

- [ ] 复用 `layout/index.vue` 的管理布局根节点，增加 `.sva-workspace` 作用域和统一 CSS 变量。
- [ ] 统一侧栏、品牌区、顶部栏、标签页的层次与留白，保持现有折叠和移动端抽屉行为。
- [ ] 管理列表表头、筛选表单、操作按钮与分页使用一致视觉；不引入新的 UI 依赖。
- [ ] 保留 `--current-color` 与用户主题设置；默认主题色与 Element SCSS 一致。
- [ ] 检查 1440/1024/390 宽度下的导航与列表；保持 focus-visible 和 reduced-motion 支持。

参考样式边界：

```scss
.sva-workspace {
  --sva-surface: #fff;
  --sva-canvas: #f3f6f6;
  --sva-ink: #18332f;
  --sva-muted: #647874;
  --sva-border: #dfe8e5;
  --sva-accent: var(--current-color, #16806a);
}
```

**验证：** 对改动的 JS/Vue 执行 ESLint；结合阶段 3 运行完整前端验证。独立审查样式是否越界到登录或大屏。验证后提交 `feat(web): unify the management workspace visual system` 并立即推送。

## 3. 首页重整与状态可靠性

**文件范围：** `SVA-web/src/views/home/**`；按需新增 `src/components/Charts/` 内生命周期辅助模块、`src/utils/dashboard.js`、`tests/unit/home-dashboard.spec.js` 和图表相关测试。

- [ ] 将页标题、简短说明和组织筛选放在同一操作区；仅对有 `getDeptList` 或 `*:*:*` 权限的用户请求组织列表。
- [ ] 保留四类月度指标的准确字段和已有跳转，使用响应式卡片；API 失败显示不可用状态并允许重试。
- [ ] 公示行直接携带 `w_id`，跳转使用该行的 ID；移除会累积/错位的独立 `wids` 数组与父 DOM 样式修改。
- [ ] 组织请求与公示请求相互独立；组织加载失败不阻塞公示；快速切换组织时旧响应不得覆盖最新响应。
- [ ] 统一趋势/分布图表的标题与颜色，检查 ECharts 实例复用、resize 监听清理、destroy/dispose；图表区域支持窄屏。
- [ ] 新增有意义的回归：按行 ID 跳转；列表为空/失败；无组织权限；重复请求或乱序响应；图表销毁后监听释放（按实际实现覆盖）。纯样式调整以浏览器检查验证。

公示行映射与跳转保持既有接口：

```js
const rows = (response.data || []).map(item => ({
  id: item.w_id,
  handleEvent: item.alarm_type_name,
  handleLoc: item.device_name,
  handleOrg: item.h_org_name
}))
this.$router.push({ path: '/warning/warning', query: { withQue: 7, wid: row.id } })
```

**验证命令（`SVA-web`）：**

```powershell
npm run lint
npm run test:unit -- --runInBand
npm run build:prod
```

预期全部退出 0。通过浏览器检查桌面与手机首页、公示跳转、组织筛选和侧栏折叠，保存截图。验证后提交 `feat(web): redesign the operations dashboard` 并立即推送。

## 4. 后端设备监控职责拆分

**文件范围：**

- 修改 `SVA-backend/ruoyi-admin/src/main/java/com/ruoyi/waring/controller/HDeviceController.java`。
- 创建 `.../waring/service/DeviceMonitorService.java`：统一启停编排与失败后的状态恢复读取，构造注入 `HDeviceService`。
- 创建 `.../waring/domain/DeviceMonitorResult.java`：只表示 `success`、`shortMessage`、`data`，由 Controller 包装 HTTP 响应。
- 创建 `.../src/test/java/com/ruoyi/waring/service/DeviceMonitorServiceTest.java`，扩展 `.../controller/HDeviceControllerTest.java`。

- [ ] 先建立现有启停行为的契约测试：成功、设备不存在、0 行、抛出业务异常、超时、拉流失败、推流失败、重复启动。
- [ ] 将两条路径共享的“查设备 → 执行动作 → 读取状态 → 返回业务结果”集中到服务，Controller 只保留权限、路由和响应包装。
- [ ] 异常消息匹配使用 `Locale.ROOT`；保持已知错误的中文提示以及未知业务异常原有信息。
- [ ] 失败后的状态重读若再次失败，应保留已知设备快照和最初失败结果，记录日志，不让二次异常覆盖业务原因；添加针对性测试。
- [ ] 对旧 JSON 契约断言 `code=200`、`data.success`、`data.shortMessage`、`data.data`（设备），权限表达式、路由和现有设备服务入口保持不变。
- [ ] 运行聚合 Maven 测试及独立代码审查，确认 GB28181 同步/预览与既有部署测试仍通过。

允许的 Controller 结构：

```java
@PreAuthorize("@ss.hasPermi('waring:device:start')")
@PostMapping("/monitor/{apeId}/start")
public AjaxResult startMonitor(@PathVariable String apeId) {
    return AjaxResult.success(deviceMonitorService.start(apeId));
}
```

**验证命令（`SVA-backend`，本地 Java 17/Maven 或 WSL 中的当前工作树）：**

```text
mvn -pl ruoyi-admin -am test -DskipITs -q
```

不以旧部署树的测试结果替代当前源码验证，不修改运行中的数据库、视频源或布控。验证后提交 `refactor(backend): extract device monitor orchestration` 并立即推送。

## 5. 最终验收与实施记录

- [ ] 独立审查本轮 diff，处理可复现的行为回归与样式问题。
- [ ] 确认前端完整 lint、unit、production build 与后端测试通过；如环境阻塞，记录精确阻塞与已经完成的验证。
- [ ] 实际浏览器检查首页桌面/手机截图，以及设备和告警管理页面；不通过修改生产数据来制造展示效果。
- [ ] 在本文附录记录实际变更、验证结果、截图、各仓库提交号与远程同步结果。
- [ ] 提交实施记录并推送 `FWWsva`。核对三个仓库 `HEAD` 与远程 `refs/heads/master` 一致；前端仅保留原有大屏未提交修改。

## 边界与回退

不升级依赖、不迁移数据库、不改 Analyzer/流媒体仓库、不替换接口路径和权限、不引入示例数据、不修改既有用户工作。每个逻辑阶段独立提交，回退时可对相关提交使用 `git revert`，保持远程历史完整，不强推。

## 实施记录

执行中。验证与远程提交结果将在各阶段完成后补充。
