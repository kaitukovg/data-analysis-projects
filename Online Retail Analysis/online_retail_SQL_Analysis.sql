-- Создадим структуры таблицы

-- CREATE TABLE retail (
-- 	invoice TEXT,
-- 	stockCode VARCHAR,
-- 	description VARCHAR,
-- 	quantity INTEGER,
-- 	date TIMESTAMP,
-- 	price NUMERIC,
-- 	customer_id NUMERIC,
-- 	state VARCHAR
-- );

-- Импортируем данные из .csv файла

-- COPY retail
-- FROM 'C:\online_retail_II_US_states_30.csv'
-- WITH (
-- 	FORMAT 'csv',
-- 	HEADER TRUE,
-- 	DELIMITER ','
-- );

-- Посмотрим сколько всего записей
SELECT COUNT(*) FROM public.retail;

-- Количество уникальных заказов
SELECT 
	COUNT(DISTINCT invoice) AS distinct_order
FROM retail;

-- Создадим представление, где каждая строка это 1 заказ, 1 клиент, 1 страна
CREATE OR REPLACE VIEW single_order AS (
	SELECT invoice,
		date,
		state,
		SUM(price * quantity) AS revenue,
		COUNT(*) AS item_in_order,
		customer_id AS customer
	FROM retail
	WHERE price > 0
		AND quantity != 0
	GROUP BY invoice, date, state, customer_id
);

-- Проверка предсталвения
SELECT * FROM single_order;

-- Посмотрим суммарную выручку, среднюю выручку, количество заказов, среднее количество позиций в заказе
SELECT ROUND(SUM(revenue), 2) AS total_revenue,
	ROUND(AVG(revenue), 2) AS avg_revenue, 
	COUNT(revenue),
	ROUND(AVG(item_in_order), 2) AS avg_count_items_in_order,
	COUNT(DISTINCT customer) AS user_count
FROM single_order;

-- Топ-5 стран с наибольшим средним чеком
SELECT state, 
	ROUND(AVG(revenue), 2) AS avg_revenue
FROM single_order
GROUP BY state
ORDER BY 2 DESC
LIMIT 5;

-- Страны с наименьшим чеком
SELECT state, 
	ROUND(AVG(revenue), 2) AS avg_revenue
FROM single_order
GROUP BY state
ORDER BY 2 ASC
LIMIT 5;

-- Страны с наибольшим кол-вом заказов
SELECT state, 
	COUNT(*) AS order_count
FROM single_order
GROUP BY state
ORDER BY 2 DESC
LIMIT 5;

-- Страны с наименьшим кол-вом заказов
SELECT state, 
	COUNT(*) AS order_count
FROM single_order
GROUP BY state
ORDER BY 2 ASC
LIMIT 5;

-- Посмотрим в какие часы заказывали больше всего и меньше всего
SELECT
	EXTRACT(HOUR FROM date) AS hour,
	COUNT(*),
	ROUND(SUM(revenue), 2) AS hourly_rev,
	ROUND(AVG(revenue), 2) AS hourly_avg_check
FROM single_order
GROUP BY hour
ORDER BY 3 DESC;

/* Создадим представление, рассчитаем выручку для каждого заказа 
и категоризируем заказы, где sold — товар продали,
							returned — товар вернули
*/
CREATE OR REPLACE VIEW retail_clean AS (
	SELECT 
		invoice,
		stockcode AS item,
		description,
		quantity,
		price,
		date,
		customer_id AS customer,
		state,
		quantity * price AS revenue,
		CASE 
			WHEN quantity > 0 THEN 'sold'
			WHEN quantity < 0 THEN 'returned'
			ELSE 'other'
		END AS type
	FROM retail
	WHERE price > 0 
		AND quantity <> 0 
);

-- Узнаем количество проданных и возвращенных товаров
SELECT type, COUNT(*) FROM retail_clean
GROUP BY 1;

-- Какие товары самые продаваемые?
SELECT item,
	SUM(quantity)
FROM retail_clean
WHERE type = 'sold'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Какие товары самые возвращаемые?
SELECT item,
	SUM(-quantity) AS returned_quantity
