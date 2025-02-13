 
 
 
 
 
 
DROP TABLE IF EXISTS sample.kafka_raw_logs;


CREATE TABLE sample.kafka_raw_logs (
    log_id UInt64,
    app_id UInt8,
    branch_id UInt8,
    head String  -- ✅ JSON 전체를 String으로 저장
) ENGINE = Kafka
SETTINGS 
    kafka_broker_list = 'localhost:9092',
    kafka_topic_list = 'topic',
    kafka_group_name = 'clickhouse_consumer2',
    kafka_num_consumers = 6,
    kafka_format = 'JSONEachRow';



DROP TABLE IF EXISTS sample.kafka2_logs;

CREATE TABLE sample.kafka2_logs (
    log_id UInt64,
    app_id UInt8,
    branch_id UInt8,
    head_sid UInt32  -- ✅ JSON에서 추출한 `sid` 값 저장
) ENGINE = MergeTree()
ORDER BY (log_id);



DROP VIEW IF EXISTS sample.kafka2_to_clickhouse_logs;

CREATE MATERIALIZED VIEW sample.kafka2_to_clickhouse_logs
TO sample.kafka2_logs
AS
SELECT
    log_id,
    app_id,
    branch_id,
    JSONExtractInt(head, 'sid') AS head_sid  -- ✅ JSON에서 직접 `sid` 값 추출
FROM sample.kafka_raw_logs;
