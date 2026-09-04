-- GB28181 catalog and sleep-duty business model. Safe to re-run on MariaDB 10.6.
-- The SIP/GB catalog is the authority for platform/device/channel identity.
-- ZLM getMediaList is used only to refresh the explicit vhost/app/stream binding.

CREATE TABLE IF NOT EXISTS gb28181_channel (
    id bigint NOT NULL AUTO_INCREMENT,
    platform_id varchar(64) NOT NULL COMMENT 'GB平台ID',
    device_id varchar(64) NOT NULL COMMENT 'GB设备ID',
    channel_id varchar(64) NOT NULL COMMENT 'GB通道ID',
    channel_name varchar(128) NULL COMMENT '目录通道名称',
    catalog_online tinyint(1) NOT NULL DEFAULT 0 COMMENT 'SIP/目录在线状态',
    zlm_server_id bigint NULL COMMENT '显式绑定的ZLM节点',
    vhost varchar(128) NULL COMMENT '显式媒体vhost',
    app varchar(128) NULL COMMENT '显式媒体app',
    stream varchar(255) NULL COMMENT '显式媒体stream',
    play_url varchar(512) NULL COMMENT '目录或平台提供的播放地址',
    media_online tinyint(1) NOT NULL DEFAULT 0 COMMENT 'ZLM媒体当前可用',
    last_media_seen_at datetime NULL COMMENT '最近检测到媒体的时间',
    create_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_gb28181_catalog_identity (platform_id, device_id, channel_id),
    KEY idx_gb28181_channel_zlm_binding (zlm_server_id, vhost, app, stream)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='GB28181 SIP目录及显式媒体绑定';

-- Keep the pre-existing unified h_device extension compatible with deployments
-- that already applied the earlier Phase 1 draft. It is not the catalog authority;
-- gb28181_channel above owns the SIP/GB identity. h_device keeps denormalized mirror
-- columns so existing RTSP list/detail SQL keeps working and device pages can filter.
SET @schema_name = DATABASE();

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'device_type') = 0,
    'ALTER TABLE h_device ADD COLUMN device_type varchar(16) NOT NULL DEFAULT ''RTSP'' COMMENT ''设备类型: RTSP/GB28181/HLS_TEST'' AFTER zlm_proxy_key', 'SELECT 1');
PREPARE s1 FROM @ddl; EXECUTE s1; DEALLOCATE PREPARE s1;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'gb_device_id') = 0,
    'ALTER TABLE h_device ADD COLUMN gb_device_id varchar(64) NULL COMMENT ''GB设备ID(镜像,非权威)'' AFTER device_type', 'SELECT 1');
PREPARE s2 FROM @ddl; EXECUTE s2; DEALLOCATE PREPARE s2;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'gb_platform_id') = 0,
    'ALTER TABLE h_device ADD COLUMN gb_platform_id varchar(64) NULL COMMENT ''GB平台ID(镜像,非权威)'' AFTER gb_device_id', 'SELECT 1');
PREPARE s3 FROM @ddl; EXECUTE s3; DEALLOCATE PREPARE s3;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'gb_channel_id') = 0,
    'ALTER TABLE h_device ADD COLUMN gb_channel_id varchar(64) NULL COMMENT ''GB通道ID(镜像,非权威)'' AFTER gb_platform_id', 'SELECT 1');
PREPARE s4 FROM @ddl; EXECUTE s4; DEALLOCATE PREPARE s4;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'last_seen_at') = 0,
    'ALTER TABLE h_device ADD COLUMN last_seen_at datetime NULL COMMENT ''最近同步时间'' AFTER gb_channel_id', 'SELECT 1');
PREPARE s5 FROM @ddl; EXECUTE s5; DEALLOCATE PREPARE s5;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'sync_source') = 0,
    'ALTER TABLE h_device ADD COLUMN sync_source varchar(32) NULL COMMENT ''同步来源: GB28181目录/manual'' AFTER last_seen_at', 'SELECT 1');
