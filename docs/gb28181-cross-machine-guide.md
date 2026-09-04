# 流媒体协议组跨电脑部署与验收指南

本文用于把已完成的 GB28181 流媒体协议组代码部署到另一台电脑，并按验收点 3
复验设备注册、目录同步、预览和离线状态。目标环境可以是 CPU 电脑，也可以是
NVIDIA GPU 电脑；GPU 只影响 AI 分析器，不影响本指南的国标链路。

## 1. 结论与边界

| 能力 | 是否依赖 NVIDIA GPU | 所属组件 |
| --- | --- | --- |
| SIP 注册、心跳、目录、INVITE/BYE | 否 | WVP |
| PS-RTP 接收、RTSP/HTTP/WebSocket 转换 | 否 | GB28181 专用 ZLMediaKit |
| 设备字段、目录同步、在线状态、点播接口 | 否 | SVA-backend |
| 设备管理、启动/停止视频源、网页预览 | 否 | SVA-web |
| YOLO/ONNX 视频分析 | 可选 CPU 或 NVIDIA GPU | SVA-server |

因此，无独显电脑可以完整验证流媒体协议组。协作者有 NVIDIA 显卡时可以选择 GPU
分析器，但 GPU 驱动、CUDA、cuDNN 或 TensorRT 出错不应被误判为 GB28181 协议错误。
若只展示验收点 3，分析器没有启动也不妨碍 SIP 注册、点播、预览和离线同步验收。
国标专用 `zlm-gb.ini` 明确关闭 NVIDIA 设备探测，因此即使复用 SVA-mediaServer
可执行文件，国标媒体服务也不会要求 `/dev/nvidia*`。

本次跨电脑基线使用以下可复现版本：

- SVA-mediaServer：`95eda58fcf3e8ed401d404f825cfbc434362af34`。
- SVA-server：`f49d60183014117152607be2b592a72776db6f9f`，包含 GB28181 流输入、
  `sleep_duty` 协议兼容和姿态+眼部睡岗状态机。
- SVA-backend：`f7b45abb993f99314350489eeb7f1d6e9944b33f`，包含完整 GB28181
  数据模型、同步、点播、告警映射及 Analyzer 重启后的布控自动恢复。
- SVA-web：`98607abc3f598ba5e41a8511d184e1f2899d79e4`，包含 GB28181
  设备管理、同源媒体地址转换、布控预览和大屏算法流播放修复。
- wvp-GB28181-pro：`fb45787da01cb4f33a0b1dfaa613becf67391c17`。
- 软件相机 sbgb28181：`1da9bc62134d4cb1fd4374f733583fb5997c3f0a`。

`FWWsva/install_source.sh` 默认直接拉取上述已审核的固定提交，并允许通过显式环境
变量升级。这样协作者不会因为安装时间不同而得到不同的前端、后端或分析器源码。

安装器默认直接拉取已审核的后端提交。不要把默认值改回 `v1.2.8`：协作仓库没有
发布这个标签，而且上游同名旧标签不包含本项目的 GB28181 代码。

## 2. 支持环境与不能混用的脚本

推荐环境是 Ubuntu 22.04 x86_64，既可原生安装，也可运行在 WSL2。需要能访问
GitHub，并准备老师提供的 `easySVA-lib.zip`。安装器会准备 Java 17（easySVA
后端）、Java 21（WVP）、MariaDB、Redis、Nginx、FFmpeg 和 GStreamer 等依赖。

仓库中有两类部署入口，路径不能混用：

- 其他电脑全新安装：使用 `FWWsva/install_source.sh`，服务部署在 `/opt/SVA`，
  配置位于 `/etc/easySVA`。
- 本项目开发机复验：使用 `SVA-backend/deploy/gb28181/` 及本机启动脚本。开发机
  systemd 单元和 `D:\Codex\easySVA` 路径只服务当前电脑，不应复制给协作者。

Windows 的 `启动本机easySVA.ps1`、固定 WSL 发行版名和开发端口都不是产品配置。
协作者应使用本指南的生产安装流程，或按其实际路径显式传入环境变量。

## 3. 全新电脑安装

