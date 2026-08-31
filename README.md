# easySVA

#### 介绍
easySVA（easy Surveillance Video Analytics）是一款面向中小企业的轻量化分布式 AI 视频分析系统。项目基于若依前后端分离框架开发，AI 分析器采用 C++ 实现，允许大模型对告警结果进行复核。整体架构清晰、代码简洁规范，非常适合零基础及初学者入门学习视频分析相关技术。

#### 软件架构
本仓库是easySVA的部署入口，包含一键源码编译脚本和数据库初始化文件。业务源码及流媒体服务位于以下仓库，安装脚本会自动从GitHub克隆并编译：

- [SVA-backend](https://github.com/We1chan/SVA-backend)  系统后台（Java / Spring Boot）
- [SVA-web](https://github.com/We1chan/SVA-web)  系统前端（Vue 2）
- [SVA-server](https://github.com/We1chan/SVA-server)  C++ AI视频分析器
- [SVA-mediaServer](https://github.com/We1chan/SVA-mediaServer)  流媒体服务（基于ZLMediaKit）


#### 安装教程
##### 环境要求

- Ubuntu 22.04 x86_64
- CPU版本无需NVIDIA显卡
- GPU版本需要NVIDIA GPU，并满足安装脚本提示的驱动版本要求
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

3. 根据提示选择GPU或CPU版本；安装结束时选择部署，重启系统后服务会自动启动。

4. 浏览器访问 `http://服务器IP/`，默认账号为 `admin`，默认密码为 `admin123`。

5. 数据库中的 `zlm_server` 和 `sva_server` 默认地址为 `127.0.0.1`。分布式部署时需要改成对应服务器的实际IP地址。

WSL2 验收环境的服务结构、端口、日志命令与验收步骤见 [验收点1：部署与架构说明](docs/验收点1-部署与架构说明.md)。

如需使用仓库镜像或其他GitHub所有者，可在安装前设置 `EASYSVA_REPO_BASE`；如依赖包不在 `/opt`，可设置 `EASYSVA_LIB_ARCHIVE`。

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
