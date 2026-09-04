-- Install the three local RTSP sample cameras and their sleep-duty tasks.
-- The legacy filename is retained because older deployments may already refer to it.
-- Idempotent: safe to run again after pulling a newer checkout.
-- Cross-device safety: records are installed STOPPED. Start one task from the
-- UI only after its media source and model are ready and machine load is known.

-- Match the backend GB28181 default organization. A custom organization can be
-- supplied as session variables before sourcing this file (and the mixed file).
SET @easysva_sample_org_index = COALESCE(@easysva_sample_org_index, '103');
SET @easysva_sample_org_name = COALESCE(@easysva_sample_org_name, '研发部门');

INSERT INTO h_device
    (ape_id, name, org_index, org_name, is_online, stream_source_type,
     direct_source_url, monitor_status, zlm_server_id, sva_server_id,
     play_url, zlm_proxy_key, device_type, create_time, update_time)
VALUES
    ('cam228703', '模拟RTSP摄像头-test6', @easysva_sample_org_index, @easysva_sample_org_name, '1', 'DIRECT',
     'rtsp://127.0.0.1:9994/live/mock-camera', 'STOPPED', 1, 1,
     'ws://127.0.0.1:9992/live/cam228703.live.flv', '__defaultVhost__/live/cam228703', 'RTSP', NOW(), NOW()),
    ('cam228704', '模拟RTSP摄像头-test8', @easysva_sample_org_index, @easysva_sample_org_name, '1', 'DIRECT',
     'rtsp://127.0.0.1:9994/live/mock-camera-2', 'STOPPED', 1, 1,
     'ws://127.0.0.1:9992/live/cam228704.live.flv', '__defaultVhost__/live/cam228704', 'RTSP', NOW(), NOW()),
    ('cam228705', '模拟RTSP摄像头-test3', @easysva_sample_org_index, @easysva_sample_org_name, '1', 'DIRECT',
     'rtsp://127.0.0.1:9994/live/mock-camera-3', 'STOPPED', 1, 1,
     'ws://127.0.0.1:9992/live/cam228705.live.flv', '__defaultVhost__/live/cam228705', 'RTSP', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    name = VALUES(name), org_index = VALUES(org_index), org_name = VALUES(org_name),
    is_online = VALUES(is_online), stream_source_type = VALUES(stream_source_type),
    direct_source_url = VALUES(direct_source_url), monitor_status = VALUES(monitor_status),
    zlm_server_id = VALUES(zlm_server_id), sva_server_id = VALUES(sva_server_id),
    play_url = VALUES(play_url), zlm_proxy_key = VALUES(zlm_proxy_key),
    device_type = VALUES(device_type), update_time = NOW();

INSERT INTO deployment_task
    (deployment_id, task_name, device_id, algorithm_code, algorithm_name, target_code,
     push_enabled, frontend_overlay_enabled, record_engine, alarm_interval_sec,
     dwell_enabled, dwell_threshold_ms, ai_review_enabled, remark, geometry_config,
     stream_url, push_stream_url, algorithm_stream_url, status, start_time,
     create_time, update_time)
VALUES
    ('controliDWtaBsTRom2rH', 'RTSP-test6-睡岗检测', 'cam228703',
     'on_yolo11n_pose_sleep', '睡岗检测（姿态+眼部）', 'person', 1, 0, 'A-SERVER', 30,
     0, 15000, 0, 'test6 全片：Pose 初筛 + 眼部确认 + 严格姿态回退',
     '{"regions":[{"id":"region_primary","name":"全画面","type":"polygon","primary":true,"closed":true,"points":[{"x":0.03,"y":0.03},{"x":0.97,"y":0.03},{"x":0.97,"y":0.97},{"x":0.03,"y":0.97}]}],"lines":[],"behaviorRules":[{"id":"sleep-rule-test6","name":"睡岗告警","customEventName":"睡岗告警","behaviorType":"sleep_duty","outputMode":"direct_alarm","enabled":true,"geometryType":"region","geometryId":"region_primary","thresholdMs":15000,"ruleObjectCode":"person"}]}',
     'rtsp://127.0.0.1:9994/live/cam228703',
     'rtmp://127.0.0.1:9995/analyzer/controliDWtaBsTRom2rH',
     'ws://127.0.0.1:9992/analyzer/controliDWtaBsTRom2rH.live.flv', 'STOPPED', NULL, NOW(), NOW()),
    ('controlH87UlyOJCtFwOq', 'RTSP-test8-睡岗检测', 'cam228704',
     'on_yolo11n_pose_sleep', '睡岗检测（姿态+眼部）', 'person', 1, 0, 'A-SERVER', 30,
     0, 15000, 0, 'test8 全片：Pose 初筛 + 眼部确认 + 严格姿态回退',
     '{"regions":[{"id":"region_primary","name":"全画面","type":"polygon","primary":true,"closed":true,"points":[{"x":0.03,"y":0.03},{"x":0.97,"y":0.03},{"x":0.97,"y":0.97},{"x":0.03,"y":0.97}]}],"lines":[],"behaviorRules":[{"id":"sleep-rule-test8","name":"睡岗告警","customEventName":"睡岗告警","behaviorType":"sleep_duty","outputMode":"direct_alarm","enabled":true,"geometryType":"region","geometryId":"region_primary","thresholdMs":15000,"ruleObjectCode":"person"}]}',
     'rtsp://127.0.0.1:9994/live/cam228704',
     'rtmp://127.0.0.1:9995/analyzer/controlH87UlyOJCtFwOq',
     'ws://127.0.0.1:9992/analyzer/controlH87UlyOJCtFwOq.live.flv', 'STOPPED', NULL, NOW(), NOW()),
    ('controlTest3Sleep20260903', 'RTSP-test3-睡岗检测', 'cam228705',
     'on_yolo11n_pose_sleep', '睡岗检测（姿态+眼部）', 'person', 1, 0, 'A-SERVER', 30,
     0, 15000, 0, 'test3 全片：Pose 初筛 + 眼部确认 + 严格姿态回退',
     '{"regions":[{"id":"region_primary","name":"全画面","type":"polygon","primary":true,"closed":true,"points":[{"x":0.03,"y":0.03},{"x":0.97,"y":0.03},{"x":0.97,"y":0.97},{"x":0.03,"y":0.97}]}],"lines":[],"behaviorRules":[{"id":"sleep-rule-test3","name":"睡岗告警","customEventName":"睡岗告警","behaviorType":"sleep_duty","outputMode":"direct_alarm","enabled":true,"geometryType":"region","geometryId":"region_primary","thresholdMs":5000,"ruleObjectCode":"person"}]}',
     'rtsp://127.0.0.1:9994/live/cam228705',
     'rtmp://127.0.0.1:9995/analyzer/controlTest3Sleep20260903',
     'ws://127.0.0.1:9992/analyzer/controlTest3Sleep20260903.live.flv', 'STOPPED', NULL, NOW(), NOW())
ON DUPLICATE KEY UPDATE
    task_name = VALUES(task_name), device_id = VALUES(device_id),
    algorithm_code = VALUES(algorithm_code), algorithm_name = VALUES(algorithm_name),
    target_code = VALUES(target_code), push_enabled = VALUES(push_enabled),
    frontend_overlay_enabled = VALUES(frontend_overlay_enabled),
    record_engine = VALUES(record_engine), alarm_interval_sec = VALUES(alarm_interval_sec),
    dwell_enabled = VALUES(dwell_enabled), dwell_threshold_ms = VALUES(dwell_threshold_ms),
    ai_review_enabled = VALUES(ai_review_enabled), remark = VALUES(remark),
    geometry_config = VALUES(geometry_config), stream_url = VALUES(stream_url),
    push_stream_url = VALUES(push_stream_url), algorithm_stream_url = VALUES(algorithm_stream_url),
    status = VALUES(status), start_time = VALUES(start_time), update_time = NOW();

DELETE FROM deployment_task_algorithm
WHERE deployment_id IN ('controliDWtaBsTRom2rH', 'controlH87UlyOJCtFwOq', 'controlTest3Sleep20260903')
  AND algorithm_code = 'on_yolo11n_pose_sleep';

INSERT INTO deployment_task_algorithm
    (deployment_id, algorithm_code, algorithm_name, detect_fps,
     score_threshold, nms_threshold, target_codes, sort_order, create_time, update_time)
VALUES
    ('controliDWtaBsTRom2rH', 'on_yolo11n_pose_sleep', '睡岗检测（姿态+眼部）', 10, 0.350, 0.700, 'person', 0, NOW(), NOW()),
    ('controlH87UlyOJCtFwOq', 'on_yolo11n_pose_sleep', '睡岗检测（姿态+眼部）', 10, 0.350, 0.700, 'person', 0, NOW(), NOW()),
    ('controlTest3Sleep20260903', 'on_yolo11n_pose_sleep', '睡岗检测（姿态+眼部）', 10, 0.150, 0.700, 'person', 0, NOW(), NOW());

DELETE FROM h_screen_wall_stream
WHERE wall_code = 'main'
  AND source_id IN ('controliDWtaBsTRom2rH', 'controlH87UlyOJCtFwOq', 'controlTest3Sleep20260903');

INSERT INTO h_screen_wall_stream
    (wall_code, source_type, source_id, device_id, play_url, title,
     slot_index, enabled, create_time, update_time)
VALUES
    ('main', 'task', 'controliDWtaBsTRom2rH', 'cam228703',
     'ws://127.0.0.1:9992/analyzer/controliDWtaBsTRom2rH.live.flv',
     'test6 睡岗检测（带YOLO框）', 0, 1, NOW(), NOW()),
    ('main', 'task', 'controlH87UlyOJCtFwOq', 'cam228704',
     'ws://127.0.0.1:9992/analyzer/controlH87UlyOJCtFwOq.live.flv',
     'test8 睡岗检测（带YOLO框）', 1, 1, NOW(), NOW()),
    ('main', 'task', 'controlTest3Sleep20260903', 'cam228705',
     'ws://127.0.0.1:9992/analyzer/controlTest3Sleep20260903.live.flv',
     'test3 睡岗检测（带YOLO框）', 2, 1, NOW(), NOW());