先确认依赖包路径，然后选择 CPU 或 GPU。即使协作者有 NVIDIA 显卡，第一次联调也
建议先选 `C` 建立功能基线；国标链路通过后再重新选择 `G` 验证分析器，可快速区分
协议问题和显卡环境问题。

```bash
sudo apt update
sudo apt install -y git unzip
cd /opt
sudo git clone https://github.com/We1chan/FWWsva.git
sudo -s

# 依赖包不在默认位置时才设置。
export EASYSVA_LIB_ARCHIVE=/opt/easySVA-lib.zip

# 必须是软件相机或实体 IPC 能访问到的地址，不要填 127.0.0.1。
# 单网卡机器可不设置并让启动器自动探测。
export EASYSVA_GB28181_HOST_IP=192.168.1.100

# 正式环境请换成各自的强密码，不要在聊天或截图中公开。
export EASYSVA_GB28181_SIP_PASSWORD='replace_with_a_strong_password'
export EASYSVA_GB28181_ZLM_SECRET='replace_with_a_private_zlm_secret'
export EASYSVA_WVP_DB_PASSWORD='replace_with_a_database_password'

# 仅在需要复现“睡岗检测”时设置。该模型不随 Git 仓库分发；省略后安装器会跳过
# 四路睡岗演示配置，但普通 YOLO、GB28181 接入和视频预览仍然可用。
# export EASYSVA_SLEEP_POSE_MODEL=/opt/models/yolo11n-pose.onnx

# 默认不启用演示视频源自启动。1 只启用推流/软件相机，不会自动运行算法任务。
export EASYSVA_AUTO_START_SAMPLE_SOURCES=0

# 省略时 GPU 默认 10 FPS、CPU 默认 1 FPS，也可以按机器能力显式覆盖。
export EASYSVA_SLEEP_DETECT_FPS=1

chmod +x /opt/FWWsva/install_source.sh
/opt/FWWsva/install_source.sh
```

选择规则：

- 无 NVIDIA 显卡、驱动不满足要求或只验收流媒体：输入 `C`。
- `nvidia-smi` 正常、驱动版本不低于安装器提示且要验证 AI 分析：输入 `G`。
- WSL2 的 NVIDIA 驱动安装在 Windows 主机侧，不要在 WSL 内重复安装 Linux 驱动。
- GPU 模式也会构建 CPU 回退版本；启动器检测到 GPU 运行库不完整时会改用 CPU。
- 三路演示视频的推流器会实际探测 NVENC：NVIDIA 驱动和编码器都可用时使用
  `h264_nvenc`，否则自动使用 CPU `libx264`，无需手工修改 systemd 单元。
- `yolo11n-pose.onnx` 不在仓库中。要运行睡岗模型，先按
  `SVA-server/prototypes/sleep_pose/README.md` 导出并通过
  `EASYSVA_SLEEP_POSE_MODEL` 提供；安装器会同时部署仓库内的眼部模型。未提供时不会
  写入状态为 `RUNNING` 的睡岗任务，防止新电脑启动后反复恢复一个无法加载的模型。
- 即使模型存在，四路睡岗任务也默认不运行。CPU 机器先以 1 FPS 手工启动一路验证；
  NVIDIA GPU 机器确认驱动、显存和 Analyzer 日志后，再从页面逐路启动算法任务。
  `EASYSVA_AUTO_START_SAMPLE_SOURCES=1` 只启用输入视频源开机自启动，不改变算法任务状态。

安装完成并选择部署后，重启系统或执行：

```bash
sudo systemctl daemon-reload
sudo systemctl restart mariadb redis-server easysva-media easysva-gb-media \
  easysva-wvp easysva-backend nginx
sudo easysva-gb-health
```

健康检查中的 WVP HTTP、GB ZLM HTTP/RTSP、原 Web 和原 RTSP 端口均应为
`OK`，SIP TCP/UDP 至少有与设备配置一致的一种为 `OK`。自定义 ZLM secret 已
保存在 `/etc/easySVA/gb28181.env`，健康
检查会使用同一配置；不要把 secret 直接写进命令历史。
生产站点默认检查 `http://127.0.0.1/`；仅在本地前端使用其他端口时，可临时设置
`EASYSVA_WEB_HEALTH_URL` 指向实际地址。

