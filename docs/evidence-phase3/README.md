# 阶段 3 浏览器取证脚本与复现步骤

**执行时间：** 2026-09-02 18:05–18:13 +08:00
**取证人：** 前后端业务组 / WorkBuddy（agent-browser→playwright-core 切换）
**取证对象：** `http://localhost/`（即 `SVA-backend` + `nginx` + `SVA-web` dist 11M 已构建的 easySVA 系统）

## 工具链

- `agent-browser 0.27.0`（CLI 在本环境打开页面超时/无响应，已 TaskStop + `agent-browser close` 清理，GUI/守护进程模式不适用，最终切换到 headless 方案）
- `playwright-core`（npmmirror 安装于 `.p3tools/`）
- Chromium 152（`C:/Users/19904/.agent-browser/browsers/chrome-152.0.7977.75/chrome.exe`）

## 文件清单

| 文件 | 用途 |
| --- | --- |
| `run-phase3-frontend.js` | 主取证脚本：登录后逐场景点击操作并截图（p3-10~p3-18）+ 输出 `p3-summary-<ts>.json` |
| `package.json` | 仅声明 `playwright-core` 依赖（`npm i` 即可复现） |
| `diag-*.js` | 开发期诊断脚本（登录结构/菜单/查询区/按钮可见性） |
| `p3-10 ~ p3-18-<ts>.png` | 9 张关键场景截图 |
| `p3-03-admin-index.png` | 登录后后台首页（含左侧菜单树） |
| `p3-summary-<ts>.json` | 各场景 URL 与命中元素/文本断言摘要 |

## 复现步骤

```bash
cd /c/Users/19904/Documents/ChatGPT/sva/.p3tools && npm i playwright-core
# 确保服务运行：systemctl is-active easysva-backend nginx easysva-rtsp-simulator
node run-phase3-frontend.js   # 截图落 docs/evidence-phase3/
```

## 关键发现

1. RuoYi 表格操作按钮 hover 行才显示（visibility:hidden）→ click 用 `{ force: true }`。
2. Element-UI el-dialog append-to-body → 测试断言用 `document.body.textContent`。
3. 菜单级联幂等导航：二级项 :visible 则直点，否则展开一级再点。
4. 接入类型筛选 el-select 用 `:has-text` 定位。

## 已知环境限制

- GB28181/RTSP 预览画面未解码（p3-18 播放器 video 元素已渲染并拉流）：WSL2 NAT 下 Windows 浏览器访问 `ws://127.0.0.1:9992`（ZLM）不通。前后端接线已由 p3-18（前端）+ evidence-phase2/07-preview-online（后端 playUrl）双向证明。阶段 5 可加端口转发后补图。
