# 流媒体协议组 GB28181 代码地图

本文面向维护者，说明 GB28181 接入在各仓库中的职责、数据流和验证入口。
模块在原有 DIRECT/RTSP 链路旁路运行，不改变原流媒体服务的接口与端口。
不同 CPU/GPU、WSL2 或原生 Ubuntu 电脑的部署前置条件和排障步骤见
[跨电脑部署与验收指南](gb28181-cross-machine-guide.md)。

## 数据流

```text
国标摄像机 / sbgb28181
        │ SIP 注册、目录、INVITE、PS-RTP
        ▼
WVP ───────────────► GB28181 专用 ZLMediaKit
 │ 设备与通道 API                │ 播放地址
 ▼                               ▼
SVA-backend ───────────────► SVA-web 预览
 │ 在线且已点播时的 RTSP 地址
 ▼
SVA-server 分析器
```

## 六个任务模块与代码入口

| 模块 | 仓库与入口 | 职责与关键约束 |
| --- | --- | --- |
| 1. 本地部署与启停 | `FWWsva/install_source.sh`、`FWWsva/deploy/`、`SVA-backend/deploy/gb28181/` | 安装 WVP 和独立 ZLMediaKit，使用独立端口与服务，保留原 RTSP 链路 |
| 2. 设备字段与数据模型 | `HDevice.java`、`HDeviceMapper.java/.xml`、`deploy/gb28181/sql/` | 在共享设备表中增加可空国标字段，幂等迁移不修改已有 DIRECT/PLATFORM 数据 |
| 3. 设备同步与在线状态 | `Gb28181SyncServiceImpl.java`、`Gb28181SyncTaskScheduler.java` | 定时读取 WVP 完整快照；缺失通道置离线，并清除离线通道的陈旧点播地址 |
| 4. 取流与预览适配 | `Gb28181PlaybackServiceImpl.java`、`HDeviceServiceImpl.java`、`SVA-web/src/views/device/index.vue` | 仅对在线国标通道发起点播；停止或异常时回收会话；DIRECT 流继续走原代理逻辑 |
| 5. 取景与云台控制 | `Gb28181PtzServiceImpl.java`、`HDeviceController.java`、`SVA-web/src/views/device/manage.vue`、`SVA-web/src/components/RTSPPlayer/index.vue` | 默认以 1.10× 数字取景在浏览器内实时缩放/八向平移，分析器仍读取完整原始流；切到“设备云台”后才把语义指令换算成 WVP PTZ 参数，并由服务端在 1.5 秒后兜底 STOP |
| 6. 回归与验收 | `SVA-backend/deploy/gb28181/scripts/regression.sh`、`acceptance-software-simulator.md`、`FWWsva/deploy/tests/gb28181-installation-test.sh`、`gb28181-offline-recovery-smoke.sh` | 覆盖配置、迁移、单测、服务健康、PTZ、软件相机点播、离线同步/恢复和原 RTSP 回归 |

Java 文件均位于 `SVA-backend/ruoyi-admin/src/main/` 的对应 `com/ruoyi/waring`
包中；分析器输入适配位于 `com/ruoyi/web/service/deployment/DeploymentAnalyzerClient.java`。

## 维护约束

- `stream_source_type` 只使用 `DIRECT`、`PLATFORM`、`GB28181`；协议分支不得改变其他类型行为。
- GB28181 设备以 `gb_device_id + gb_channel_id` 生成稳定 `ape_id`，重复同步不得产生重复记录。
- `is_online=1` 只表示 WVP 目录在线；`monitor_status=RUNNING` 表示点播已启动，两者不能混用。
- `play_url` 面向浏览器，`gb_stream_url` 面向分析器；设备离线或停止点播后必须清理会话地址。
- WVP 点播超时、后端读取超时和浏览器超时依次为 18 秒、20 秒和 23 秒，调整时保持该顺序。
- 预览窗口默认是纯前端“数字取景”：CSS 只变换浏览器中的 video 元素，不修改媒体流、布控输入或后端分析画面。倍率范围 1.00×–2.50×，方向键在放大画面内移动裁剪区域，“恢复默认取景”回到居中的 1.10×。
- 切到“设备云台”后，PTZ HTTP 成功只表示 SIP 指令已下发，不表示云台机械动作已完成；前端按住时每 700ms 续期，后端每条移动指令 1.5s 后自动补发 STOP，避免浏览器断网后云台持续转动。
- 软件相机默认心跳仍为 60 秒/3 次；测试用 systemd 单元使用 10 秒/3 次，并响应 `ConfigDownload`，因此掉线通常约 30 秒即可在 WVP 判定。
- CPU/GPU 选择属于分析器部署策略，不影响 SIP、WVP、ZLMediaKit、设备同步或浏览器预览逻辑。
- `wvp-GB28181-pro` 是固定版本的外部依赖；`SVA-mediaServer` 复用已有 ZLMediaKit 可执行文件，协议组配置保存在业务仓库，不在第三方核心中维护私有补丁。

## 最小验证

```bash
# 安装器和 systemd 集成
bash deploy/tests/gb28181-installation-test.sh

# 后端、数据库、服务及原 RTSP 回归（在 SVA-backend 中执行）
bash deploy/gb28181/scripts/regression.sh

# 已部署环境健康检查
sudo easysva-gb-health

# 软件相机掉线、状态传播、重新注册及运行中监控恢复
sudo EASYSVA_ADMIN_USERNAME=admin EASYSVA_ADMIN_PASSWORD='<password>' \
  bash deploy/tests/gb28181-offline-recovery-smoke.sh
```

没有实体摄像机时，按 `SVA-backend/deploy/gb28181/acceptance-software-simulator.md`
启动 `sbgb28181`。页面验收顺序为“启动监控 → 预览彩条测试画面 → 停止监控 →
再次预览提示先启动监控”，随后可在预览窗口保持默认“预览取景”，按住方向/变倍按钮验证画面实时裁剪；需要验证真实设备时再切换“设备云台”，最后运行
掉线恢复冒烟脚本确认 WVP 与业务设备状态均能离线、重新上线；若测试前监控为
`RUNNING`，脚本还会等待恢复服务重新 INVITE 并回到 `RUNNING`。