## 4. 已有环境升级

不要在有数据的电脑上重跑全新安装器。先记录五个仓库的提交与本机配置，备份数据库，
再用 `git fetch` 比较变更，确认没有覆盖本机配置后 `git merge --ff-only` 更新。
有未提交改动时先保留，不能用 `reset --hard` 强行同步。随后执行增量迁移、编译和复验。

已有电脑出现 `Unknown column 'device_type' in 'field list'`，说明代码已升级但业务库
没有执行完整迁移，并不表示五个仓库的字段定义互相冲突。先备份，再执行幂等迁移：

```bash
sudo mkdir -p /var/backups/easySVA
sudo mysqldump -uroot -p easySVA \
  > /var/backups/easySVA/easySVA-before-gb28181.sql
sudo mysql -uroot -p easySVA \
  < /opt/FWWsva/deploy/sql/20260901_gb28181_business.sql
```

然后使用当前源码重新构建前后端并重启相应服务。不要只复制 jar 或只拉前端；数据库、
后端与前端必须来自兼容版本。升级后确认：

```bash
sudo mysql -uroot -p easySVA -e "
SHOW COLUMNS FROM h_device LIKE 'device_type';
SHOW COLUMNS FROM h_device LIKE 'gb_device_id';
SHOW TABLES LIKE 'gb28181_channel';"

sudo systemctl restart easysva-backend easysva-wvp
sudo easysva-gb-health
```

回滚应用版本前应恢复与该版本匹配的数据库备份。不要手工删除新增列，也不要用初始化
SQL 覆盖已经有业务数据的数据库。

### 4.1 拉了新前端却仍看到旧设备页面

路由菜单保存在数据库中，不会随 `git pull` 自动变更。先查询：

```sql
SELECT menu_id, menu_name, path, component
FROM sys_menu WHERE component IN ('device/index', 'device/manage');
```

最新设备管理页面为 `device/manage`，包括接入类型、国标同步、视频状态和
「启动视频源/停止视频源」。若当前菜单仍为 `device/index` 且明确需要切换新版，先备份，
再仅按查询得到的 `menu_id` 修改 `component='device/manage'`，保留原 `path`、父菜单和
权限字段。退出重新登录（或刷新以重新加载路由）后验证。不要批量覆盖整张 `sys_menu`。

## 5. 不同电脑必须检查的配置

### 5.1 Java 与数据库

- easySVA 后端使用 Java 17；WVP 使用 Java 21。出现 class version 错误时先检查
  `java -version` 和 systemd 的 `ExecStart`，不要修改业务代码。
- 本地开发脚本默认 WVP 数据库在 `127.0.0.1:3307`。其他端口可通过
  `SPRING_DATASOURCE_URL` 覆盖；用户名和密码使用 `WVP_DB_USERNAME`、
  `WVP_DB_PASSWORD`。
- 本地 WVP 的 Java 21 不在标准路径时设置 `EASYSVA_JAVA21_BIN`。
- 自动回归需要 MySQL 凭据时，使用权限为 `0600` 的客户端配置文件，并设置
  `EASYSVA_MYSQL_DEFAULTS_FILE`，避免密码出现在进程列表和命令历史。

示例客户端配置文件：

```ini
[client]
user=root
password=replace_with_database_password
socket=/run/mysqld/mysqld.sock
```

### 5.2 WSL、IP 与防火墙

SIP/SDP 公布的 IP 必须可由软件相机或实体 IPC 访问。多网卡、VPN、Docker 和 WSL
都可能让自动探测选错地址；此时显式设置 `EASYSVA_GB28181_HOST_IP`。WSL2 推荐
镜像网络；使用 NAT 时还需处理 Windows 到 WSL 的端口转发。

外部防火墙和 Windows 防火墙需放行：

| 协议 | 端口 | 用途 |
| --- | --- | --- |
| TCP/UDP | 5060 | SIP |
| TCP | 9996 | GB ZLM HTTP/WebSocket 预览 |
| TCP | 9997 | GB ZLM RTSP |
| UDP | 10000 | RTP 单端口 |
| TCP/UDP | 40002-45000 | RTP 多端口 |
| UDP | 50000-55000 | WVP 媒体端口范围 |

