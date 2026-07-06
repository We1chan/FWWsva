/*
 Navicat Premium Dump SQL

 Source Server         : 10.129.52.114-SVA
 Source Server Type    : MariaDB
 Source Server Version : 100623 (10.6.23-MariaDB-0ubuntu0.22.04.1)
 Source Host           : localhost:3306
 Source Schema         : easySVA

 Target Server Type    : MariaDB
 Target Server Version : 100623 (10.6.23-MariaDB-0ubuntu0.22.04.1)
 File Encoding         : 65001

 Date: 20/05/2026 10:50:06
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for ai_review_server
-- ----------------------------
DROP TABLE IF EXISTS `ai_review_server`;
CREATE TABLE `ai_review_server`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '服务名称',
  `server_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'openai' COMMENT '服务类型：openai/aliyun',
  `endpoint_url` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '完整接口地址',
  `model` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '模型名称',
  `api_key` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT 'API Key',
  `timeout_ms` int(11) NOT NULL DEFAULT 15000 COMMENT '超时时间(毫秒)',
  `enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '备注',
  `create_time` datetime NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_ai_review_server_enabled`(`enabled`) USING BTREE,
  INDEX `idx_ai_review_server_type_enabled`(`server_type`, `enabled`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = 'AI复核服务节点' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of ai_review_server
-- ----------------------------
INSERT INTO `ai_review_server` VALUES (1, '阿里云通义千问VL', 'aliyun', 'https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation', 'qwen-vl-max', 'sk-f398d0ec52da4cb6a8897b12df0cd3f6', 30000, 1, 'DashScope Qwen-VL 多模态复核服务', '2026-06-08 19:05:17', '2026-06-08 19:05:17');
INSERT INTO `ai_review_server` VALUES (2, '本地OpenAI兼容复核服务', 'openai', 'http://127.0.0.1:8000/v1/chat/completions', 'qwen3-vl', NULL, 30000, 0, 'OpenAI兼容多模态复核服务', '2026-06-10 08:41:14', '2026-06-10 08:41:51');

-- ----------------------------
-- Table structure for av_algorithm
-- ----------------------------
DROP TABLE IF EXISTS `av_algorithm`;
CREATE TABLE `av_algorithm`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sort` int(11) NOT NULL DEFAULT 0,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `api_url` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `object_count` int(11) NOT NULL DEFAULT 0,
  `object_str` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `remark` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `state` tinyint(4) NOT NULL DEFAULT 0,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_av_algorithm_code`(`code`) USING BTREE,
  INDEX `idx_av_algorithm_state`(`state`) USING BTREE,
  INDEX `idx_av_algorithm_sort`(`sort`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 19 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of av_algorithm
-- ----------------------------
INSERT INTO `av_algorithm` VALUES (1, 0, 'on_yolo26n_80', 'yolo26s_80类目标检测', '', 80, 'person,bicycle,car,motorcycle,airplane,bus,train,truck,boat,traffic light,fire hydrant,stop sign,parking meter,bench,bird,cat,dog,horse,sheep,cow,elephant,bear,zebra,giraffe,backpack,umbrella,handbag,tie,suitcase,frisbee,skis,snowboard,sports ball,kite,baseball bat,baseball glove,skateboard,surfboard,tennis racket,bottle,wine glass,cup,fork,knife,spoon,bowl,banana,apple,sandwich,orange,broccoli,carrot,hot dog,pizza,donut,cake,chair,couch,potted plant,bed,dining table,toilet,tv,laptop,mouse,remote,keyboard,cell phone,microwave,oven,toaster,sink,refrigerator,book,clock,vase,scissors,teddy bear,hair drier,toothbrush', '', 0, '2026-03-19 23:59:24', '2026-04-03 15:28:09');
INSERT INTO `av_algorithm` VALUES (2, 1, 'on_yolo26s_miner', '矿井8类目标检测', '', 8, 'helmet_on,helmet_off,helmet,self-rescuer,towline,support plate,track-car,crane-hook', '', 0, '2026-03-19 23:59:24', '2026-04-03 15:28:09');
INSERT INTO `av_algorithm` VALUES (3, 2, 'on_yolo11n_80', 'yolo11n_80类目标检测', '', 80, 'person,bicycle,car,motorcycle,airplane,bus,train,truck,boat,traffic light,fire hydrant,stop sign,parking meter,bench,bird,cat,dog,horse,sheep,cow,elephant,bear,zebra,giraffe,backpack,umbrella,handbag,tie,suitcase,frisbee,skis,snowboard,sports ball,kite,baseball bat,baseball glove,skateboard,surfboard,tennis racket,bottle,wine glass,cup,fork,knife,spoon,bowl,banana,apple,sandwich,orange,broccoli,carrot,hot dog,pizza,donut,cake,chair,couch,potted plant,bed,dining table,toilet,tv,laptop,mouse,remote,keyboard,cell phone,microwave,oven,toaster,sink,refrigerator,book,clock,vase,scissors,teddy bear,hair drier,toothbrush', '', 0, '2026-03-19 23:59:24', '2026-04-03 15:28:09');
-- ----------------------------
-- Table structure for deployment_business_event_template
-- ----------------------------
DROP TABLE IF EXISTS `deployment_business_event_template`;
CREATE TABLE `deployment_business_event_template`  (
  `template_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `template_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `template_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `template_desc` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `scope_type` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'USER',
  `owner_org_index` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `owner_user_id` bigint(20) NULL DEFAULT NULL,
  `status` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'ACTIVE',
  `version_no` int(11) NOT NULL DEFAULT 1,
  `tags_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `parameter_schema_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `rule_blueprint_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `ui_schema_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`template_id`) USING BTREE,
  INDEX `idx_deployment_business_event_template_code`(`template_code`) USING BTREE,
  INDEX `idx_deployment_business_event_template_scope`(`scope_type`) USING BTREE,
  INDEX `idx_deployment_business_event_template_status`(`status`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of deployment_business_event_template
-- ----------------------------
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000001', 'BEHAVIOR_CROSS_LINE', '跨线告警模板', '基于线段的跨线检测，适合周界穿越、出入口越线等场景。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"line\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"线段ID\",\"description\":\"填写 geometryConfig 中的线段 ID\",\"placeholder\":\"例如：line_1\"},\"direction\":{\"type\":\"string\",\"title\":\"检测方向\",\"enum\":[\"both\",\"a_to_b\",\"b_to_a\"],\"enumNames\":[\"双向\",\"A->B\",\"B->A\"],\"default\":\"both\"}},\"required\":[\"geometryId\"]}', '{\"rule\":{\"id\":\"cross_line\",\"behaviorType\":\"cross_line\",\"geometryType\":\"line\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"direction\":{\"$valueFrom\":\"params.direction\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000002', 'BEHAVIOR_ENTER_REGION', '进区告警模板', '目标进入指定区域时触发，适合禁区入侵、装卸区进入等场景。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"}},\"required\":[\"geometryId\"]}', '{\"rule\":{\"id\":\"enter_region\",\"behaviorType\":\"enter_region\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000003', 'BEHAVIOR_EXIT_REGION', '出区告警模板', '目标离开指定区域时触发，适合重点区域离场监测。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"}},\"required\":[\"geometryId\"]}', '{\"rule\":{\"id\":\"exit_region\",\"behaviorType\":\"exit_region\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000004', 'BEHAVIOR_DWELL', '停留告警模板', '目标在指定区域停留超过阈值时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"temporal\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"停留阈值(毫秒)\",\"minimum\":1,\"default\":5000,\"placeholder\":\"例如：5000\"}},\"required\":[\"geometryId\",\"thresholdMs\"]}', '{\"rule\":{\"id\":\"dwell\",\"behaviorType\":\"dwell\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000005', 'BEHAVIOR_LOW_SPEED', '低速告警模板', '目标在指定区域内持续低速移动时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"temporal\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"持续时长(毫秒)\",\"minimum\":200,\"default\":5000,\"placeholder\":\"例如：5000\"},\"maxSpeedPxPerSec\":{\"type\":\"number\",\"title\":\"最大速度(px/s)\",\"minimum\":0.1,\"default\":12,\"placeholder\":\"例如：12\"}},\"required\":[\"geometryId\",\"thresholdMs\",\"maxSpeedPxPerSec\"]}', '{\"rule\":{\"id\":\"low_speed\",\"behaviorType\":\"low_speed\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"},\"maxSpeedPxPerSec\":{\"$valueFrom\":\"params.maxSpeedPxPerSec\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000006', 'BEHAVIOR_LOITERING', '徘徊告警模板', '目标在指定区域内长时间小范围活动时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"temporal\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"徘徊时长(毫秒)\",\"minimum\":1000,\"default\":10000,\"placeholder\":\"例如：10000\"},\"maxDisplacementPx\":{\"type\":\"number\",\"title\":\"最大位移(px)\",\"minimum\":1,\"default\":80,\"placeholder\":\"例如：80\"}},\"required\":[\"geometryId\",\"thresholdMs\",\"maxDisplacementPx\"]}', '{\"rule\":{\"id\":\"loitering\",\"behaviorType\":\"loitering\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"},\"maxDisplacementPx\":{\"$valueFrom\":\"params.maxDisplacementPx\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000007', 'BEHAVIOR_ABSENCE', '缺席告警模板', '指定区域在持续时长内无人出现时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"temporal\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"缺席时长(毫秒)\",\"minimum\":1,\"default\":5000,\"placeholder\":\"例如：5000\"}},\"required\":[\"geometryId\",\"thresholdMs\"]}', '{\"rule\":{\"id\":\"absence\",\"behaviorType\":\"absence\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000008', 'BEHAVIOR_COUNT_THRESHOLD', '数量阈值模板', '指定区域内目标数量达到阈值时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"count\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"thresholdCount\":{\"type\":\"integer\",\"title\":\"数量阈值\",\"minimum\":1,\"default\":1,\"placeholder\":\"例如：3\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"持续时长(毫秒)\",\"minimum\":0,\"default\":0,\"placeholder\":\"例如：0\"}},\"required\":[\"geometryId\",\"thresholdCount\"]}', '{\"rule\":{\"id\":\"count_threshold\",\"behaviorType\":\"count_threshold\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"thresholdCount\":{\"$valueFrom\":\"params.thresholdCount\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000009', 'BEHAVIOR_OCCUPANCY', '占用告警模板', '指定区域持续被占用超过阈值时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"temporal\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"占用时长(毫秒)\",\"minimum\":1,\"default\":5000,\"placeholder\":\"例如：5000\"}},\"required\":[\"geometryId\",\"thresholdMs\"]}', '{\"rule\":{\"id\":\"occupancy\",\"behaviorType\":\"occupancy\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000010', 'BEHAVIOR_DIRECTION_MOVE', '定向通行模板', '目标在指定区域内沿指定方向通行时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"direction\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"directionAngleDeg\":{\"type\":\"number\",\"title\":\"目标方向角(度)\",\"default\":0,\"placeholder\":\"例如：0\"},\"directionToleranceDeg\":{\"type\":\"number\",\"title\":\"方向容差(度)\",\"minimum\":1,\"maximum\":180,\"default\":30,\"placeholder\":\"例如：30\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"持续时长(毫秒)\",\"minimum\":0,\"default\":3000,\"placeholder\":\"例如：3000\"}},\"required\":[\"geometryId\",\"directionAngleDeg\"]}', '{\"rule\":{\"id\":\"direction_move\",\"behaviorType\":\"direction_move\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"directionAngleDeg\":{\"$valueFrom\":\"params.directionAngleDeg\"},\"directionToleranceDeg\":{\"$valueFrom\":\"params.directionToleranceDeg\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000011', 'BEHAVIOR_DIRECTION_REVERSE', '逆向通行模板', '目标在指定区域内沿禁止方向通行时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"direction\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"directionAngleDeg\":{\"type\":\"number\",\"title\":\"基准方向角(度)\",\"default\":0,\"placeholder\":\"例如：0\"},\"directionToleranceDeg\":{\"type\":\"number\",\"title\":\"方向容差(度)\",\"minimum\":1,\"maximum\":180,\"default\":30,\"placeholder\":\"例如：30\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"持续时长(毫秒)\",\"minimum\":0,\"default\":3000,\"placeholder\":\"例如：3000\"}},\"required\":[\"geometryId\",\"directionAngleDeg\"]}', '{\"rule\":{\"id\":\"direction_reverse\",\"behaviorType\":\"direction_reverse\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"directionAngleDeg\":{\"$valueFrom\":\"params.directionAngleDeg\"},\"directionToleranceDeg\":{\"$valueFrom\":\"params.directionToleranceDeg\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000012', 'BEHAVIOR_RELATION_NEAR', '目标接近模板', '主体目标与目标对象在指定区域内接近到距离阈值以内时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"relation\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"subjectObject\":{\"type\":\"string\",\"title\":\"主体对象\",\"placeholder\":\"例如：person\"},\"targetObject\":{\"type\":\"string\",\"title\":\"目标对象\",\"placeholder\":\"例如：person\"},\"distanceThresholdPx\":{\"type\":\"number\",\"title\":\"接近距离阈值(px)\",\"minimum\":1,\"default\":80,\"placeholder\":\"例如：80\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"持续时长(毫秒)\",\"minimum\":0,\"default\":3000,\"placeholder\":\"例如：3000\"}},\"required\":[\"geometryId\",\"subjectObject\",\"targetObject\",\"distanceThresholdPx\"]}', '{\"rule\":{\"id\":\"relation_near\",\"behaviorType\":\"relation_near\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"subjectObject\":{\"$valueFrom\":\"params.subjectObject\"},\"targetObject\":{\"$valueFrom\":\"params.targetObject\"},\"distanceThresholdPx\":{\"$valueFrom\":\"params.distanceThresholdPx\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');
INSERT INTO `deployment_business_event_template` VALUES ('be000000000000000000000000000013', 'BEHAVIOR_RELATION_APART', '目标远离模板', '主体目标与目标对象在指定区域内距离大于阈值并持续一段时间时触发。', 'SYSTEM', NULL, NULL, 'ACTIVE', 1, '[\"builtin\",\"behavior\",\"region\",\"relation\"]', '{\"type\":\"object\",\"properties\":{\"geometryId\":{\"type\":\"string\",\"title\":\"区域ID\",\"description\":\"填写 geometryConfig 中的区域 ID\",\"placeholder\":\"例如：region_1\"},\"subjectObject\":{\"type\":\"string\",\"title\":\"主体对象\",\"placeholder\":\"例如：person\"},\"targetObject\":{\"type\":\"string\",\"title\":\"目标对象\",\"placeholder\":\"例如：person\"},\"distanceThresholdPx\":{\"type\":\"number\",\"title\":\"远离距离阈值(px)\",\"minimum\":1,\"default\":80,\"placeholder\":\"例如：80\"},\"thresholdMs\":{\"type\":\"integer\",\"title\":\"持续时长(毫秒)\",\"minimum\":0,\"default\":3000,\"placeholder\":\"例如：3000\"}},\"required\":[\"geometryId\",\"subjectObject\",\"targetObject\",\"distanceThresholdPx\"]}', '{\"rule\":{\"id\":\"relation_apart\",\"behaviorType\":\"relation_apart\",\"geometryType\":\"region\",\"geometryId\":{\"$valueFrom\":\"params.geometryId\"},\"subjectObject\":{\"$valueFrom\":\"params.subjectObject\"},\"targetObject\":{\"$valueFrom\":\"params.targetObject\"},\"distanceThresholdPx\":{\"$valueFrom\":\"params.distanceThresholdPx\"},\"thresholdMs\":{\"$valueFrom\":\"params.thresholdMs\"}}}', '{}', 'system', 'system', '2026-04-15 09:28:58', '2026-04-15 09:32:54');

-- ----------------------------
-- Table structure for deployment_task
-- ----------------------------
DROP TABLE IF EXISTS `deployment_task`;
CREATE TABLE `deployment_task`  (
  `deployment_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `task_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `device_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `algorithm_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `algorithm_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `target_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `push_enabled` tinyint(1) NULL DEFAULT NULL,
  `frontend_overlay_enabled` tinyint(1) NULL DEFAULT 1 COMMENT '不推流时是否由前端画框',
  `record_engine` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `alarm_interval_sec` int(11) NULL DEFAULT NULL,
  `dwell_enabled` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否启用停留规则',
  `dwell_threshold_ms` bigint(20) NOT NULL DEFAULT 5000 COMMENT '停留判定阈值毫秒',
  `ai_review_enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否启用AI复核',
  `ai_review_prompt` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT 'AI复核提示词',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `polygon_points` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `geometry_config` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '统一几何配置JSON，包含regions/lines',
  `stream_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `push_stream_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `algorithm_stream_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '算法播放地址(ws-flv)',
  `status` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `start_time` datetime NULL DEFAULT NULL,
  `stop_time` datetime NULL DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`deployment_id`) USING BTREE,
  INDEX `idx_deployment_task_status`(`status`) USING BTREE,
  INDEX `idx_deployment_task_task_name`(`task_name`) USING BTREE,
  INDEX `idx_deployment_task_device_id`(`device_id`) USING BTREE,
  INDEX `idx_deployment_task_update_time`(`update_time`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of deployment_task
-- ----------------------------

-- ----------------------------
-- Table structure for deployment_task_algorithm
-- ----------------------------
DROP TABLE IF EXISTS `deployment_task_algorithm`;
CREATE TABLE `deployment_task_algorithm`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `deployment_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `algorithm_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `algorithm_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `detect_fps` decimal(6,2) DEFAULT NULL COMMENT '检测帧率',
  `score_threshold` decimal(4,3) DEFAULT NULL COMMENT '置信度阈值',
  `nms_threshold` decimal(4,3) DEFAULT NULL COMMENT 'NMS阈值',
  `target_codes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_deployment_task_algorithm_deployment_id`(`deployment_id`) USING BTREE,
  INDEX `idx_deployment_task_algorithm_code`(`algorithm_code`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 221 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of deployment_task_algorithm
-- ----------------------------

-- ----------------------------
-- Table structure for deployment_task_event
-- ----------------------------
DROP TABLE IF EXISTS `deployment_task_event`;
CREATE TABLE `deployment_task_event`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `deployment_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `event_key` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `template_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `template_version` int(11) NULL DEFAULT NULL,
  `event_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `parameter_values_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `compiled_rule_ids_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `compiled_rule_snapshot_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_deployment_task_event_deployment_id`(`deployment_id`) USING BTREE,
  INDEX `idx_deployment_task_event_template_id`(`template_id`) USING BTREE,
  INDEX `idx_deployment_task_event_event_key`(`event_key`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of deployment_task_event
-- ----------------------------

-- ----------------------------
-- Table structure for device
-- ----------------------------
DROP TABLE IF EXISTS `device`;
CREATE TABLE `device`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `device_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '设备ID',
  `device_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '设备名称',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '0' COMMENT '状态:0新建,1在线,2离线,3停用',
  `urls` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '设备流地址',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_device_device_id`(`device_id`) USING BTREE,
  INDEX `idx_device_status`(`status`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 123 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of device
-- ----------------------------

-- ----------------------------
-- Table structure for gen_table
-- ----------------------------
DROP TABLE IF EXISTS `gen_table`;
CREATE TABLE `gen_table`  (
  `table_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '编号',
  `table_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '表名称',
  `table_comment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '表描述',
  `sub_table_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '关联子表的表名',
  `sub_table_fk_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '子表关联的外键名',
  `class_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '实体类名称',
  `tpl_category` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT 'crud' COMMENT '使用的模板（crud单表操作 tree树表操作）',
  `tpl_web_type` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '前端模板类型（element-ui模版 element-plus模版）',
  `package_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '生成包路径',
  `module_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '生成模块名',
  `business_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '生成业务名',
  `function_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '生成功能名',
  `function_author` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '生成功能作者',
  `gen_type` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '生成代码方式（0zip压缩包 1自定义路径）',
  `gen_path` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '/' COMMENT '生成路径（不填默认项目路径）',
  `options` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '其它生成选项',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`table_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '代码生成业务表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of gen_table
-- ----------------------------

-- ----------------------------
-- Table structure for gen_table_column
-- ----------------------------
DROP TABLE IF EXISTS `gen_table_column`;
CREATE TABLE `gen_table_column`  (
  `column_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '编号',
  `table_id` bigint(20) NULL DEFAULT NULL COMMENT '归属表编号',
  `column_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '列名称',
  `column_comment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '列描述',
  `column_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '列类型',
  `java_type` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'JAVA类型',
  `java_field` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'JAVA字段名',
  `is_pk` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '是否主键（1是）',
  `is_increment` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '是否自增（1是）',
  `is_required` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '是否必填（1是）',
  `is_insert` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '是否为插入字段（1是）',
  `is_edit` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '是否编辑字段（1是）',
  `is_list` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '是否列表字段（1是）',
  `is_query` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '是否查询字段（1是）',
  `query_type` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT 'EQ' COMMENT '查询方式（等于、不等于、大于、小于、范围）',
  `html_type` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '显示类型（文本框、文本域、下拉框、复选框、单选框、日期控件）',
  `dict_type` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '字典类型',
  `sort` int(11) NULL DEFAULT NULL COMMENT '排序',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`column_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '代码生成业务表字段' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of gen_table_column
-- ----------------------------

-- ----------------------------
-- Table structure for h_alarm_review_result
-- ----------------------------
DROP TABLE IF EXISTS `h_alarm_review_result`;
CREATE TABLE `h_alarm_review_result`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_id` bigint(20) NOT NULL COMMENT '任务ID',
  `w_id` int(11) NOT NULL COMMENT '告警主键',
  `decision` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '复核结论',
  `confidence` decimal(10, 4) NULL DEFAULT NULL COMMENT '结论置信度',
  `false_positive_score` decimal(10, 4) NULL DEFAULT NULL COMMENT '误报分数',
  `summary` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '事件摘要',
  `reason` varchar(4000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '复核原因',
  `raw_response_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '原始响应',
  `create_time` datetime NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_alarm_review_result_task`(`task_id`) USING BTREE,
  INDEX `idx_alarm_review_result_wid`(`w_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 45 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = 'AI复核结果' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_alarm_review_result
-- ----------------------------

-- ----------------------------
-- Table structure for h_alarm_review_task
-- ----------------------------
DROP TABLE IF EXISTS `h_alarm_review_task`;
CREATE TABLE `h_alarm_review_task`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `w_id` int(11) NOT NULL COMMENT '告警主键',
  `review_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'image' COMMENT '复核类型',
  `media_url` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '待复核媒资URL',
  `prompt_snapshot` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '复核提示词快照',
  `server_id` bigint(20) NULL DEFAULT NULL COMMENT '执行节点ID',
  `status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'PENDING' COMMENT '任务状态',
  `retry_count` int(11) NOT NULL DEFAULT 0 COMMENT '已重试次数',
  `max_retries` int(11) NOT NULL DEFAULT 3 COMMENT '最大重试次数',
  `next_retry_time` datetime NULL DEFAULT NULL COMMENT '下次重试时间',
  `started_time` datetime NULL DEFAULT NULL COMMENT '开始时间',
  `finished_time` datetime NULL DEFAULT NULL COMMENT '结束时间',
  `error_message` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '错误信息',
  `create_time` datetime NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_alarm_review_task_wid`(`w_id`) USING BTREE,
  INDEX `idx_alarm_review_task_status`(`status`) USING BTREE,
  INDEX `idx_alarm_review_task_next_retry`(`next_retry_time`) USING BTREE,
  INDEX `idx_alarm_review_task_create_time`(`create_time`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 112 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = 'AI复核任务' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_alarm_review_task
-- ----------------------------

-- ----------------------------
-- Table structure for h_binding
-- ----------------------------
DROP TABLE IF EXISTS `h_binding`;
CREATE TABLE `h_binding`  (
  `b_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '绑定表ID',
  `device_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '摄像头名称',
  `device_index` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '通道编码',
  `team_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '队组名称',
  PRIMARY KEY (`b_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 51 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_binding
-- ----------------------------


-- ----------------------------
-- Table structure for h_device
-- ----------------------------
DROP TABLE IF EXISTS `h_device`;
CREATE TABLE `h_device`  (
  `ape_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '设备国标编码',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '设备名称',
  `resource_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '资源类型',
  `sub_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '资源子类型枚举',
  `ip_addr` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'ip地址\r',
  `port` int(11) NULL DEFAULT NULL COMMENT '端口',
  `org_index` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组织id\r',
  `org_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组织名称\r',
  `org_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '机构代码\r',
  `place_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '行政区域码',
  `place` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '安装位置\r',
  `is_online` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '在线状态\r\n(0 登录中\r\n1 在线/启用\r\n2 离线/停用\r\n9 其他/异常)',
  `producer` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '设备厂商',
  `producer_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '厂商名称',
  `parent_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组织父ID',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '修改时间',
  `stream_source_type` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'DIRECT' COMMENT '流来源类型: PLATFORM/DIRECT',
  `direct_source_url` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'DIRECT直连地址',
  `monitor_status` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'STOPPED' COMMENT '监控状态',
  `zlm_server_id` bigint(20) NOT NULL DEFAULT 1,
  `sva_server_id` bigint(20) NOT NULL DEFAULT 1,
  `play_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'Web预览播放地址(ws-flv)',
  `zlm_proxy_key` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'ZLM代理Key(delStreamProxy使用)',
  INDEX `idx_h_device_zlm_server_id`(`zlm_server_id`) USING BTREE,
  INDEX `idx_h_device_sva_server_id`(`sva_server_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_device
-- ----------------------------

-- ----------------------------
-- Table structure for h_dist
-- ----------------------------
DROP TABLE IF EXISTS `h_dist`;
CREATE TABLE `h_dist`  (
  `d_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '打卡id',
  `person_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '打卡人',
  `pass_time` datetime NULL DEFAULT NULL COMMENT '打卡时间',
  `person_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '打卡人编号',
  `index_path_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '打卡人组织',
  `pass_time_exc` date NULL DEFAULT NULL COMMENT '打卡日期',
  `pass_time_ms` time NULL DEFAULT NULL COMMENT '打卡时间',
  `site_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '打卡地点',
  `attendance_identification` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '证据图相对路径',
  `attendance_identification_absolute` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '证据图绝对路径',
  `type` tinyint(1) NULL DEFAULT NULL COMMENT '1:为入井口 2:巡检点',
  PRIMARY KEY (`d_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 936 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_dist
-- ----------------------------


-- ----------------------------
-- Table structure for h_handle
-- ----------------------------
DROP TABLE IF EXISTS `h_handle`;
CREATE TABLE `h_handle`  (
  `h_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '处置ID',
  `w_id` int(11) NOT NULL COMMENT '报警信息ID',
  `h_title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '处置标题',
  `h_remark` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '处置意见',
  `h_time` datetime NULL DEFAULT NULL COMMENT '责令整改期限',
  `h_create_time` datetime NOT NULL COMMENT '添加时间',
  `h_org_index` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '责令整改组织编号',
  `h_org_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '责令整改组织',
  PRIMARY KEY (`h_id`, `w_id`) USING BTREE,
  INDEX `h_waring`(`w_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 14273 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_handle
-- ----------------------------


-- ----------------------------
-- Table structure for h_opc
-- ----------------------------
DROP TABLE IF EXISTS `h_opc`;
CREATE TABLE `h_opc`  (
  `o_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
  `o_node` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '点位名称',
  `device_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '摄像头名称',
  `device_index` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '摄像头通道编码',
  `type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '类型1：皮带 2：刮板机\r\n',
  PRIMARY KEY (`o_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_opc
-- ----------------------------


-- ----------------------------
-- Table structure for h_person
-- ----------------------------
DROP TABLE IF EXISTS `h_person`;
CREATE TABLE `h_person`  (
  `p_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '人数统计',
  `statistic_time` bigint(20) NULL DEFAULT NULL COMMENT '统计时间',
  `statistic_in_person_count` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '进入人数',
  `statistic_out_person_count` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '离开人数',
  `statistic_person_count` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '在场人数',
  `area_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '区域名称',
  PRIMARY KEY (`p_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 354 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_person
-- ----------------------------


-- ----------------------------
-- Table structure for h_screen_wall_stream
-- ----------------------------
DROP TABLE IF EXISTS `h_screen_wall_stream`;
CREATE TABLE `h_screen_wall_stream`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `wall_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '监控墙编码',
  `source_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '来源类型: realtime/task',
  `source_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '来源ID(如任务ID)',
  `device_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '设备ID',
  `play_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '最终播放地址',
  `title` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '展示标题',
  `slot_index` int(11) NULL DEFAULT NULL COMMENT '墙位索引',
  `enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否启用: 1启用 0禁用',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_h_screen_wall_stream_wall_device`(`wall_code`, `device_id`) USING BTREE,
  INDEX `idx_h_screen_wall_stream_wall_enabled_slot`(`wall_code`, `enabled`, `slot_index`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 30 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '监控墙流配置' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_screen_wall_stream
-- ----------------------------

-- ----------------------------
-- Table structure for h_waring
-- ----------------------------
DROP TABLE IF EXISTS `h_waring`;
CREATE TABLE `h_waring`  (
  `w_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '告警信息主键',
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警事件id',
  `alarm_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警类型编码',
  `alarm_type_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警类型名称',
  `alarm_level` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警等级',
  `alarm_level_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警等级名称',
  `device_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警设备id',
  `device_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警设备名称',
  `org_index` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组织id',
  `org_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组织名称',
  `longitude` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警经度',
  `latitude` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '告警维度',
  `picture_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '抓拍图片相对路径',
  `picture_absolute_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '抓拍图片绝对路径',
  `video_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA回写视频相对路径',
  `video_absolute_url` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA回写视频绝对路径',
  `is_handle` tinyint(1) UNSIGNED ZEROFILL NOT NULL COMMENT '是否整改(处理) 0，未处理  1，处理',
  `alarm_time` datetime NULL DEFAULT NULL COMMENT '告警时间',
  `end_time` datetime NULL DEFAULT NULL COMMENT '事件结束时间',
  `duration_ms` bigint(20) NULL DEFAULT NULL COMMENT '事件持续毫秒',
  `sva_media_status` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA素材回写状态',
  `sva_media_error` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA素材回写错误信息',
  `is_enable` tinyint(4) NULL DEFAULT 1 COMMENT '是否显示 0不显示 1显示',
  `is_daping` smallint(1) UNSIGNED ZEROFILL NULL DEFAULT 0 COMMENT '是否显示大屏 0不显示 1显示',
  `team` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '所属队组',
  `ip` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'ip',
  `control_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '布控任务编码',
  `sva_event_key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA事件键',
  `sva_event_state` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA事件状态',
  `sva_behavior_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA行为类型',
  `sva_rule_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA规则ID',
  `sva_business_event_id` bigint(20) NULL DEFAULT NULL COMMENT '业务事件实例ID',
  `sva_business_event_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '业务事件名称',
  `sva_business_template_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '业务事件模板ID',
  `sva_business_template_version` int(11) NULL DEFAULT NULL COMMENT '业务事件模板版本',
  `sva_region_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA区域ID',
  `sva_region_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA区域名称',
  `sva_line_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA线段ID',
  `sva_line_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA线段名称',
  `sva_crossing_direction` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT 'SVA跨线方向',
  `sva_track_id` int(11) NULL DEFAULT NULL COMMENT 'SVA轨迹ID',
  PRIMARY KEY (`w_id`) USING BTREE,
  INDEX `idx_h_waring_control_code`(`control_code`) USING BTREE,
  INDEX `idx_h_waring_sva_event_key`(`sva_event_key`) USING BTREE,
  INDEX `idx_h_waring_sva_rule_id`(`sva_rule_id`) USING BTREE,
  INDEX `idx_h_waring_sva_region_id`(`sva_region_id`) USING BTREE,
  INDEX `idx_h_waring_sva_line_id`(`sva_line_id`) USING BTREE,
  INDEX `idx_h_waring_sva_media_status`(`sva_media_status`) USING BTREE,
  INDEX `idx_h_waring_sva_business_event_id`(`sva_business_event_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 741 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_waring
-- ----------------------------

-- ----------------------------
-- Table structure for h_waring_type
-- ----------------------------
DROP TABLE IF EXISTS `h_waring_type`;
CREATE TABLE `h_waring_type`  (
  `t_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '报警类型ID',
  `device_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '通道编码（H3平台获取）',
  `device_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '通道名称（H3平台获取）',
  `alarm_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '报警类型唯一标识（H3平台获取）',
  `alarm_type_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '报警类型（宇祺/甲方定义）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '添加时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '修改时间',
  `create_user` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '添加人',
  `update_user` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '修改人',
  `alarm_level` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '报警等级',
  `alarm_level_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '报警等级名称',
  `is_handle` tinyint(4) NOT NULL COMMENT '是否使用 0使用 1不使用',
  `org_index` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组织编码',
  `org_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组织名称',
  PRIMARY KEY (`t_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 41 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of h_waring_type
-- ----------------------------

-- ----------------------------
-- Table structure for license_state
-- ----------------------------
DROP TABLE IF EXISTS `license_state`;
CREATE TABLE `license_state`  (
  `id` bigint(20) NOT NULL,
  `license_content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `license_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `verify_status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `verify_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `expire_at` datetime NULL DEFAULT NULL,
  `invalid_since` datetime NULL DEFAULT NULL,
  `grace_deadline` datetime NULL DEFAULT NULL,
  `last_verify_at` datetime NULL DEFAULT NULL,
  `last_stop_all_at` datetime NULL DEFAULT NULL,
  `create_time` datetime NULL DEFAULT NULL,
  `update_time` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of license_state
-- ----------------------------
INSERT INTO `license_state` VALUES (1, NULL, NULL, 'invalid_grace', '未配置授权内容', NULL, '2026-05-20 10:48:20', '2026-05-20 11:48:20', '2026-05-20 10:48:20', NULL, '2026-05-20 10:48:20', '2026-05-20 10:48:20');

-- ----------------------------
-- Table structure for stream_session
-- ----------------------------
DROP TABLE IF EXISTS `stream_session`;
CREATE TABLE `stream_session`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `stream_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '转发会话ID',
  `device_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '设备ID',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0' COMMENT '状态:0新建,1运行中,2已停止,3失败',
  `urls` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '会话URL集合(JSON)',
  `algorithm_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '算法编码',
  `algorithm_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '算法名称',
  `start_time` datetime NULL DEFAULT NULL COMMENT '启动时间',
  `stop_time` datetime NULL DEFAULT NULL COMMENT '停止时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_stream_session_stream_id`(`stream_id`) USING BTREE,
  INDEX `idx_stream_session_device_id`(`device_id`) USING BTREE,
  INDEX `idx_stream_session_status`(`status`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '转发会话表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of stream_session
-- ----------------------------

-- ----------------------------
-- Table structure for sva_server
-- ----------------------------
DROP TABLE IF EXISTS `sva_server`;
CREATE TABLE `sva_server`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `app` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `host` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `analyzer_port` int(11) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_sva_enabled`(`enabled`) USING BTREE,
  INDEX `idx_sva_update_time`(`update_time`) USING BTREE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`enabled` in (0,1))
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sva_server
-- ----------------------------
INSERT INTO `sva_server` VALUES (1, 'default-sva', 'analyzer', '127.0.0.1', 9993, 1, 'default config', '2026-03-20 20:40:08', '2026-04-09 12:01:45');

-- ----------------------------
-- Table structure for sys_config
-- ----------------------------
DROP TABLE IF EXISTS `sys_config`;
CREATE TABLE `sys_config`  (
  `config_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '参数主键',
  `config_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '参数名称',
  `config_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '参数键名',
  `config_value` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '参数键值',
  `config_type` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT 'N' COMMENT '系统内置（Y是 N否）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`config_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '参数配置表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_config
-- ----------------------------
INSERT INTO `sys_config` VALUES (1, '主框架页-默认皮肤样式名称', 'sys.index.skinName', 'skin-blue', 'Y', 'admin', '2023-12-27 10:17:11', '', NULL, '蓝色 skin-blue、绿色 skin-green、紫色 skin-purple、红色 skin-red、黄色 skin-yellow');
INSERT INTO `sys_config` VALUES (2, '用户管理-账号初始密码', 'sys.user.initPassword', '123456', 'Y', 'admin', '2023-12-27 10:17:11', '', NULL, '初始化密码 123456');
INSERT INTO `sys_config` VALUES (3, '主框架页-侧边栏主题', 'sys.index.sideTheme', 'theme-dark', 'Y', 'admin', '2023-12-27 10:17:11', '', NULL, '深色主题theme-dark，浅色主题theme-light');
INSERT INTO `sys_config` VALUES (4, '账号自助-验证码开关', 'sys.account.captchaEnabled', 'false', 'Y', 'admin', '2023-12-27 10:17:11', '', '2026-03-18 11:25:00', '是否开启验证码功能（true开启，false关闭）');
INSERT INTO `sys_config` VALUES (5, '账号自助-是否开启用户注册功能', 'sys.account.registerUser', 'false', 'Y', 'admin', '2023-12-27 10:17:11', '', NULL, '是否开启注册用户功能（true开启，false关闭）');
INSERT INTO `sys_config` VALUES (6, '用户登录-黑名单列表', 'sys.login.blackIPList', '', 'Y', 'admin', '2023-12-27 10:17:11', '', NULL, '设置登录IP黑名单限制，多个匹配项以;分隔，支持匹配（*通配、网段）');
INSERT INTO `sys_config` VALUES (7, 'AI复核总开关', 'ai.review.enabled', 'true', 'N', 'admin', '2026-04-05 17:19:22', '', NULL, '是否启用AI告警复核（true开启，false关闭）');
INSERT INTO `sys_config` VALUES (8, '前端画框延迟(ms)', 'sva.overlay.delay.ms', '400', 'N', 'admin', '2026-04-17 21:02:45', 'admin', '2026-04-18 11:24:57', '控制视频墙与布控详情页前端画框相对视频的全局延迟，单位毫秒。');

-- ----------------------------
-- Table structure for sys_dept
-- ----------------------------
DROP TABLE IF EXISTS `sys_dept`;
CREATE TABLE `sys_dept`  (
  `dept_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '部门id',
  `parent_id` bigint(20) NULL DEFAULT 0 COMMENT '父部门id',
  `ancestors` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '祖级列表',
  `dept_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '组织名称',
  `order_num` int(11) NULL DEFAULT 0 COMMENT '显示顺序',
  `org_index` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组织编码',
  `leader` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '负责人',
  `phone` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '联系电话',
  `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '邮箱',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '部门状态（0正常 1停用）',
  `del_flag` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '删除标志（0代表存在 2代表删除）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`dept_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 217 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '部门表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_dept
-- ----------------------------
INSERT INTO `sys_dept` VALUES (100, 0, '0', '总公司', 0, '10', '', '', '', '0', '0', 'admin', '2023-12-27 10:17:11', 'admin', '2026-05-20 10:37:41');

-- ----------------------------
-- Table structure for sys_dict_data
-- ----------------------------
DROP TABLE IF EXISTS `sys_dict_data`;
CREATE TABLE `sys_dict_data`  (
  `dict_code` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '字典编码',
  `dict_sort` int(11) NULL DEFAULT 0 COMMENT '字典排序',
  `dict_label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '字典标签',
  `dict_value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '字典键值',
  `dict_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '字典类型',
  `css_class` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '样式属性（其他样式扩展）',
  `list_class` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '表格回显样式',
  `is_default` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT 'N' COMMENT '是否默认（Y是 N否）',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '状态（0正常 1停用）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`dict_code`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 30 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '字典数据表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_dict_data
-- ----------------------------
INSERT INTO `sys_dict_data` VALUES (1, 1, '男', '0', 'sys_user_sex', '', '', 'Y', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '性别男');
INSERT INTO `sys_dict_data` VALUES (2, 2, '女', '1', 'sys_user_sex', '', '', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '性别女');
INSERT INTO `sys_dict_data` VALUES (3, 3, '未知', '2', 'sys_user_sex', '', '', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '性别未知');
INSERT INTO `sys_dict_data` VALUES (4, 1, '显示', '0', 'sys_show_hide', '', 'primary', 'Y', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '显示菜单');
INSERT INTO `sys_dict_data` VALUES (5, 2, '隐藏', '1', 'sys_show_hide', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '隐藏菜单');
INSERT INTO `sys_dict_data` VALUES (6, 1, '正常', '0', 'sys_normal_disable', '', 'primary', 'Y', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '正常状态');
INSERT INTO `sys_dict_data` VALUES (7, 2, '停用', '1', 'sys_normal_disable', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '停用状态');
INSERT INTO `sys_dict_data` VALUES (8, 1, '正常', '0', 'sys_job_status', '', 'primary', 'Y', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '正常状态');
INSERT INTO `sys_dict_data` VALUES (9, 2, '暂停', '1', 'sys_job_status', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '停用状态');
INSERT INTO `sys_dict_data` VALUES (10, 1, '默认', 'DEFAULT', 'sys_job_group', '', '', 'Y', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '默认分组');
INSERT INTO `sys_dict_data` VALUES (11, 2, '系统', 'SYSTEM', 'sys_job_group', '', '', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '系统分组');
INSERT INTO `sys_dict_data` VALUES (12, 1, '是', 'Y', 'sys_yes_no', '', 'primary', 'Y', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '系统默认是');
INSERT INTO `sys_dict_data` VALUES (13, 2, '否', 'N', 'sys_yes_no', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '系统默认否');
INSERT INTO `sys_dict_data` VALUES (14, 1, '通知', '1', 'sys_notice_type', '', 'warning', 'Y', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '通知');
INSERT INTO `sys_dict_data` VALUES (15, 2, '公告', '2', 'sys_notice_type', '', 'success', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '公告');
INSERT INTO `sys_dict_data` VALUES (16, 1, '正常', '0', 'sys_notice_status', '', 'primary', 'Y', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '正常状态');
INSERT INTO `sys_dict_data` VALUES (17, 2, '关闭', '1', 'sys_notice_status', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '关闭状态');
INSERT INTO `sys_dict_data` VALUES (18, 99, '其他', '0', 'sys_oper_type', '', 'info', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '其他操作');
INSERT INTO `sys_dict_data` VALUES (19, 1, '新增', '1', 'sys_oper_type', '', 'info', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '新增操作');
INSERT INTO `sys_dict_data` VALUES (20, 2, '修改', '2', 'sys_oper_type', '', 'info', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '修改操作');
INSERT INTO `sys_dict_data` VALUES (21, 3, '删除', '3', 'sys_oper_type', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '删除操作');
INSERT INTO `sys_dict_data` VALUES (22, 4, '授权', '4', 'sys_oper_type', '', 'primary', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '授权操作');
INSERT INTO `sys_dict_data` VALUES (23, 5, '导出', '5', 'sys_oper_type', '', 'warning', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '导出操作');
INSERT INTO `sys_dict_data` VALUES (24, 6, '导入', '6', 'sys_oper_type', '', 'warning', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '导入操作');
INSERT INTO `sys_dict_data` VALUES (25, 7, '强退', '7', 'sys_oper_type', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '强退操作');
INSERT INTO `sys_dict_data` VALUES (26, 8, '生成代码', '8', 'sys_oper_type', '', 'warning', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '生成操作');
INSERT INTO `sys_dict_data` VALUES (27, 9, '清空数据', '9', 'sys_oper_type', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '清空操作');
INSERT INTO `sys_dict_data` VALUES (28, 1, '成功', '0', 'sys_common_status', '', 'primary', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '正常状态');
INSERT INTO `sys_dict_data` VALUES (29, 2, '失败', '1', 'sys_common_status', '', 'danger', 'N', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '停用状态');

-- ----------------------------
-- Table structure for sys_dict_type
-- ----------------------------
DROP TABLE IF EXISTS `sys_dict_type`;
CREATE TABLE `sys_dict_type`  (
  `dict_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '字典主键',
  `dict_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '字典名称',
  `dict_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '字典类型',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '状态（0正常 1停用）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`dict_id`) USING BTREE,
  UNIQUE INDEX `dict_type`(`dict_type`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '字典类型表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_dict_type
-- ----------------------------
INSERT INTO `sys_dict_type` VALUES (1, '用户性别', 'sys_user_sex', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '用户性别列表');
INSERT INTO `sys_dict_type` VALUES (2, '菜单状态', 'sys_show_hide', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '菜单状态列表');
INSERT INTO `sys_dict_type` VALUES (3, '系统开关', 'sys_normal_disable', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '系统开关列表');
INSERT INTO `sys_dict_type` VALUES (4, '任务状态', 'sys_job_status', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '任务状态列表');
INSERT INTO `sys_dict_type` VALUES (5, '任务分组', 'sys_job_group', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '任务分组列表');
INSERT INTO `sys_dict_type` VALUES (6, '系统是否', 'sys_yes_no', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '系统是否列表');
INSERT INTO `sys_dict_type` VALUES (7, '通知类型', 'sys_notice_type', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '通知类型列表');
INSERT INTO `sys_dict_type` VALUES (8, '通知状态', 'sys_notice_status', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '通知状态列表');
INSERT INTO `sys_dict_type` VALUES (9, '操作类型', 'sys_oper_type', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '操作类型列表');
INSERT INTO `sys_dict_type` VALUES (10, '系统状态', 'sys_common_status', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '登录状态列表');

-- ----------------------------
-- Table structure for sys_job
-- ----------------------------
DROP TABLE IF EXISTS `sys_job`;
CREATE TABLE `sys_job`  (
  `job_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '任务ID',
  `job_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '' COMMENT '任务名称',
  `job_group` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'DEFAULT' COMMENT '任务组名',
  `invoke_target` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '调用目标字符串',
  `cron_expression` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT 'cron执行表达式',
  `misfire_policy` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '3' COMMENT '计划执行错误策略（1立即执行 2执行一次 3放弃执行）',
  `concurrent` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '1' COMMENT '是否并发执行（0允许 1禁止）',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '状态（0正常 1暂停）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '备注信息',
  PRIMARY KEY (`job_id`, `job_name`, `job_group`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '定时任务调度表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_job
-- ----------------------------
INSERT INTO `sys_job` VALUES (1, '系统默认（无参）', 'DEFAULT', 'ryTask.ryNoParams', '0/10 * * * * ?', '3', '1', '1', 'admin', '2023-12-27 10:17:11', '', NULL, '');
INSERT INTO `sys_job` VALUES (2, '系统默认（有参）', 'DEFAULT', 'ryTask.ryParams(\'ry\')', '0/15 * * * * ?', '3', '1', '1', 'admin', '2023-12-27 10:17:11', '', NULL, '');
INSERT INTO `sys_job` VALUES (3, '系统默认（多参）', 'DEFAULT', 'ryTask.ryMultipleParams(\'ry\', true, 2000L, 316.50D, 100)', '0/20 * * * * ?', '3', '1', '1', 'admin', '2023-12-27 10:17:11', '', NULL, '');

-- ----------------------------
-- Table structure for sys_job_log
-- ----------------------------
DROP TABLE IF EXISTS `sys_job_log`;
CREATE TABLE `sys_job_log`  (
  `job_log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '任务日志ID',
  `job_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '任务名称',
  `job_group` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '任务组名',
  `invoke_target` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '调用目标字符串',
  `job_message` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '日志信息',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '执行状态（0正常 1失败）',
  `exception_info` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '异常信息',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`job_log_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '定时任务调度日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_job_log
-- ----------------------------

-- ----------------------------
-- Table structure for sys_logininfor
-- ----------------------------
DROP TABLE IF EXISTS `sys_logininfor`;
CREATE TABLE `sys_logininfor`  (
  `info_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '访问ID',
  `user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '用户账号',
  `ipaddr` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '登录IP地址',
  `login_location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '登录地点',
  `browser` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '浏览器类型',
  `os` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '操作系统',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '登录状态（0成功 1失败）',
  `msg` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '提示消息',
  `login_time` datetime NULL DEFAULT NULL COMMENT '访问时间',
  PRIMARY KEY (`info_id`) USING BTREE,
  INDEX `idx_sys_logininfor_s`(`status`) USING BTREE,
  INDEX `idx_sys_logininfor_lt`(`login_time`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1612 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '系统访问记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_logininfor
-- ----------------------------

-- ----------------------------
-- Table structure for sys_menu
-- ----------------------------
DROP TABLE IF EXISTS `sys_menu`;
CREATE TABLE `sys_menu`  (
  `menu_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '菜单ID',
  `menu_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '菜单名称',
  `parent_id` bigint(20) NULL DEFAULT 0 COMMENT '父菜单ID',
  `order_num` int(11) NULL DEFAULT 0 COMMENT '显示顺序',
  `path` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '路由地址',
  `component` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '组件路径',
  `query` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '路由参数',
  `is_frame` int(11) NULL DEFAULT 1 COMMENT '是否为外链（0是 1否）',
  `is_cache` int(11) NULL DEFAULT 0 COMMENT '是否缓存（0缓存 1不缓存）',
  `menu_type` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '菜单类型（M目录 C菜单 F按钮）',
  `visible` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '菜单状态（0显示 1隐藏）',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '菜单状态（0正常 1停用）',
  `perms` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '权限标识',
  `icon` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '#' COMMENT '菜单图标',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '备注',
  `route_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '路由名称',
  PRIMARY KEY (`menu_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2040 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '菜单权限表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_menu
-- ----------------------------
INSERT INTO `sys_menu` VALUES (1, '系统管理', 0, 1, 'system', NULL, '', 1, 0, 'M', '0', '0', '', 'system', 'admin', '2023-12-27 10:17:11', '', NULL, '系统管理目录', '');
INSERT INTO `sys_menu` VALUES (2, '系统监控', 0, 2, 'monitor', NULL, '', 1, 0, 'M', '0', '0', '', 'monitor', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:40:01', '系统监控目录', '');
INSERT INTO `sys_menu` VALUES (3, '系统工具', 0, 3, 'tool', NULL, '', 1, 0, 'M', '0', '0', '', 'tool', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:39', '系统工具目录', '');
INSERT INTO `sys_menu` VALUES (100, '用户管理', 1, 1, 'user', 'system/user/index', '', 1, 0, 'C', '0', '0', 'system:user:list', 'user', 'admin', '2023-12-27 10:17:11', '', NULL, '用户管理菜单', '');
INSERT INTO `sys_menu` VALUES (101, '角色管理', 1, 2, 'role', 'system/role/index', '', 1, 0, 'C', '0', '0', 'system:role:list', 'peoples', 'admin', '2023-12-27 10:17:11', '', NULL, '角色管理菜单', '');
INSERT INTO `sys_menu` VALUES (102, '菜单管理', 1, 3, 'menu', 'system/menu/index', '', 1, 0, 'C', '0', '0', 'system:menu:list', 'tree-table', 'admin', '2023-12-27 10:17:11', '', NULL, '菜单管理菜单', '');
INSERT INTO `sys_menu` VALUES (103, '组织管理', 1, 4, 'dept', 'system/dept/index', '', 1, 0, 'C', '0', '0', 'system:dept:list', 'tree', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 10:39:52', '部门管理菜单', '');
INSERT INTO `sys_menu` VALUES (104, '岗位管理', 1, 5, 'post', 'system/post/index', '', 1, 0, 'C', '0', '1', 'system:post:list', 'post', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 11:17:46', '岗位管理菜单', '');
INSERT INTO `sys_menu` VALUES (105, '字典管理', 1, 6, 'dict', 'system/dict/index', '', 1, 0, 'C', '0', '1', 'system:dict:list', 'dict', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 10:42:41', '字典管理菜单', '');
INSERT INTO `sys_menu` VALUES (106, '参数设置', 1, 7, 'config', 'system/config/index', '', 1, 0, 'C', '0', '1', 'system:config:list', 'edit', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 10:42:46', '参数设置菜单', '');
INSERT INTO `sys_menu` VALUES (107, '通知公告', 1, 8, 'notice', 'system/notice/index', '', 1, 0, 'C', '0', '1', 'system:notice:list', 'message', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 10:42:52', '通知公告菜单', '');
INSERT INTO `sys_menu` VALUES (108, '日志管理', 1, 9, 'log', '', '', 1, 0, 'M', '0', '1', '', 'log', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 11:15:53', '日志管理菜单', '');
INSERT INTO `sys_menu` VALUES (109, '在线用户', 2, 1, 'online', 'monitor/online/index', '', 1, 0, 'C', '0', '0', 'monitor:online:list', 'online', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:10', '在线用户菜单', '');
INSERT INTO `sys_menu` VALUES (110, '定时任务', 2, 2, 'job', 'monitor/job/index', '', 1, 0, 'C', '0', '0', 'monitor:job:list', 'job', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:15', '定时任务菜单', '');
INSERT INTO `sys_menu` VALUES (111, '数据监控', 2, 3, 'druid', 'monitor/druid/index', '', 1, 0, 'C', '0', '0', 'monitor:druid:list', 'druid', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:20', '数据监控菜单', '');
INSERT INTO `sys_menu` VALUES (112, '服务监控', 2, 4, 'server', 'monitor/server/index', '', 1, 0, 'C', '0', '0', 'monitor:server:list', 'server', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:23', '服务监控菜单', '');
INSERT INTO `sys_menu` VALUES (113, '缓存监控', 2, 5, 'cache', 'monitor/cache/index', '', 1, 0, 'C', '0', '0', 'monitor:cache:list', 'redis', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:28', '缓存监控菜单', '');
INSERT INTO `sys_menu` VALUES (114, '缓存列表', 2, 6, 'cacheList', 'monitor/cache/list', '', 1, 0, 'C', '0', '0', 'monitor:cache:list', 'redis-list', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:31', '缓存列表菜单', '');
INSERT INTO `sys_menu` VALUES (115, '表单构建', 3, 1, 'build', 'tool/build/index', '', 1, 0, 'C', '0', '0', 'tool:build:list', 'build', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:42', '表单构建菜单', '');
INSERT INTO `sys_menu` VALUES (116, '代码生成', 3, 2, 'gen', 'tool/gen/index', '', 1, 0, 'C', '0', '0', 'tool:gen:list', 'code', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:46', '代码生成菜单', '');
INSERT INTO `sys_menu` VALUES (117, '系统接口', 3, 3, 'swagger', 'tool/swagger/index', '', 1, 0, 'C', '0', '0', 'tool:swagger:list', 'swagger', 'admin', '2023-12-27 10:17:11', 'admin', '2026-03-19 09:41:49', '系统接口菜单', '');
INSERT INTO `sys_menu` VALUES (500, '操作日志', 108, 1, 'operlog', 'monitor/operlog/index', '', 1, 0, 'C', '0', '1', 'monitor:operlog:list', 'form', 'admin', '2023-12-27 10:17:11', '', NULL, '操作日志菜单', '');
INSERT INTO `sys_menu` VALUES (501, '登录日志', 108, 2, 'logininfor', 'monitor/logininfor/index', '', 1, 0, 'C', '0', '1', 'monitor:logininfor:list', 'logininfor', 'admin', '2023-12-27 10:17:11', '', NULL, '登录日志菜单', '');
INSERT INTO `sys_menu` VALUES (1000, '用户查询', 100, 1, '', '', '', 1, 0, 'F', '0', '0', 'system:user:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1001, '用户新增', 100, 2, '', '', '', 1, 0, 'F', '0', '0', 'system:user:add', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1002, '用户修改', 100, 3, '', '', '', 1, 0, 'F', '0', '0', 'system:user:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1003, '用户删除', 100, 4, '', '', '', 1, 0, 'F', '0', '0', 'system:user:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1004, '用户导出', 100, 5, '', '', '', 1, 0, 'F', '0', '0', 'system:user:export', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1005, '用户导入', 100, 6, '', '', '', 1, 0, 'F', '0', '0', 'system:user:import', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1006, '重置密码', 100, 7, '', '', '', 1, 0, 'F', '0', '0', 'system:user:resetPwd', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1007, '角色查询', 101, 1, '', '', '', 1, 0, 'F', '0', '0', 'system:role:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1008, '角色新增', 101, 2, '', '', '', 1, 0, 'F', '0', '0', 'system:role:add', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1009, '角色修改', 101, 3, '', '', '', 1, 0, 'F', '0', '0', 'system:role:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1010, '角色删除', 101, 4, '', '', '', 1, 0, 'F', '0', '0', 'system:role:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1011, '角色导出', 101, 5, '', '', '', 1, 0, 'F', '0', '0', 'system:role:export', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1012, '菜单查询', 102, 1, '', '', '', 1, 0, 'F', '0', '0', 'system:menu:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1013, '菜单新增', 102, 2, '', '', '', 1, 0, 'F', '0', '0', 'system:menu:add', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1014, '菜单修改', 102, 3, '', '', '', 1, 0, 'F', '0', '0', 'system:menu:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1015, '菜单删除', 102, 4, '', '', '', 1, 0, 'F', '0', '0', 'system:menu:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1016, '组织查询', 103, 1, '', '', '', 1, 0, 'F', '0', '0', 'system:dept:query', '#', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 10:40:09', '', '');
INSERT INTO `sys_menu` VALUES (1017, '组织新增', 103, 2, '', '', '', 1, 0, 'F', '0', '0', 'system:dept:add', '#', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 10:40:16', '', '');
INSERT INTO `sys_menu` VALUES (1018, '组织修改', 103, 3, '', '', '', 1, 0, 'F', '0', '0', 'system:dept:edit', '#', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 10:40:24', '', '');
INSERT INTO `sys_menu` VALUES (1019, '组织删除', 103, 4, '', '', '', 1, 0, 'F', '0', '0', 'system:dept:remove', '#', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 10:40:32', '', '');
INSERT INTO `sys_menu` VALUES (1020, '岗位查询', 104, 1, '', '', '', 1, 0, 'F', '0', '1', 'system:post:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1021, '岗位新增', 104, 2, '', '', '', 1, 0, 'F', '0', '1', 'system:post:add', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1022, '岗位修改', 104, 3, '', '', '', 1, 0, 'F', '0', '1', 'system:post:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1023, '岗位删除', 104, 4, '', '', '', 1, 0, 'F', '0', '1', 'system:post:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1024, '岗位导出', 104, 5, '', '', '', 1, 0, 'F', '0', '1', 'system:post:export', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1025, '字典查询', 105, 1, '#', '', '', 1, 0, 'F', '0', '1', 'system:dict:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1026, '字典新增', 105, 2, '#', '', '', 1, 0, 'F', '0', '1', 'system:dict:add', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1027, '字典修改', 105, 3, '#', '', '', 1, 0, 'F', '0', '1', 'system:dict:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1028, '字典删除', 105, 4, '#', '', '', 1, 0, 'F', '0', '1', 'system:dict:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1029, '字典导出', 105, 5, '#', '', '', 1, 0, 'F', '0', '1', 'system:dict:export', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1030, '参数查询', 106, 1, '#', '', '', 1, 0, 'F', '0', '1', 'system:config:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1031, '参数新增', 106, 2, '#', '', '', 1, 0, 'F', '0', '1', 'system:config:add', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1032, '参数修改', 106, 3, '#', '', '', 1, 0, 'F', '0', '1', 'system:config:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1033, '参数删除', 106, 4, '#', '', '', 1, 0, 'F', '0', '1', 'system:config:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1034, '参数导出', 106, 5, '#', '', '', 1, 0, 'F', '0', '1', 'system:config:export', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1035, '公告查询', 107, 1, '#', '', '', 1, 0, 'F', '0', '1', 'system:notice:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1036, '公告新增', 107, 2, '#', '', '', 1, 0, 'F', '0', '1', 'system:notice:add', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1037, '公告修改', 107, 3, '#', '', '', 1, 0, 'F', '0', '1', 'system:notice:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1038, '公告删除', 107, 4, '#', '', '', 1, 0, 'F', '0', '1', 'system:notice:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1039, '操作查询', 500, 1, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:operlog:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1040, '操作删除', 500, 2, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:operlog:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1041, '日志导出', 500, 3, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:operlog:export', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1042, '登录查询', 501, 1, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:logininfor:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1043, '登录删除', 501, 2, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:logininfor:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1044, '日志导出', 501, 3, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:logininfor:export', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1045, '账户解锁', 501, 4, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:logininfor:unlock', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1046, '在线查询', 109, 1, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:online:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1047, '批量强退', 109, 2, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:online:batchLogout', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1048, '单条强退', 109, 3, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:online:forceLogout', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1049, '任务查询', 110, 1, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:job:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1050, '任务新增', 110, 2, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:job:add', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1051, '任务修改', 110, 3, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:job:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1052, '任务删除', 110, 4, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:job:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1053, '状态修改', 110, 5, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:job:changeStatus', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1054, '任务导出', 110, 6, '#', '', '', 1, 0, 'F', '0', '1', 'monitor:job:export', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1055, '生成查询', 116, 1, '#', '', '', 1, 0, 'F', '0', '1', 'tool:gen:query', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1056, '生成修改', 116, 2, '#', '', '', 1, 0, 'F', '0', '1', 'tool:gen:edit', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1057, '生成删除', 116, 3, '#', '', '', 1, 0, 'F', '0', '1', 'tool:gen:remove', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1058, '导入代码', 116, 4, '#', '', '', 1, 0, 'F', '0', '1', 'tool:gen:import', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1059, '预览代码', 116, 5, '#', '', '', 1, 0, 'F', '0', '1', 'tool:gen:preview', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (1060, '生成代码', 116, 6, '#', '', '', 1, 0, 'F', '0', '1', 'tool:gen:code', '#', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2000, '报警管理', 0, 4, 'warning', NULL, NULL, 1, 0, 'M', '0', '0', NULL, 'bug', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2001, '报警列表', 2000, 1, 'warning', 'warning/index', NULL, 1, 0, 'C', '0', '0', NULL, 'bug', 'admin', '2023-12-27 10:17:11', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2004, '设备管理', 0, 5, 'device', NULL, NULL, 1, 0, 'M', '0', '0', NULL, 'nested', 'admin', '2024-01-23 15:35:46', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2006, '报警类型', 0, 6, 'type', NULL, NULL, 1, 0, 'M', '0', '0', NULL, 'star', 'admin', '2024-01-23 15:38:36', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2007, '报警类型', 2006, 1, 'type', 'warning/type', NULL, 1, 0, 'C', '0', '0', NULL, 'star', 'admin', '2024-01-23 15:39:05', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2008, '测试数据', 0, 7, 'handle', NULL, NULL, 1, 0, 'M', '0', '0', NULL, 'component', 'admin', '2024-01-25 10:35:05', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2009, '测试数据', 2008, 1, 'handle', 'warning/test', NULL, 1, 0, 'C', '0', '0', NULL, 'component', 'admin', '2024-01-25 10:35:39', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2010, '离线设备', 2004, 2, 'lixian', 'device/lixian', NULL, 1, 0, 'C', '0', '0', '', 'row', 'admin', '2024-02-22 09:07:57', 'admin', '2024-02-22 09:19:02', '', '');
INSERT INTO `sys_menu` VALUES (2012, '组织信息', 0, 8, '', NULL, NULL, 1, 0, 'F', '0', '0', 'getDeptList', '#', 'admin', '2024-03-20 08:56:50', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2013, '误报', 2000, 3, 'wubao', 'warning/wubao', NULL, 1, 0, 'C', '0', '0', '', 'edit', 'admin', '2024-06-11 09:44:34', 'admin', '2024-06-11 09:45:46', '', '');
INSERT INTO `sys_menu` VALUES (2019, '设备管理', 2004, 1, 'manage', 'device/manage', '', 1, 0, 'C', '0', '0', 'waring:device:query', 'edit', 'admin', '2026-03-19 10:30:42', 'admin', '2026-03-23 09:51:32', '设备管理菜单', '');
INSERT INTO `sys_menu` VALUES (2020, '设备查询', 2019, 1, '', '', '', 1, 0, 'F', '0', '0', 'waring:device:query', '#', 'admin', '2026-03-19 10:30:42', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2021, '设备新增', 2019, 2, '', '', '', 1, 0, 'F', '0', '0', 'waring:device:add', '#', 'admin', '2026-03-19 10:30:42', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2022, '设备修改', 2019, 3, '', '', '', 1, 0, 'F', '0', '0', 'waring:device:edit', '#', 'admin', '2026-03-19 10:30:42', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2023, '设备删除', 2019, 4, '', '', '', 1, 0, 'F', '0', '0', 'waring:device:remove', '#', 'admin', '2026-03-19 10:30:42', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2024, '布控管理', 0, 10, 'deployment', '', '', 1, 0, 'M', '0', '0', '', 'build', 'admin', '2026-03-19 20:58:43', 'admin', '2026-03-19 22:05:54', '布控管理目录', '');
INSERT INTO `sys_menu` VALUES (2025, '布控管理', 2024, 2, 'add', 'deployment/add', '', 1, 0, 'C', '0', '0', 'deployment:task:add', 'edit', 'admin', '2026-03-19 20:58:43', 'admin', '2026-03-21 10:37:02', '添加布控菜单', '');
INSERT INTO `sys_menu` VALUES (2026, '布控列表', 2024, 1, 'index', 'deployment/index', '', 1, 0, 'C', '0', '0', 'deployment:task:list', 'list', 'admin', '2026-03-19 21:18:09', 'admin', '2026-03-19 22:05:54', '布控列表菜单', '');
INSERT INTO `sys_menu` VALUES (2027, '实时监控', 2004, 2, 'realtime', 'device/realtime', '', 1, 0, 'C', '0', '0', 'waring:device:query', 'monitor', 'admin', '2026-03-20 16:34:31', 'admin', '2026-03-20 16:47:55', '实时监控菜单', '');
INSERT INTO `sys_menu` VALUES (2028, '实时监控查询', 2027, 1, '', '', '', 1, 0, 'F', '0', '0', 'waring:device:query', '#', 'admin', '2026-03-20 16:34:31', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2029, '启动监控', 2027, 2, '', '', '', 1, 0, 'F', '0', '0', 'waring:device:edit', '#', 'admin', '2026-03-20 16:34:31', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2030, '停止监控', 2027, 3, '', '', '', 1, 0, 'F', '0', '0', 'waring:device:edit', '#', 'admin', '2026-03-20 16:34:31', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2031, '预览视频', 2027, 4, '', '', '', 1, 0, 'F', '0', '0', 'waring:device:query', '#', 'admin', '2026-03-20 16:34:31', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2032, '媒体服务器', 2, 7, 'media', 'monitor/media/index', '', 1, 0, 'C', '0', '0', 'monitor:media:list', 'server', 'admin', '2026-03-22 23:03:13', 'admin', '2026-03-22 23:03:13', '媒体服务器菜单', '');
INSERT INTO `sys_menu` VALUES (2033, '媒体服务器查询', 2032, 1, '#', '', '', 1, 0, 'F', '0', '0', 'monitor:media:list', '#', 'admin', '2026-03-22 23:03:13', 'admin', '2026-03-22 23:03:13', '媒体服务器查询按钮', '');
INSERT INTO `sys_menu` VALUES (2034, '算法服务器', 2, 8, 'algorithm', 'monitor/algorithm/index', '', 1, 0, 'C', '0', '0', 'monitor:algorithm:list', 'server', 'admin', '2026-03-23 08:55:10', 'admin', '2026-03-23 08:55:10', '算法服务器菜单', '');
INSERT INTO `sys_menu` VALUES (2035, '算法服务器查询', 2034, 1, '#', '', '', 1, 0, 'F', '0', '0', 'monitor:algorithm:list', '#', 'admin', '2026-03-23 08:55:10', 'admin', '2026-03-23 08:55:10', '算法服务器查询按钮', '');
INSERT INTO `sys_menu` VALUES (2036, '系统参数', 1, 7, 'runtimeConfig', 'system/config/business', '', 1, 0, 'C', '0', '0', 'system:config:list', 'edit', 'admin', '2026-04-17 21:02:45', 'admin', '2026-04-17 21:02:45', '系统默认参数业务页', '');
INSERT INTO `sys_menu` VALUES (2037, '授权管理', 1, 99, 'license', 'system/license/index', '', 1, 0, 'C', '0', '0', 'system:license:view', 'lock', 'admin', '2026-04-27 16:23:09', 'admin', '2026-04-27 16:23:09', '授权状态与激活管理', '');
INSERT INTO `sys_menu` VALUES (2038, '授权查看', 2037, 1, '', '', '', 1, 0, 'F', '0', '0', 'system:license:view', '#', 'admin', '2026-04-27 16:23:09', '', NULL, '', '');
INSERT INTO `sys_menu` VALUES (2039, '授权激活', 2037, 2, '', '', '', 1, 0, 'F', '0', '0', 'system:license:edit', '#', 'admin', '2026-04-27 16:23:09', '', NULL, '', '');

-- ----------------------------
-- Table structure for sys_notice
-- ----------------------------
DROP TABLE IF EXISTS `sys_notice`;
CREATE TABLE `sys_notice`  (
  `notice_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '公告ID',
  `notice_title` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '公告标题',
  `notice_type` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '公告类型（1通知 2公告）',
  `notice_content` longblob NULL DEFAULT NULL COMMENT '公告内容',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '公告状态（0正常 1关闭）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`notice_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '通知公告表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_notice
-- ----------------------------

-- ----------------------------
-- Table structure for sys_oper_log
-- ----------------------------
DROP TABLE IF EXISTS `sys_oper_log`;
CREATE TABLE `sys_oper_log`  (
  `oper_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志主键',
  `title` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '模块标题',
  `business_type` int(11) NULL DEFAULT 0 COMMENT '业务类型（0其它 1新增 2修改 3删除）',
  `method` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '方法名称',
  `request_method` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '请求方式',
  `operator_type` int(11) NULL DEFAULT 0 COMMENT '操作类别（0其它 1后台用户 2手机端用户）',
  `oper_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '操作人员',
  `dept_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '部门名称',
  `oper_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '请求URL',
  `oper_ip` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '主机地址',
  `oper_location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '操作地点',
  `oper_param` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '请求参数',
  `json_result` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '返回参数',
  `status` int(11) NULL DEFAULT 0 COMMENT '操作状态（0正常 1异常）',
  `error_msg` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '错误消息',
  `oper_time` datetime NULL DEFAULT NULL COMMENT '操作时间',
  `cost_time` bigint(20) NULL DEFAULT 0 COMMENT '消耗时间',
  PRIMARY KEY (`oper_id`) USING BTREE,
  INDEX `idx_sys_oper_log_bt`(`business_type`) USING BTREE,
  INDEX `idx_sys_oper_log_s`(`status`) USING BTREE,
  INDEX `idx_sys_oper_log_ot`(`oper_time`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 179 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '操作日志记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_oper_log
-- ----------------------------

-- ----------------------------
-- Table structure for sys_post
-- ----------------------------
DROP TABLE IF EXISTS `sys_post`;
CREATE TABLE `sys_post`  (
  `post_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '岗位ID',
  `post_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '岗位编码',
  `post_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '岗位名称',
  `post_sort` int(11) NOT NULL COMMENT '显示顺序',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '状态（0正常 1停用）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`post_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '岗位信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_post
-- ----------------------------
INSERT INTO `sys_post` VALUES (1, 'ceo', '董事长', 1, '1', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 11:17:25', '');
INSERT INTO `sys_post` VALUES (2, 'se', '项目经理', 2, '1', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 11:17:29', '');
INSERT INTO `sys_post` VALUES (3, 'hr', '人力资源', 3, '1', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 11:17:32', '');
INSERT INTO `sys_post` VALUES (4, 'user', '普通员工', 4, '1', 'admin', '2023-12-27 10:17:11', 'admin', '2023-12-27 11:17:36', '');

-- ----------------------------
-- Table structure for sys_role
-- ----------------------------
DROP TABLE IF EXISTS `sys_role`;
CREATE TABLE `sys_role`  (
  `role_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '角色ID',
  `role_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '角色名称',
  `role_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '角色权限字符串',
  `role_sort` int(11) NOT NULL COMMENT '显示顺序',
  `data_scope` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '1' COMMENT '数据范围（1：全部数据权限 2：自定数据权限 3：本部门数据权限 4：本部门及以下数据权限）',
  `menu_check_strictly` tinyint(1) NULL DEFAULT 1 COMMENT '菜单树选择项是否关联显示',
  `dept_check_strictly` tinyint(1) NULL DEFAULT 1 COMMENT '部门树选择项是否关联显示',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '角色状态（0正常 1停用）',
  `del_flag` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '删除标志（0代表存在 2代表删除）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`role_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '角色信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_role
-- ----------------------------
INSERT INTO `sys_role` VALUES (1, '超级管理员', 'admin', 1, '1', 1, 1, '0', '0', 'admin', '2023-12-27 10:17:11', '', NULL, '超级管理员');

-- ----------------------------
-- Table structure for sys_role_dept
-- ----------------------------
DROP TABLE IF EXISTS `sys_role_dept`;
CREATE TABLE `sys_role_dept`  (
  `role_id` bigint(20) NOT NULL COMMENT '角色ID',
  `dept_id` bigint(20) NOT NULL COMMENT '部门ID',
  PRIMARY KEY (`role_id`, `dept_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '角色和部门关联表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_role_dept
-- ----------------------------

-- ----------------------------
-- Table structure for sys_role_menu
-- ----------------------------
DROP TABLE IF EXISTS `sys_role_menu`;
CREATE TABLE `sys_role_menu`  (
  `role_id` bigint(20) NOT NULL COMMENT '角色ID',
  `menu_id` bigint(20) NOT NULL COMMENT '菜单ID',
  PRIMARY KEY (`role_id`, `menu_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '角色和菜单关联表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_role_menu
-- ----------------------------
INSERT INTO `sys_role_menu` VALUES (1, 2019);
INSERT INTO `sys_role_menu` VALUES (1, 2020);
INSERT INTO `sys_role_menu` VALUES (1, 2021);
INSERT INTO `sys_role_menu` VALUES (1, 2022);
INSERT INTO `sys_role_menu` VALUES (1, 2023);
INSERT INTO `sys_role_menu` VALUES (1, 2024);
INSERT INTO `sys_role_menu` VALUES (1, 2025);
INSERT INTO `sys_role_menu` VALUES (1, 2026);
INSERT INTO `sys_role_menu` VALUES (1, 2027);
INSERT INTO `sys_role_menu` VALUES (1, 2028);
INSERT INTO `sys_role_menu` VALUES (1, 2029);
INSERT INTO `sys_role_menu` VALUES (1, 2030);
INSERT INTO `sys_role_menu` VALUES (1, 2031);
INSERT INTO `sys_role_menu` VALUES (1, 2036);
INSERT INTO `sys_role_menu` VALUES (1, 2037);
INSERT INTO `sys_role_menu` VALUES (1, 2038);
INSERT INTO `sys_role_menu` VALUES (1, 2039);

-- ----------------------------
-- Table structure for sys_user
-- ----------------------------
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user`  (
  `user_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `dept_id` bigint(20) NULL DEFAULT NULL COMMENT '部门ID',
  `login_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '登录账号',
  `user_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '用户账号',
  `nick_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '用户昵称',
  `user_type` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '00' COMMENT '用户类型（00系统用户）',
  `email` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '用户邮箱',
  `phonenumber` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '手机号码',
  `sex` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '用户性别（0男 1女 2未知）',
  `avatar` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '头像地址',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '密码',
  `salt` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '盐加密',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '帐号状态（0正常 1停用）',
  `del_flag` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '0' COMMENT '删除标志（0代表存在 2代表删除）',
  `login_ip` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '最后登录IP',
  `login_date` datetime NULL DEFAULT NULL COMMENT '最后登录时间',
  `pwd_update_date` datetime NULL DEFAULT NULL COMMENT '密码最后更新时间',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '创建者',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT '' COMMENT '更新者',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用户信息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user
-- ----------------------------
INSERT INTO `sys_user` VALUES (1, 100, 'admin', 'admin', '超级管理员', '00', '', '', '1', '', '$2a$10$Fev5YJTdy2wH11NERZ9PyeIeBFwFwQ4gERHxqqi2Zmb3WlJl.DEh2', '111111', '0', '0', '127.0.0.1', '2026-05-20 10:34:32', '2026-03-17 22:07:52', 'admin', '2023-12-27 10:17:11', '', '2026-03-18 11:31:45', '管理员 | reset by copilot 2026-03-18 11:31:38');

-- ----------------------------
-- Table structure for sys_user_online
-- ----------------------------
DROP TABLE IF EXISTS `sys_user_online`;
CREATE TABLE `sys_user_online`  (
  `sessionId` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '用户会话id',
  `login_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '登录账号',
  `dept_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '部门名称',
  `ipaddr` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '登录IP地址',
  `login_location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '登录地点',
  `browser` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '浏览器类型',
  `os` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '操作系统',
  `status` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '在线状态on_line在线off_line离线',
  `start_timestamp` datetime NULL DEFAULT NULL COMMENT 'session创建时间',
  `last_access_time` datetime NULL DEFAULT NULL COMMENT 'session最后访问时间',
  `expire_time` int(11) NULL DEFAULT 0 COMMENT '超时时间，单位为分钟',
  PRIMARY KEY (`sessionId`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '在线用户记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user_online
-- ----------------------------

-- ----------------------------
-- Table structure for sys_user_post
-- ----------------------------
DROP TABLE IF EXISTS `sys_user_post`;
CREATE TABLE `sys_user_post`  (
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `post_id` bigint(20) NOT NULL COMMENT '岗位ID',
  PRIMARY KEY (`user_id`, `post_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用户与岗位关联表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user_post
-- ----------------------------
INSERT INTO `sys_user_post` VALUES (1, 1);

-- ----------------------------
-- Table structure for sys_user_role
-- ----------------------------
DROP TABLE IF EXISTS `sys_user_role`;
CREATE TABLE `sys_user_role`  (
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `role_id` bigint(20) NOT NULL COMMENT '角色ID',
  PRIMARY KEY (`user_id`, `role_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin COMMENT = '用户和角色关联表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user_role
-- ----------------------------
INSERT INTO `sys_user_role` VALUES (1, 1);

-- ----------------------------
-- Table structure for zlm_server
-- ----------------------------
DROP TABLE IF EXISTS `zlm_server`;
CREATE TABLE `zlm_server`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `app` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `host` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `api_port` int(11) NOT NULL,
  `media_http_port` int(11) NOT NULL,
  `media_rtsp_port` int(11) NOT NULL,
  `secret` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `remark` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  `update_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_zlm_enabled`(`enabled`) USING BTREE,
  INDEX `idx_zlm_update_time`(`update_time`) USING BTREE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`enabled` in (0,1))
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of zlm_server
-- ----------------------------
INSERT INTO `zlm_server` VALUES (1, 'default-zlm', 'live', '127.0.0.1', 9992, 9992, 9994, 'V3522025zlm0aA9ajn7UiOWi', 1, 'default config', '2026-03-20 20:40:08', '2026-04-09 12:01:28');

SET FOREIGN_KEY_CHECKS = 1;