PREPARE s6 FROM @ddl; EXECUTE s6; DEALLOCATE PREPARE s6;

-- Keep this aggregate migration in sync with the backend's GB stream routing
-- fields.  The current mapper selects these columns for every device, including
-- ordinary DIRECT/RTSP devices, so omitting one prevents all device APIs from
-- loading after an upgrade.
SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'gb_media_server_id') = 0,
    'ALTER TABLE h_device ADD COLUMN gb_media_server_id varchar(50) NULL COMMENT ''WVP媒体服务器ID'' AFTER gb_channel_id', 'SELECT 1');
PREPARE s7 FROM @ddl; EXECUTE s7; DEALLOCATE PREPARE s7;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'gb_stream_id') = 0,
    'ALTER TABLE h_device ADD COLUMN gb_stream_id varchar(255) NULL COMMENT ''当前WVP/ZLM流ID'' AFTER gb_media_server_id', 'SELECT 1');
PREPARE s8 FROM @ddl; EXECUTE s8; DEALLOCATE PREPARE s8;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'gb_stream_url') = 0,
    'ALTER TABLE h_device ADD COLUMN gb_stream_url varchar(1024) NULL COMMENT ''当前WVP/ZLM RTSP流地址'' AFTER gb_stream_id', 'SELECT 1');
PREPARE s9 FROM @ddl; EXECUTE s9; DEALLOCATE PREPARE s9;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'h_device' AND column_name = 'gb_last_sync_time') = 0,
    'ALTER TABLE h_device ADD COLUMN gb_last_sync_time datetime NULL COMMENT ''最近一次WVP同步时间'' AFTER gb_stream_url', 'SELECT 1');
PREPARE s10 FROM @ddl; EXECUTE s10; DEALLOCATE PREPARE s10;

-- Existing WVP-synchronized rows predate device_type. ALTER TABLE fills the new
-- NOT NULL column with its RTSP default, so restore their actual access type.
UPDATE h_device
SET device_type = 'GB28181'
WHERE UPPER(stream_source_type) = 'GB28181'
  AND device_type <> 'GB28181';

-- upsertGbDevice relies on a unique ape_id. Add it only when no duplicate exists so
-- existing RTSP rows never block the migration.
SET @dup_ape = (SELECT COUNT(*) FROM (SELECT ape_id FROM h_device GROUP BY ape_id HAVING COUNT(*) > 1) t);
SET @has_uk = (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE table_schema = @schema_name AND table_name = 'h_device' AND index_name = 'uk_h_device_ape_id');
SET @ddl = IF(@has_uk = 0 AND @dup_ape = 0, 'ALTER TABLE h_device ADD UNIQUE KEY uk_h_device_ape_id (ape_id)', 'SELECT 1');
PREPARE s11 FROM @ddl; EXECUTE s11; DEALLOCATE PREPARE s11;

INSERT INTO h_waring_type (device_id, device_name, alarm_type, alarm_type_name, is_handle, create_time, update_time)
SELECT 'SYSTEM', '系统', 'SLEEP_DUTY', '睡岗告警', 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM h_waring_type WHERE alarm_type = 'SLEEP_DUTY');

-- Register the production hybrid pose/eye model in the algorithm selector.
-- The Analyzer resolves this code to yolo11n-pose.onnx plus the bundled eye
-- classifier and only exposes person as a selectable target.
INSERT INTO av_algorithm
    (sort, code, name, api_url, object_str, state)
SELECT
    COALESCE((SELECT MAX(existing.sort) + 1 FROM av_algorithm existing), 0),
    'on_yolo11n_pose_sleep', '睡岗检测（姿态+眼部）', '', 'person', 0
WHERE NOT EXISTS (
    SELECT 1 FROM av_algorithm WHERE code = 'on_yolo11n_pose_sleep'
);