Windows 开发机可用管理员 PowerShell 运行 `open-firewall.ps1`。WSL 发行版名称不是
`Ubuntu-22.04` 时，检查脚本应显式传入名称：

```powershell
wsl -l -q
powershell -ExecutionPolicy Bypass -File `
  deploy\gb28181\scripts\device-check.ps1 -WslDistro Ubuntu
```

WSL 镜像网络下如果 SIP UDP 正常而 TCP 5060 显示 `WARN`，运行
`netsh interface ipv4 show excludedportrange protocol=tcp`。若 5060 落在 Windows
动态排除范围内，WVP 会因端口被系统保留而只启动 UDP；软件相机和多数 IPC 可直接选
UDP 完成验收。确需 TCP 时，应由管理员调整 Windows 排除范围或为整套配置统一更换
空闲 SIP 端口，不能只改防火墙。

### 5.3 媒体地址

生产单机默认地址可保留 `127.0.0.1`；分布式部署必须把数据库中的 `zlm_server`、
`sva_server` 及浏览器可见播放地址改成实际可达 IP。浏览器访问 HTTPS 页面而预览是
HTTP/WS 时会受到 mixed content 限制，应统一代理为同源 HTTPS/WSS，而不是关闭浏览器
安全策略。

生产 Nginx 和前端开发服务器都需要 `/live`、`/analyzer`、`/media`、`/gb-media`
这四类同源代理。开发环境可通过 `VUE_APP_BACKEND_URL`、`VUE_APP_MEDIA_URL`、
`VUE_APP_GB_MEDIA_URL` 覆盖服务端目标；修改后重启开发服务器。不要把浏览器上的
`localhost` 当成远端部署机 IP。同一台机器上的代理目标可以是回环地址，浏览器只访问站点域名。

如果 WVP 返回 `ws://某个局域网IP:9996/rtp/...live.flv`，且浏览器不能直连该地址，
仅配置代理还不够：需在前端构建环境中明确指定这个 GB 媒体实例的公布地址，例如：

```dotenv
# SVA-web/.env.development.local（开发）或 .env.production.local（生产构建前）
VUE_APP_GB_MEDIA_PUBLIC_ORIGIN=http://192.168.1.100:9996
```

这里填 WVP 返回地址的协议、主机和端口，不填流路径；`http` 同时匹配对应的 `ws`。
播放器只把这个明确匹配的实例转换成站点 `/gb-media/rtp/...` 的 HTTP(S)-FLV，
不会把其他远端媒体服务器的地址全部改写。开发环境重启服务，生产环境重新构建并部署前端。
对应 `/gb-media` 代理必须指向同一个 ZLM 实例；多媒体服务器部署应分别设计路由，
不能把所有实例都指向这个单实例代理。该配置不改变 SIP/SDP 中摄像机连接用的地址。

浏览器验收必须实际打开预览，确认视频有尺寸且播放时间持续增加。仅在 WSL 内用
`ffprobe` 取流成功，不能证明 Windows 或其他电脑的浏览器也能访问返回的播放地址。

Linux 启动脚本、systemd 单元和 `.patch` 文件必须保持 LF 换行；仓库已通过
`.gitattributes` 固定。Windows 下载的旧补丁若应用失败，先检查换行，再确认锁定的源码版本。

### 5.4 最新四路演示与 CPU 模型边界

最新演示布局为 GB28181-test6、RTSP-test8、RTSP-test3、GB28181-test3。
两个国标源虽从本地 RTSP 视频取素材，对平台仍走真正的 SIP → INVITE → PS-RTP 链路，
不是把 RTSP 地址标记成国标设备。test3 的原始推流可被 RTSP 与 GB 软件相机共用。

已有环境如要升级这组演示数据，备份后按顺序应用 `20260903_add_test3_sleep_source.sql`、
`20260903_tune_sleep_detection.sql`、`20260903_mixed_gb_rtsp_sources.sql`。
注意它们是演示配置迁移：会替换指定大屏槽位，把 test6 任务改绑到国标设备，并删除旧
`cam228703` 演示设备；不要对自行改名复用的演示 ID 盲目执行。CPU 机器还应将这四个
任务的 `deployment_task_algorithm.detect_fps` 设为 1，并保持任务未运行，再逐个验证。

