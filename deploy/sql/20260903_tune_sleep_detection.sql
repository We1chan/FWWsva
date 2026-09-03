-- Keep lower-confidence pose candidates for the calibrated positive test3
-- source, while preserving the conservative threshold for the test6/test8
-- negative sources.  The shared model decodes at a lower internal floor; these
-- task values are applied independently by Analyzer::runAlgorithmTask.
-- Idempotent: safe to reapply during local environment recovery.

UPDATE deployment_task_algorithm
SET score_threshold = 0.350,
    nms_threshold = 0.700
WHERE deployment_id IN ('controlH87UlyOJCtFwOq', 'controliDWtaBsTRom2rH')
  AND algorithm_code = 'on_yolo11n_pose_sleep';

UPDATE deployment_task_algorithm
SET score_threshold = 0.150,
    nms_threshold = 0.700
WHERE deployment_id = 'controlTest3Sleep20260903'
  AND algorithm_code = 'on_yolo11n_pose_sleep';

-- Production classroom negatives contain short 5-8 second writing/reading
-- poses that resemble sleep when eyes are occluded.  Keep their conservative
-- 15-second pose fallback.  The short close-up test3 sample needs five seconds
-- because its complete sleep/awake cycle is only about 23 seconds.
UPDATE deployment_task
SET geometry_config = JSON_SET(geometry_config, '$.behaviorRules[0].thresholdMs', 15000)
WHERE deployment_id IN ('controlH87UlyOJCtFwOq', 'controliDWtaBsTRom2rH');

UPDATE deployment_task
SET geometry_config = JSON_SET(geometry_config, '$.behaviorRules[0].thresholdMs', 5000)
WHERE deployment_id = 'controlTest3Sleep20260903';
