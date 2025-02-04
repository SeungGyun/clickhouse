import clickhouse_connect

# ClickHouse 서버에 연결
client = clickhouse_connect.get_client(host='localhost', port=8123, username='default', password='')

# 1. 테이블 생성 (이미 존재하면 생략 가능)
client.command('''
    CREATE TABLE IF NOT EXISTS test_table2 (
        id UInt32,
        name String,
        age UInt8
    ) ENGINE = MergeTree()
    ORDER BY id
''')

# 2. 데이터 삽입
data = [
    (1, 'Alice', 25),
    (2, 'Bob', 30),
    (3, 'Charlie', 22)
]
client.insert('test_table2', data, column_names=['id', 'name', 'age'])

# 3. 데이터 조회
rows = client.query('SELECT * FROM test_table2')

# 4. 결과 출력
for row in rows.result_rows:
    print(row)