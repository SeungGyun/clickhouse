CREATE TABLE default.kafka_raw_logs
(
    raw_data String  -- Kafka 메시지를 그대로 저장
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'localhost1:9092,localhost2:9092',
         kafka_topic_list = 'test',
         kafka_group_name = 'clickhouse_consumer',
         kafka_format = 'JSONEachRow',
         kafka_num_consumers = 3,  -- 병렬 소비자 3개
         kafka_handle_error_mode = 'stream';


CREATE TABLE default.parsed_logs
(
    log_id UInt64,
    app_id UInt32,
    tid String,
    branch String,
    sid UInt32,
    tag String,
    device_id String,
    os_type String,
    app_version String,
    event_type UInt32,
    api_domain UInt32,
    api_group String,
    api_name String,
    parameters String,
    response String,
    succeed Bool,
    error_code Nullable(UInt32),
    started_at DateTime,
    finished_at DateTime,
    elapsed_time UInt32
) ENGINE = MergeTree()
ORDER BY log_id;


DROP table mv_parsed_logs;

CREATE MATERIALIZED VIEW mv_parsed_logs TO parsed_logs AS
SELECT
    JSONExtractString(raw_data, 'log_id') AS log_id,
    JSONExtractUInt(raw_data, 'app_id') AS app_id,
    JSONExtractUInt(raw_data, 'head.log_type') AS log_type,
    JSONExtractString(raw_data, 'head.branch') AS branch,
    UUIDStringToNum(JSONExtractString(raw_data, 'head.tid')) AS tid,  -- UUID 변환
    JSONExtractUInt(raw_data, 'head.sid') AS sid,
    JSONExtractString(raw_data, 'head.tag') AS tag,
    JSONExtractString(raw_data, 'head.device.id') AS device_id,
    JSONExtractString(raw_data, 'head.device.sdk_did') AS sdk_did,
    JSONExtractString(raw_data, 'head.device.screen_resolution') AS screen_resolution,
    JSONExtractString(raw_data, 'head.network.type') AS network_type,
    JSONExtractString(raw_data, 'head.instance.os_type') AS os_type,
    assumeNotNull(JSONExtractString(raw_data, 'head.instance.app_version')) AS app_version,  -- NULL 방지
    JSONExtractUInt(raw_data, 'body.data.api_domain') AS api_domain,
    JSONExtractString(raw_data, 'body.data.api_group') AS api_group,
    JSONExtractString(raw_data, 'body.data.api_name') AS api_name,
    JSONExtractString(raw_data, 'body.data.parameters') AS parameters,
    JSONExtractString(raw_data, 'body.data.response') AS response,
    JSONExtractBool(raw_data, 'body.data.succeed') AS succeed,
    assumeNotNull(JSONExtractUInt(raw_data, 'body.data.error_code')) AS error_code,  -- NULL 방지
    toDateTime(JSONExtractUInt(raw_data, 'body.data.started_at') / 1000) AS started_at,
    toDateTime(JSONExtractUInt(raw_data, 'body.data.finished_at') / 1000) AS finished_at,
    JSONExtractUInt(raw_data, 'body.data.elapsed_time') AS elapsed_time
FROM kafka_raw_logs;
