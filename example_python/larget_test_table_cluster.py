import clickhouse_connect
import random
import time
from datetime import datetime

# ClickHouse 서버 연결
client = clickhouse_connect.get_client(
    host='localhost',
    port=18123,
    username='default',  # default 사용자 비밀번호 없이 가능 (또는 설정한 사용자 사용)
    settings={'insert_quorum': 2},  # ✅ 클러스터 환경 최적화
    compress=True  # ✅ 데이터 압축 전송
)

# 1️⃣ 테이블 생성
def create_table():
    client.command('''
        CREATE TABLE IF NOT EXISTS large_test_table (
            id UInt32,
            name String,
            age UInt8,
            created_at DateTime DEFAULT now()
        ) ENGINE = MergeTree()
        ORDER BY id
    ''')
    print("✅ 테이블 생성 완료!")

# 2️⃣ 대량 데이터 생성 (100만 개)
def generate_data(num_rows=1_000_000):
    return [(i, f'User_{i}', random.randint(18, 60), datetime.now()) for i in range(1, num_rows + 1)]

# 3️⃣ 빠른 배치 삽입 (한 번에 10,000개씩)
def insert_data_batch(data, batch_size=10_000):
    start_time = time.time()
    for i in range(0, len(data), batch_size):
        batch = data[i:i + batch_size]
        client.insert('large_test_table', batch, column_names=['id', 'name', 'age', 'created_at'])
        print(f"🟢 {i + batch_size}개 삽입 완료")
    end_time = time.time()
    print(f"✅ 대용량 데이터 삽입 완료! 총 소요 시간: {end_time - start_time:.2f}초")

# 4️⃣ 데이터 조회 성능 테스트
def query_data():
    start_time = time.time()
    rows = client.query('SELECT COUNT(*) FROM large_test_table WHERE age > 30')
    end_time = time.time()
    print(f"🔍 조회 결과: {rows.result_rows}")
    print(f"✅ 조회 시간: {end_time - start_time:.2f}초")

# 🏁 실행 코드
if __name__ == "__main__":
    create_table()  # 테이블 생성
    data = generate_data(1_000_000)  # 100만 개 데이터 생성
    insert_data_batch(data)  # 배치 삽입 실행
    query_data()  # 조회 성능 테스트