FROM retail_clean
WHERE type = 'returned'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Какие товары лучше всего продаются в каждом регионе?
WITH state_and_items AS (
	SELECT DISTINCT ON (state)
		state,
		item,
		SUM(quantity) AS quantity
	FROM retail_clean
	WHERE type = 'sold'
	GROUP BY state, item
	ORDER BY state, SUM(quantity) DESC
)
SELECT * FROM state_and_items 
ORDER BY quantity DESC;

-- топ-3 покупателя в каждом регионе
WITH ranked_customers AS (
	SELECT state,
		customer,
		COUNT(DISTINCT invoice) AS orders,
		ROW_NUMBER() OVER (
			PARTITION BY state
			ORDER BY COUNT(DISTINCT invoice) DESC
		) AS rank
	FROM retail_clean
	WHERE customer IS NOT NULL
	GROUP BY state, customer
) 
SELECT state,
	customer,
	orders
FROM ranked_customers 
WHERE rank <= 3;

-- Сколько выручки приходится на каждый квартиль
WITH customer_revenue AS(
	SELECT 	
		customer,
		SUM(revenue) AS revenue
	FROM single_order
	WHERE customer IS NOT NULL
	GROUP BY customer
),
customers AS (
	SELECT customer,
		revenue,
		NTILE(4) OVER (
			ORDER BY revenue DESC
		) AS revenue_group
	FROM customer_revenue
)
SELECT revenue_group,
	SUM(revenue) AS quartile_revenue
FROM customers
GROUP BY revenue_group;

-- Посмотрим количество заказов и выручку для каждого покупателя
SELECT customer,
	COUNT(*),
	SUM(revenue)
FROM single_order
WHERE customer IS NOT NULL
GROUP BY customer
ORDER BY 3 DESC, 2 DESC;
-- Мы видим что наибольшее количество заказов еще не означает наибольшую выручку

-- Какую долю всей выручки составляют топ-10 товаров по выручке
WITH top_10_items AS (
	SELECT item,
		SUM(revenue) AS rev
	FROM retail_clean
	GROUP BY item
	ORDER BY 2 DESC
	LIMIT 10
)
SELECT 
	ROUND((
		SELECT SUM(rev) FROM top_10_items
	) / (
		SELECT SUM(revenue) FROM retail_clean
	) * 100, 2) AS "Top 10 item fraction"
;

-- Какую долю всей выручки составляют топ-10 товаров по количеству продаж
WITH top_10_items AS (
	SELECT item,
		SUM(quantity), 
		SUM(revenue) AS rev
	FROM retail_clean
	GROUP BY item
	ORDER BY 2 DESC
	LIMIT 10
)
SELECT 
	ROUND((
		SELECT SUM(rev) FROM top_10_items
	) / (
		SELECT SUM(revenue) FROM retail_clean
	) * 100, 2) AS "Top 10 item fraction"
;

-- Какой процент выручки приходится на клиентов, которые покупают повторно?
WITH customer_return AS (
	SELECT customer, 
		COUNT(DISTINCT invoice) AS orders,
		SUM(revenue) AS revenue_per_user,
		CASE 
			WHEN COUNT(DISTINCT invoice) = 1 THEN 'single'
			WHEN COUNT(DISTINCT invoice) > 1 THEN 'multiply'
		END AS type
	FROM retail_clean
	WHERE customer IS NOT NULL
	GROUP BY customer
	ORDER BY orders DESC
), grouped AS (
SELECT type, 
	COUNT(*) AS orders, 
	SUM(revenue_per_user) AS rev
FROM customer_return
GROUP BY type
)
SELECT ROUND(
		(
		SELECT orders 
		FROM grouped 
		WHERE type = 'multiply'
		) / (
		SELECT SUM(oviewrders) FROM grouped
		) * 100
		, 2) AS "Процент заказавших больше 1-го раза",
		ROUND((SELECT rev FROM grouped
		WHERE type = 'multiply')
		/ 
		(SELECT SUM(rev) FROM grouped)
		* 100, 2) AS "Доля выручки от клиентов, заказавших повторно"		
;

