-- Создаем таблицу
CREATE TABLE IF NOT EXISTS network_traffic (
	time TIMESTAMPTZ NOT NULL,
	bytes_in INT NOT NULL,
	bytes_out INT NOT NULL
);

-- Превращаем ее в гипертаблицу, с разбиением временных чанков на интервалы по 1 дню, для корректной работы с TimeScaleDB
SELECT create_hypertable('network_traffic', 'time', chunk_time_interval => INTERVAL '1 day');

-- Создаем непрерывный агрегат
CREATE MATERIALIZED VIEW IF NOT EXISTS traffic_hourly_sum
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 hour', time) AS bucket,
	SUM(bytes_in) AS total_bytes_in,
	SUM(bytes_out) AS total_bytes_out,
	SUM(bytes_in + bytes_out) AS total_bytes_all
FROM network_traffic
GROUP BY bucket;

-- Настраиваем автообновление каждый час
SELECT 
	add_continuous_aggregate_policy(
		'traffic_hourly_sum', 
		start_offset => INTERVAL '2 hours', 
		end_offset => INTERVAL '00:00:00', 
		schedule_interval => INTERVAL '1 hour',
		if_not_exists => TRUE
	);

-- Рассчитываем скользящее среднее
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
    GROUP BY minute) sub  
ORDER BY minute;