演示设备默认归属组织 `103/研发部门`，与后端国标同步默认值一致。若使用自定义组织，
在同一个 MySQL 会话执行脚本前设置 `@easysva_sample_org_index`、
`@easysva_sample_org_name`，并把后端 `GB28181_DEFAULT_ORG_INDEX`、
`GB28181_DEFAULT_ORG_NAME` 设成同样的值。否则账号的组织过滤可能让“数据库里有设备，
页面却看不见”。不要通过关闭权限校验解决。

本机已验证姿态模型可在 CPU 上加载并运行。30 帧短测约 2.38 FPS，这是特定视频与
软件版本下的观察值，不是所有电脑的保证；也不代表四路实时运行或睡岗告警准确率已验收。
建议从一路、1 FPS 开始。没有姿态模型时可以完全跳过 AI，照常验收国标注册与预览。

单路 test3 输入启动示例（不启动算法）：

```bash
sudo systemctl start easysva-rtsp-simulator-3
# 还要验证同一素材的国标路径时再启动：
sudo systemctl start easysva-gb-simulator-test3
```

软件相机从 `/etc/easySVA/gb28181.env` 读取 IP、SIP 密码；默认按 WVP 相同方式探测本机 IP。
若 WVP 在另一台机器，分别设置 `GB28181_SERVER_IP` 和 `GB28181_LOCAL_IP`，后者必须
是软件相机所在电脑的实际 IP。`GB28181_SIP_PORT` 可覆盖 SIP 端口。

安装或替换模型时可以使用摘要校验工具，摘要应由模型提供者通过可信渠道确认：

```bash
sudo bash /opt/FWWsva/deploy/scripts/install-sleep-models.sh \
  /path/to/yolo11n-pose.onnx VERIFIED_SHA256 /opt/SVA/models \
  /opt/SVA/SVA-server/prototypes/sleep_pose/models/open-closed-eye-0001.onnx
sudo systemctl restart easysva-analyzer
```

该工具校验失败不会覆盖现有文件；成功替换前保留 `.backup-*`。重启后确认模型加载日志，
再在「布控任务」启动一路。只看到进程存活不能作为模型加载成功的证据。

## 6. 软件相机验收点 3

没有实体 IPC 时使用锁定版本的 `sbgb28181`，具体安装依赖见
`SVA-backend/deploy/gb28181/acceptance-software-simulator.md`。先确认服务健康，再在
SVA-backend 目录启动模拟器：

```bash
bash deploy/gb28181/scripts/health.sh
bash deploy/gb28181/scripts/simulator-start.sh
```

另开终端或 PowerShell 检查目录。生产环境可直接查看 WVP API；开发环境可运行
`device-check.ps1`。默认应看到设备 `44010200491320000001` 和通道
`44010200491320000002` 在线。

浏览器进入「视频智能分析 → 设备管理」，按以下顺序演示：

1. 点击「同步国标设备」，列表出现接入类型为 `GB28181`、名称为 `ch1` 的在线设备。
2. 点击「启动视频源」（旧版叫「启动监控」），页面提示成功且视频状态变为播放中。
3. 点击「预览视频」，持续显示彩条测试画面。彩条右下角的一小块雪花属于标准测试源，
   不是解码故障。
4. 关闭预览并点击「停止视频源」，页面提示成功。如果该视频源还有运行中的布控，
   应先在「布控任务」停止布控；新版会阻止中断正在被算法使用的视频源。
5. 再次点击「预览视频」，必须提示“GB28181 设备尚未启动点播，请先启动监控”。
6. 在模拟器终端按 `Ctrl+C`（systemd 相机则停止对应服务）。等待心跳超时后设备变为离线；
   当前默认 60 秒心跳、3 次缺失，约 3 分钟后判离线，再加平台同步周期。离线状态不得启动点播。
7. 重新运行模拟器，设备恢复在线且可再次预览。
8. 同时预览一台原有 RTSP 设备，证明旧链路未被国标旁路改造破坏。

媒体层可交叉验证：

```bash
ffprobe -v error -rtsp_transport tcp \
  -show_entries stream=codec_name,width,height,r_frame_rate \
  -of default=noprint_wrappers=1 \
  rtsp://127.0.0.1:9997/rtp/44010200491320000001_44010200491320000002
```