-- В каких странам больше всего возвратов
SELECT state, COUNT(*)
FROM retail_clean
WHERE type = 'returned'
GROUP BY state
ORDER BY 2 DESC
LIMIT 10;

SELECT state, COUNT(*)
FROM retail_clean
WHERE type = 'sold'
GROUP BY state
ORDER BY 2 DESC
LIMIT 10;
/*Страны с наибольшим количеством возвращенных товаров 
также являются лидерами по количеству купленных товаров*/


-- 18. Какие товары имеют высокий объём продаж, но одновременно высокий уровень возвратов?
WITH product_stats AS (
    SELECT
        item,
        SUM(CASE WHEN type = 'sold' THEN quantity ELSE 0 END) AS sold_quantity,
        SUM(CASE WHEN type = 'returned' THEN -quantity ELSE 0 END) AS returned_quantity
    FROM retail_clean
    GROUP BY item
)
SELECT
    item,
    sold_quantity,
    returned_quantity,
    ROUND(
        returned_quantity::numeric / NULLIF(sold_quantity, 0) * 100,
        2
    ) AS return_rate
FROM product_stats
WHERE sold_quantity > 100
  AND returned_quantity > 0
ORDER BY return_rate DESC;

-- Сумма выручки потерянная из-за возвратов
SELECT SUM(ABS(revenue)) FROM retail_clean
WHERE revenue < 0;

-- Были ли заказы где вернули все позиции?
WITH sold_return AS (
	SELECT invoice,
		SUM(CASE WHEN type = 'sold' THEN quantity ELSE 0 END) AS sold_items,
		SUM(CASE WHEN type = 'returned' THEN quantity ELSE 0 END) AS returned_items
	FROM retail_clean
	GROUP BY invoice
)
SELECT * FROM sold_return
WHERE sold_items = -returned_items;
-- Таких заказов не было

-- Посмотрим как менялась выручка по годам 
SELECT
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    SUM(CASE 
        WHEN type = 'sold' THEN revenue 
        ELSE 0 
    END) AS revenue,
    COUNT(DISTINCT CASE 
        WHEN type = 'sold' THEN invoice 
    END) AS orders
FROM retail_clean
GROUP BY
    EXTRACT(YEAR FROM date),
    EXTRACT(MONTH FROM date)
ORDER BY year, month;

-- Посмотрим есть ли сезонность
WITH yearly_revenue AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        SUM(CASE
            WHEN type = 'sold' THEN revenue
            ELSE 0
        END) AS revenue
    FROM retail_clean
    GROUP BY EXTRACT(YEAR FROM date)
)

SELECT
    year,
    revenue,
    LAG(revenue) OVER (ORDER BY year) AS previous_year_revenue,
    revenue - LAG(revenue) OVER (ORDER BY year) AS revenue_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY year))
        / NULLIF(LAG(revenue) OVER (ORDER BY year), 0) * 100,
        2
    ) AS growth_rate
FROM yearly_revenue
ORDER BY year;

-- Какой месяц является самым прибыльным в каждом году
WITH monthly_revenue AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        EXTRACT(MONTH FROM date) AS month,
        SUM(CASE
            WHEN type = 'sold' THEN revenue
            ELSE 0
        END) AS revenue
    FROM retail_clean
    GROUP BY
        EXTRACT(YEAR FROM date),
        EXTRACT(MONTH FROM date)
),

ranked_months AS (
    SELECT
        year,
        month,
        revenue,
        DENSE_RANK() OVER (
            PARTITION BY year
            ORDER BY revenue DESC
        ) AS rank
    FROM monthly_revenue
)

SELECT
    year,
    month,
    revenue
FROM ranked_months
WHERE rank = 1
ORDER BY year;

-- В какие дни недели совершается больше всего заказов
SELECT
    TO_CHAR(date, 'Day') AS day_of_week,
    COUNT(DISTINCT CASE
        WHEN type = 'sold' THEN invoice
    END) AS orders,
    SUM(CASE
        WHEN type = 'sold' THEN revenue
        ELSE 0
    END) AS revenue
FROM retail_clean
GROUP BY TO_CHAR(date, 'Day'), EXTRACT(DOW FROM date)
ORDER BY EXTRACT(DOW FROM date);