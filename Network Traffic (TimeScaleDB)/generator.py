import random
from datetime import datetime, timedelta
import psycopg2

DB_CONFIG = {
    "dbname": "",
    "user": "",
    "password": "",
    "host": "",
    "port": ""
}

def generate_traffic_data(records_count=2000):
    data = []
    current_time = datetime.now()

    for i in range(records_count):
        timestamp = current_time - timedelta(seconds=10 * i)

        bytes_in = random.randint(5000, 10000) if random.random() < 0.10 else random.randint(100, 500)
        bytes_out = random.randint(5000, 10000) if random.random() < 0.10 else random.randint(100, 500)

        data.append((timestamp, bytes_in, bytes_out))

    return data[::-1]

def upload_to_timescaledb(data):
    try:
        conn = psycopg2.connect(**DB_CONFIG)

        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute("TRUNCATE TABLE network_traffic;")

        query = "INSERT INTO network_traffic (time, bytes_in, bytes_out) VALUES (%s, %s, %s)"
        cursor.executemany(query, data)

        print("Данные успешно загружены в гипертаблицу. Обновляем агрегат...")

        cursor.execute("CALL refresh_continuous_aggregate('traffic_hourly_sum', NULL, NULL);")
        # NULL, NULL означает «пересчитай вообще всю историю, которая сейчас есть в базе».

        print(f"Успешно загружено {len(data)} записей и обновлен агрегат!")

    except Exception as e:
        # Если база данных отключена или в пароле ошибка — покажет здесь
        print(f"Ошибка: {e}")
    finally:
        if conn:
            cursor.close()
            conn.close()
if __name__ == "__main__":
    traffic_records = generate_traffic_data(2000)
    upload_to_timescaledb(traffic_records)
