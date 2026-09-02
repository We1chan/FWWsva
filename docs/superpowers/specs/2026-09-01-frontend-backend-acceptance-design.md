# 前后端业务组验收闭环方案

## 目标与范围

本方案仅覆盖“前后端业务组”在四个验收点中的职责：数据库扩展、后端接口、Vue 页面适配、睡岗告警业务闭环和交付材料。GB28181 的 SIP 注册、RTP 推流和 C++ 睡岗算法推理由流媒体协议组、AI 算法组负责；本组提供其可调用的业务接入面。

## 验收点映射

| 验收点 | 本组交付 |
| --- | --- |
| 1 基础部署 | 记录现有设备→ZLM→Analyzer→告警库→页面链路，确认原 RTSP 功能回归通过。 |
| 2 睡岗检测 | 建立睡岗告警类型；确保 Analyzer 回传的睡岗事件可落库、带截图查询、在告警列表和详情展示；布控配置可选择睡岗算法/规则。 |
| 3 GB28181 接入 | 从 SIP/GB 平台目录同步国标身份；以显式绑定关联 ZLMediaKit 媒体；统一返回预览 URL；状态同步；设备管理页按类型展示和筛选。 |
| 4 整体联调 | RTSP 和 GB28181 都可建布控、产生睡岗告警并在前端查看截图；验证设备断线重连、布控启停和原功能回归；补齐部署、设计、演示材料。 |

## 架构决策

采用“统一业务设备 + 权威目录分流”模型。`h_device` 继续承载既有 RTSP、前端、布控和告警关联；`gb28181_channel` 保存国标平台的权威身份。RTSP 继续使用既有 `DIRECT` 代理逻辑；GB28181 媒体由 ZLM 完成 RTP 接收，不调用 `addStreamProxy`。CCTV HLS 测试源属于 `HLS_TEST` 设备，不伪装为 GB28181 通道。

`Gb28181DeviceSyncService` 有两个严格分离的入口：目录同步只接收 SIP/GB 平台提供的 `platformId/deviceId/channelId` 和名称；媒体刷新只读取 ZLM 的 `vhost/app/stream`，匹配目录中显式保存的同一三元组。ZLM 通用流列表没有设备身份，不能创建、命名、删除或下线任何目录通道。媒体缺失仅令通道不可预览，保留目录身份及 SIP 目录在线状态。

睡岗告警沿用 `h_waring`，以 `alarm_type=SLEEP_DUTY`、`alarm_type_name=睡岗告警`、`sva_behavior_type=SLEEP_DUTY` 统一标识。图片仍由 Analyzer 回传并由现有告警素材路径处理；不创建平行告警表。

## 数据与接口契约

`gb28181_channel` 包含 `platform_id`、`device_id`、`channel_id`、`channel_name`、`catalog_online`，并以三者建立唯一键；媒体绑定为 `zlm_server_id/vhost/app/stream`，另保存 `play_url`、`media_online`、`last_media_seen_at`。`h_device.device_type` 可继续用于业务页面分类，但不是 GB28181 身份或媒体绑定的来源。

新增接口：

- `POST /waring/device/gb28181/catalog/sync`：接收或拉取 SIP/GB 平台目录并按身份幂等保存。
- `POST /waring/device/gb28181/status/refresh?zlmServerId=1`：仅以显式绑定刷新媒体可用性；不改变目录身份或目录在线状态。
- `GET /waring/device/list?deviceType=GB28181`：在既有列表中增加类型筛选。

设备列表和详情统一返回 `device_type`、`gb_device_id`、`gb_platform_id`、`gb_channel_id`、`last_seen_at`。当设备类型为 `GB28181` 时，`/monitor/{apeId}/start` 不创建 RTSP 代理，只校验在线及可播放流后更新监控状态；预览接口仍返回 `playUrl`。

## 前端交互

设备管理页增加“设备类型”列和筛选框。新增“同步国标设备”按钮，调用同步接口后提示同步统计并刷新表格。手动新增设备默认 RTSP；切换为 GB28181 后只读展示同步获得的国标字段，不能输入 RTSP 地址。实时预览、布控设备选择器和大屏继续使用现有设备列表与 `preview` 接口。

告警页增加“睡岗告警”快速筛选、类型标签和 `sva_behavior_type` 展示；告警详情始终显示设备类型与告警截图。布控配置通过既有算法/行为规则来源增加 `SLEEP_DUTY` 选项，不在 Vue 中硬编码模型阈值。

## 错误处理与验收证据

ZLM 不可达、返回格式异常或通道无播放地址必须返回可读错误，且不修改目录身份或非国标设备。重复目录同步不能产生重复行。每个阶段记录数据库查询、接口响应、页面截图和服务日志；最终文档包含可复现命令、测试设备参数和截图/视频清单。
