-- Configure the four-source acceptance layout:
--   GB28181: test6 and a second test3 source
--   RTSP:    the existing test8 and test3 sources
-- The two GB ape_id values are Java UUID.nameUUIDFromBytes(deviceId:channelId)
-- outputs, so the WVP catalog scheduler upserts these same rows.

INSERT INTO h_device
    (ape_id, name, device_type, stream_source_type, gb_device_id, gb_channel_id,
     gb_media_server_id, resource_type, org_index, org_name, is_online,
     zlm_server_id, sva_server_id, monitor_status, create_time, update_time)
VALUES
    ('GB_9e678b6ebac4374fb590056a2d16b046', 'GB28181-test6', 'GB28181', 'GB28181',
     '44010200491320000006', '44010200491320000016', 'easysva-gb28181',
     'GB28181', '103', '研发部门', '0', 1, 1, 'STOPPED', NOW(), NOW()),
    ('GB_f69bf7102081394fb64b6fcd68899b47', 'GB28181-test3', 'GB28181', 'GB28181',
     '44010200491320000003', '44010200491320000013', 'easysva-gb28181',
     'GB28181', '103', '研发部门', '0', 1, 1, 'STOPPED', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    name = VALUES(name), device_type = 'GB28181', stream_source_type = 'GB28181',
    gb_device_id = VALUES(gb_device_id), gb_channel_id = VALUES(gb_channel_id),
    gb_media_server_id = VALUES(gb_media_server_id), resource_type = VALUES(resource_type),
    org_index = VALUES(org_index), org_name = VALUES(org_name),
    zlm_server_id = VALUES(zlm_server_id), sva_server_id = VALUES(sva_server_id),
    update_time = NOW();

-- Reuse the existing test6 task identity so historical alarms and screen-wall
-- references continue to resolve, but bind it to the GB catalog identity.
UPDATE deployment_task
SET task_name = 'GB-test6-睡岗检测',
    device_id = 'GB_9e678b6ebac4374fb590056a2d16b046',
    remark = 'test6 全片：GB28181 接入；Pose 初筛 + 眼部确认 + 严格姿态回退',
    stream_url = NULL,
    status = 'CREATED',
    start_time = NULL,
    stop_time = NOW(),
    update_time = NOW()
WHERE deployment_id = 'controliDWtaBsTRom2rH'
  AND device_id = 'cam228703';

INSERT INTO deployment_task
    (deployment_id, task_name, device_id, algorithm_code, algorithm_name, target_code,
     push_enabled, frontend_overlay_enabled, record_engine, alarm_interval_sec,
     dwell_enabled, dwell_threshold_ms, ai_review_enabled, remark, geometry_config,
     stream_url, push_stream_url, algorithm_stream_url, status,
     create_time, update_time)
VALUES
    ('controlGbTest3Sleep20260903', 'GB-test3-睡岗检测',
     'GB_f69bf7102081394fb64b6fcd68899b47',
     'on_yolo11n_pose_sleep', '睡岗检测（姿态+眼部）', 'person', 1, 0, 'A-SERVER', 30,
     0, 15000, 0, 'test3 全片：GB28181 接入；Pose 初筛 + 眼部确认 + 严格姿态回退',
     '{"regions":[{"id":"region_primary","name":"全画面","type":"polygon","primary":true,"closed":true,"points":[{"x":0.03,"y":0.03},{"x":0.97,"y":0.03},{"x":0.97,"y":0.97},{"x":0.03,"y":0.97}]}],"lines":[],"behaviorRules":[{"id":"sleep-rule-gb-test3","name":"睡岗告警","customEventName":"睡岗告警","behaviorType":"sleep_duty","outputMode":"direct_alarm","enabled":true,"geometryType":"region","geometryId":"region_primary","thresholdMs":5000,"ruleObjectCode":"person"}]}',
     NULL,
     'rtmp://127.0.0.1:9995/analyzer/controlGbTest3Sleep20260903',
     'ws://127.0.0.1:9992/analyzer/controlGbTest3Sleep20260903.live.flv',
     'CREATED', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    task_name = VALUES(task_name), device_id = VALUES(device_id),
    algorithm_code = VALUES(algorithm_code), algorithm_name = VALUES(algorithm_name),
    target_code = VALUES(target_code), push_enabled = VALUES(push_enabled),
    frontend_overlay_enabled = VALUES(frontend_overlay_enabled),
    record_engine = VALUES(record_engine), alarm_interval_sec = VALUES(alarm_interval_sec),
    dwell_enabled = VALUES(dwell_enabled), dwell_threshold_ms = VALUES(dwell_threshold_ms),
    ai_review_enabled = VALUES(ai_review_enabled), remark = VALUES(remark),
    geometry_config = VALUES(geometry_config), push_stream_url = VALUES(push_stream_url),
    algorithm_stream_url = VALUES(algorithm_stream_url), update_time = NOW();

DELETE FROM deployment_task_algorithm
WHERE deployment_id = 'controlGbTest3Sleep20260903'
  AND algorithm_code = 'on_yolo11n_pose_sleep';

INSERT INTO deployment_task_algorithm
    (deployment_id, algorithm_code, algorithm_name, detect_fps,
     score_threshold, nms_threshold, target_codes, sort_order, create_time, update_time)
VALUES
    ('controlGbTest3Sleep20260903', 'on_yolo11n_pose_sleep',
     '睡岗检测（姿态+眼部）', 10, 0.150, 0.700, 'person', 0, NOW(), NOW());

DELETE FROM h_screen_wall_stream
WHERE wall_code = 'main'
  AND source_id IN ('controliDWtaBsTRom2rH', 'controlH87UlyOJCtFwOq',
                    'controlTest3Sleep20260903', 'controlGbTest3Sleep20260903');

INSERT INTO h_screen_wall_stream
    (wall_code, source_type, source_id, device_id, play_url, title,
     slot_index, enabled, create_time, update_time)
VALUES
    ('main', 'task', 'controliDWtaBsTRom2rH', 'GB_9e678b6ebac4374fb590056a2d16b046',
     'ws://127.0.0.1:9992/analyzer/controliDWtaBsTRom2rH.live.flv',
     'GB-test6 睡岗检测（带YOLO框）', 0, 1, NOW(), NOW()),
    ('main', 'task', 'controlH87UlyOJCtFwOq', 'cam228704',
     'ws://127.0.0.1:9992/analyzer/controlH87UlyOJCtFwOq.live.flv',
     'RTSP-test8 睡岗检测（带YOLO框）', 1, 1, NOW(), NOW()),
    ('main', 'task', 'controlTest3Sleep20260903', 'cam228705',
     'ws://127.0.0.1:9992/analyzer/controlTest3Sleep20260903.live.flv',
     'RTSP-test3 睡岗检测（带YOLO框）', 2, 1, NOW(), NOW()),
    ('main', 'task', 'controlGbTest3Sleep20260903', 'GB_f69bf7102081394fb64b6fcd68899b47',
     'ws://127.0.0.1:9992/analyzer/controlGbTest3Sleep20260903.live.flv',
     'GB-test3 睡岗检测（带YOLO框）', 3, 1, NOW(), NOW());

-- The old test6 DIRECT device is no longer exposed in easySVA. Its local RTSP
-- producer remains active solely as the media input of the GB software camera.
DELETE FROM h_device WHERE ape_id = 'cam228703';
