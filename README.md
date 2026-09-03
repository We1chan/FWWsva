# easySVA

#### 介绍
easySVA（easy Surveillance Video Analytics）是一款面向中小企业的轻量化分布式 AI 视频分析系统。项目基于若依前后端分离框架开发，AI 分析器采用 C++ 实现，允许大模型对告警结果进行复核。整体架构清晰、代码简洁规范，非常适合零基础及初学者入门学习视频分析相关技术。

#### 软件架构
本仓库是easySVA的部署入口，包含一键源码编译脚本和数据库初始化文件。业务源码及流媒体服务位于以下仓库，安装脚本会自动从GitHub克隆并编译：

- [SVA-backend](https://github.com/We1chan/SVA-backend)  系统后台（Java / Spring Boot）
- [SVA-web](https://github.com/We1chan/SVA-web)  系统前端（Vue 2）
- [SVA-server](https://github.com/We1chan/SVA-server)  C++ AI视频分析器
- [SVA-mediaServer](https://github.com/We1chan/SVA-mediaServer)  流媒体服务（基于ZLMediaKit）
- [wvp-GB28181-pro](https://github.com/648540858/wvp-GB28181-pro)  GB28181 SIP信令服务

流媒体协议组的跨仓库职责、数据流和维护约束见
[GB28181 代码地图](docs/gb28181-code-map.md)；在另一台 CPU/GPU、原生 Ubuntu
或 WSL2 电脑部署时，请先阅读
[流媒体协议组跨电脑部署与验收指南](docs/gb28181-cross-machine-guide.md)。


#### 安装教程
##### 环境要求

- Ubuntu 22.04 x86_64
- CPU版本无需NVIDIA显卡
- GPU版本需要NVIDIA GPU，并满足安装脚本提示的驱动版本要求；WSL2 使用 Windows 主机驱动，不要在 WSL 内另装 Linux 显卡驱动
- 安装和源码编译通常需要30分钟以上

##### 源代码部署

1. 下载依赖包 `easySVA-lib.zip` 到 `/opt/easySVA-lib.zip`。该文件包含CUDA、ONNX Runtime、FFmpeg、OpenCV、模型等大型依赖。

   下载地址：https://pan.quark.cn/s/b13f7c9baf9e

2. 在目标Ubuntu设备上执行：

```bash
sudo apt update
sudo apt install -y git unzip
cd /opt
sudo git clone https://github.com/We1chan/FWWsva.git
sudo -s
chmod +x /opt/FWWsva/install_source.sh
/opt/FWWsva/install_source.sh
```

3. 根据提示选择GPU或CPU版本。GPU模式会同时编译 GPU Analyzer 和 CPU 回退版本；CPU模式只安装CPU运行库。安装脚本会使用 Java 17 编译 easySVA 后端、使用 Java 21 编译 WVP，并初始化 `easySVA` 与 `wvp` 两个数据库。安装结束时选择部署，脚本会安装systemd服务和自动选择启动器，重启后服务会自动启动。

4. 浏览器访问 `http://服务器IP/`，默认账号为 `admin`，默认密码为 `admin123`。

5. 数据库中的 `zlm_server` 和 `sva_server` 默认地址为 `127.0.0.1`。分布式部署时需要改成对应服务器的实际IP地址。

WSL2 验收环境的服务结构、GPU 验证、端口、日志命令与验收步骤见 [验收点1：部署与架构说明](docs/验收点1-部署与架构说明.md)。

WSL2 验收部署会在服务启动时自动检测 NVIDIA GPU 和 CUDA 依赖；检测失败时自动使用 CPU Analyzer。双击 `关闭easySVA.bat` 会关闭共享 WSL 虚拟机并释放 `vmmemWSL`，因此也会停止其他 WSL 发行版和 Docker 的 WSL 后端；使用 `--distro-only` 可只终止 easySVA。

双击 `启动easySVA.bat` 时会在 ZLMediaKit 启动后自动恢复数据库中状态为 `RUNNING` 的直连设备代理，避免 WSL 完全关闭后出现“设备仍显示运行、预览却没有画面”。示例与候选视频源见 [`deploy/sample-streams.tsv`](deploy/sample-streams.tsv)；验收演示优先使用本地 RTSP 模拟源，公网 HLS 源可能受网络、代理和源站可用性影响。

如需使用仓库镜像或其他GitHub所有者，可在安装前设置 `EASYSVA_REPO_BASE`；如依赖包不在 `/opt`，可设置 `EASYSVA_LIB_ARCHIVE`。当前 FWWsva 安装器默认固定另外四个业务仓库和 WVP 的已审核提交，避免不同电脑因分支继续变化而安装到不同代码。只有在目标提交已经复核时，才使用 `EASYSVA_MEDIA_SERVER_REF`、`EASYSVA_SERVER_REF`、`EASYSVA_BACKEND_REF`、`EASYSVA_WEB_REF`、`EASYSVA_WVP_REPO` 或 `EASYSVA_WVP_REF` 覆盖。

##### GB28181设备接入

部署并重启后，执行以下命令确认后端、WVP、SIP 和独立 ZLMediaKit 均已就绪。
SIP TCP/UDP 至少应有与设备配置一致的一种监听成功；WSL 的 Windows 动态端口排除
可能使其中一种显示警告，排查方法见跨电脑部署指南：

```bash
sudo easysva-gb-health
```

国标摄像机的平台接入参数如下：

- SIP服务器地址：easySVA所在服务器可被摄像机访问的IPv4地址
- SIP服务器端口：`5060`，同时支持TCP和UDP
- SIP服务器域：`4401020049`
- SIP服务器ID：`44010200492000000001`
- SIP认证密码：默认 `admin123`

生产部署应在首次安装前通过环境变量设置独立强密码，例如：

```bash
export EASYSVA_GB28181_SIP_PASSWORD='replace_with_a_strong_password'
export EASYSVA_GB28181_ZLM_SECRET='replace_with_a_private_zlm_secret'
export EASYSVA_WVP_DB_PASSWORD='replace_with_a_database_password'
/opt/FWWsva/install_source.sh
```

密码和数据库连接信息安装后保存在 `/etc/easySVA/gb28181.env`，权限为 `0600`。如服务器有多个网卡或自动探测到的地址不是摄像机可达地址，可在安装前设置 `EASYSVA_GB28181_HOST_IP`。防火墙启用 UFW 时，安装器会放行 SIP、国标预览和 RTP 所需端口；外部防火墙仍需放行 `5060/tcp`、`5060/udp`、`9996/tcp`、`9997/tcp`、`10000/udp`、`40002:45000/udp` 和 `50000:55000/udp`。

服务日志和状态可通过以下命令检查：

```bash
sudo systemctl status easysva-gb-media easysva-wvp
sudo journalctl -u easysva-gb-media -u easysva-wvp -n 200 --no-pager
```

##### 业务迁移、同步与回滚

升级已有数据库前先备份，并执行可重复运行的业务迁移；脚本只补充 GB28181 目录字段和 `SLEEP_DUTY` 告警类型，不删除已有 RTSP 或告警数据：

```bash
mysqldump -uroot -p easySVA > /var/backups/easySVA-before-gb28181.sql
mysql -uroot -p easySVA < /opt/FWWsva/deploy/sql/20260901_gb28181_business.sql
```

GB28181 目录同步由设备页的「同步国标设备」按钮或后端管理接口触发；同步后用 `sudo easysva-gb-health` 检查 WVP、SIP 与国标媒体服务。离线通道会保留目录身份并标为离线，不会删除历史设备。若需回退应用版本，先停止后端与协议服务、恢复上述备份，再部署与备份匹配的应用版本；不要对已运行的生产库直接执行初始化 SQL。

睡岗告警使用 `SLEEP_DUTY` 类型，和其他告警一样写入 `h_waring`。验收时应确认「告警管理」可按“睡岗告警”筛选、详情同时显示设备类型和抓拍；空抓拍或加载失败会显示占位，不能以占位替代真实图片留存。

##### 历史告警图片对账

历史记录引用的图片可能已被清理或是 0 字节文件。不要复制其他告警图片来伪造历史截图。部署仓库提供安全对账工具：默认只报告；只有存在于 nginx 告警目录且非空的普通文件才会在 `--apply` 模式下规范化 `picture_url` 和 `picture_absolute_url`。跨出 `alarm/` 的符号链接、目录和不安全路径均不写入；URL 已正确的行保持不变。

```bash
cd /opt/FWWsva
sudo ALARM_PUBLIC_BASE_URL='http://服务器IP' \
  MYSQL_USER=root MYSQL_DATABASE=easySVA \
  bash deploy/scripts/reconcile-alarm-images.sh

# 先备份数据库、审核报告并暂停图片清理/目录变动，再执行写入
sudo ALARM_PUBLIC_BASE_URL='http://服务器IP' \
  MYSQL_USER=root MYSQL_DATABASE=easySVA \
  bash deploy/scripts/reconcile-alarm-images.sh --apply
```

可通过 `ALARM_UPLOAD_ROOT` 指定上传根目录（默认 `/var/www/SVA-web/upload`）；需要口令时通过安全的环境变量 `MYSQL_PASSWORD` 或 mysql 客户端配置提供，不要把口令写进脚本或命令历史。`ALARM_PUBLIC_BASE_URL` 必须是浏览器可访问的站点地址，而不是直接使用默认回环地址。

报告区分 `missing`、`unsafe`、`unchanged` 和待修复的 `eligible`。查询失败会非零退出且不开始更新；写入失败也会非零退出，前面已成功写入的行不会自动回滚，修正问题后可重新运行。更新前比较原 URL，若发生并发修改则记为 `conflicted` 跳过。数据库备份用于必要时恢复；脚本不会修改图片文件。缺失路径仅报告，不修改数据库；先从同一事件的原始素材恢复文件后再重新对账。非空文件检查不等同于图片可解码或 HTTP 可访问，仍需逐项验证浏览器实际加载。

2026-09-03 的本机只读对账：63 条带图片路径的记录中，59 条文件缺失、1 条 URL 无需改变、3 条现存演示图片可规范化，实际更新 0 条。历史原图缺失仍是验收限制，新演示图片不能替代历史证据。

#### 使用说明

1.  在设备管理中添加设备
2.  启动监控后能在视频预览里看到视频。//当前版本尚不支持h265的预览，下个版本解决
3.  添加布控》添加规则，然后启动布控就能够使用

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 技术交流群
欢迎添加微信交流：
![添加微信](docs/images/weixin.png)

QQ群   1050621062  easySVA交流群