以模拟器实际输出的流 ID 为准。预期为 H.264、640x480、25 fps。完整自动回归：

```bash
cd /path/to/SVA-backend
bash deploy/gb28181/scripts/regression.sh
```

若 `FWWsva` 不在同级目录，应设置业务迁移的绝对路径：

```bash
export EASYSVA_GB28181_BUSINESS_MIGRATION=/path/to/FWWsva/deploy/sql/20260901_gb28181_business.sql
bash deploy/gb28181/scripts/regression.sh
```

## 7. 常见故障定位

| 现象 | 最可能原因 | 处理 |
| --- | --- | --- |
| `Unknown column 'device_type'` | 业务迁移未执行 | 备份后执行完整业务迁移，重启后端 |
| WVP 启动失败或 class version 错误 | Java 版本/路径错误 | WVP 用 Java 21，后端用 Java 17 |
| WVP 数据库连接失败 | 端口、库名或凭据与本机不同 | 设置 `SPRING_DATASOURCE_URL` 和 WVP 数据库环境变量 |
| SIP TCP 5060 为 `WARN`、UDP 为 `OK` | Windows 动态排除端口占用了 TCP 5060 | 相机先选 UDP；确需 TCP 时调整排除范围或统一改端口 |
| WVP 设备数始终为 0 | 公布 IP 不可达、SIP 参数或防火墙错误 | 核对 IP、5060、平台 ID/域/密码及 UDP/TCP |
| 点播成功但浏览器无画面 | 播放地址不可达、端口未放行或协议被浏览器拦截 | 检查 9996/9997、实际 IP 与 HTTP/HTTPS 同源 |
| ZLM 健康检查报 secret 错误 | 服务与检查脚本使用了不同 secret | 从同一环境文件加载 `GB28181_ZLM_SECRET` |
| `device-check.ps1` 找不到 WSL | 发行版名称不同 | 使用 `-WslDistro` 或 `EASYSVA_WSL_DISTRO` |
| GPU provider/CUDA/cuDNN/TensorRT 报错 | AI 分析器 GPU 环境不完整 | 先切 CPU 分析器；国标预览仍可独立验收 |
| 服务文件引用 `/mnt/d/Codex/...` | 误用了开发机脚本 | 其他电脑使用 FWWsva 生产安装器和 `/opt/SVA` 服务 |
| 公网 CCTV HLS 返回 403/502 | 源站或网络不稳定 | 使用本地 RTSP 或 sbgb28181，不作为代码失败依据 |

查看日志：

```bash
sudo systemctl status easysva-gb-media easysva-wvp easysva-backend --no-pager
sudo journalctl -u easysva-gb-media -u easysva-wvp -u easysva-backend \
  -n 200 --no-pager
```

只有 GPU 全系统联调时才额外检查：

```bash
nvidia-smi
sudo journalctl -u easysva-analyzer -n 200 --no-pager
```

GPU 检查失败需要由有 NVIDIA 显卡的协作者修复其驱动/运行库或先选 CPU；它不会改变
已经合并的流媒体协议代码，也不能否定验收点 3 的 SIP、设备同步和预览结果。

## 8. 最终留存证据

协作者完成后应保存以下材料，便于最后答辩：

- `easysva-gb-health` 全部通过的终端截图。
- WVP 中软件设备在线和通道目录截图。
- easySVA 设备列表中 RTSP 与 GB28181 两类设备同屏截图。
- 彩条预览、停止后拒绝预览、模拟器离线、重新上线四个状态截图或录屏。
- `ffprobe` 的编码、分辨率、帧率输出。
- `regression.sh` 完整通过输出。
- 若选择 GPU，再单独保存 `nvidia-smi` 和 analyzer 使用 GPU provider 的日志；此项不属于
  流媒体协议组验收点 3 的前置条件。

验收描述应写“GB28181 软件模拟设备”，不要把模拟器表述为实体 IPC。

本轮 CPU 开发机的实测范围、浏览器复验、已知限制及手工操作步骤见
[2026-09-04 跨设备更新与复现记录](cross-device-verification-20260904.md)。
