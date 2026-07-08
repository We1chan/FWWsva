# easySVA

#### 介绍
easySVA（easy Surveillance Video Analytics）是一款面向中小企业的轻量化分布式 AI 视频分析系统。项目基于若依前后端分离框架开发，AI 分析器采用 C++ 实现，允许大模型对告警结果进行复核。整体架构清晰、代码简洁规范，非常适合零基础及初学者入门学习视频分析相关技术。

#### 软件架构
本仓库中为一键源码编译的脚本，会自动安装开发环境、源代码并进行编译。
项目本身的源代码分在三个仓库中。

SVA-backend  系统后台     https://gitee.com/andersonwu/SVA-backend
SVA-web      系统前端     https://gitee.com/andersonwu/SVA-web
SVA-server   C++分析器    https://gitee.com/andersonwu/SVA-server


#### 安装教程
##### 源代码编译
1. 推荐使用ubuntu22.04。下载install_source.sh脚本和easySVA-lib.zip文件，并拷贝到/opt目录下。easySVA-lib.zip包含了cuda、onnxruntime、ffmepg、opencv等所需代码。
2. 以root身份执行install_source.sh脚本就可以进行安装，过程中需要选择编译GPU版本还是CPU版本，最后如果选择了部署，那么系统重启会自动启动所有服务
3. 数据库中zlm_server和sva_server的IP地址为127.0.0.1,需要修改为实际的IP地址。

easySVA-lib.zip下载地址pan.quark.cn/s/b13f7c9baf9e

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
