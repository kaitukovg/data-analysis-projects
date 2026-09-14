import psycopg2
import matplotlib
# matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import timedelta

DB_CONFIG = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "111111111",
    "host": "127.0.0.1",
    "port": "5432"
}

def fetch_data():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    # Вся аналитика выполняется на стороне СУБД с помощью оконных функций
    cursor.execute("""
        SELECT 
            minute,
            total_bytes,
            COALESCE(AVG(total_bytes) OVER (
                ORDER BY minute 
                ROWS BETWEEN 14 PRECEDING AND CURRENT ROW
            ), 0) AS rolling_mean,
            
            COALESCE(STDDEV_SAMP(total_bytes) OVER (
                ORDER BY minute 
                ROWS BETWEEN 14 PRECEDING AND CURRENT ROW
            ), 0) AS rolling_std
        FROM (
            SELECT time_bucket('1 minute', time) AS minute,
                   SUM(bytes_in + bytes_out) AS total_bytes
            FROM network_traffic
            GROUP BY minute
        ) sub
        ORDER BY minute;
    """)
    minute_data = cursor.fetchall()

    # Запрос для получения часа-пик из непрерывного агрегата
    cursor.execute("""
        SELECT bucket 
        FROM traffic_hourly_sum 
        ORDER BY total_bytes_all DESC 
        LIMIT 1;"""
    )
    peak_hour = cursor.fetchone()[0]

    cursor.close()
    conn.close()
    return minute_data, peak_hour

def plot_traffic():
    minute_data, peak_hour = fetch_data()

    # Разбираем данные, полученные из SQL, переводя числовые значения во float
    times = [row[0] for row in minute_data]
    traffic = [float(row[1]) for row in minute_data]
    means = [float(row[2]) for row in minute_data]
    stds = [float(row[3]) for row in minute_data]

    # Коэффициент чувствительности (уменьшили с 3 до 1.5, чтобы точно находить аномалии)
    SIGMA_COEF = 1.5

    # Вычисляем динамический порог на лету: Среднее + 1.5 * Сигма
    dynamic_thresholds = [m + SIGMA_COEF * s for m, s in zip(means, stds)]

    # Ищем аномалии (где синяя линия графика пробила оранжевый динамический порог)
    anomaly_indices = [i for i in range(len(traffic)) if traffic[i] > dynamic_thresholds[i]]
    anomaly_times = [times[i] for i in anomaly_indices]
    anomaly_values = [traffic[i] for i in anomaly_indices]

    plt.figure(figsize=(12, 6))

    # Отрисовка графиков
    plt.plot(times, traffic, label='Трафик (байт/мин)', color='#1f77b4', linewidth=1.5)
    plt.plot(times, means, label='Скользящее среднее (SQL, 15 мин)', color='green', linestyle=':', alpha=0.8)
    plt.plot(times, dynamic_thresholds, label=f'Динамический порог (MA + {SIGMA_COEF}σ)', color='orange', linestyle='--', alpha=0.8)

    # Подсветка Часа-пик
    peak_hour_end = peak_hour + timedelta(hours=1)
    plt.axvspan(peak_hour, peak_hour_end, color='red', alpha=0.12,
                label=f'Час-пик ({peak_hour.strftime("%H:%M")} - {peak_hour_end.strftime("%H:%M")})')

    # Вывод текстового отчета в консоль и отрисовка красных точек
    if anomaly_times:
        plt.scatter(anomaly_times, anomaly_values, color='red', zorder=5, label='Аномальный всплеск')

        print("\n" + "="*80)
        print(f"ВНИМАНИЕ! АНАЛИЗ НА СТОРОНЕ СУБД ОБНАРУЖИЛ АНОМАЛИИ: {len(anomaly_times)}")
        print("="*80)
        for i in anomaly_indices:
            t = times[i]
            v = traffic[i]
            th = dynamic_thresholds[i]
            print(f"[{t.strftime('%H:%M:%S')}] Всплеск: {int(v):_} байт (Динамический порог {int(th):_} байт превышен!)")
        print("="*80 + "\n")
    else:
        print("\n" + "="*80)
        print("Аномалий не обнаружено. Сетевой трафик соответствует норме.")
        print("="*80 + "\n")

    # Оформление внешнего вида графика
    plt.title('Мониторинг сети с динамическим порогом через Оконные функции SQL', fontsize=14, fontweight='bold')
    plt.xlabel('Время', fontsize=12)
    plt.ylabel('Объем трафика (байт)', fontsize=12)

    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
    plt.grid(True, linestyle=':', alpha=0.6)
    plt.legend(loc='upper left')

    plt.savefig('traffic_report.png', dpi=300)
    print("График успешно сохранен как 'traffic_report.png'!")
    plt.show()

if __name__ == "__main__":
    plot_traffic()