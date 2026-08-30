-- АНАЛИЗ ПРОДАЖ SUPERSTORE | SQL-ПРОЕКТ НА POSTGRESQL

-- ШАГ 1 — СОЗДАНИЕ СТРУКТУРЫ ТАБЛИЦЫ

CREATE TABLE superstore (
	row_id INTEGER,
	order_id TEXT,
	order_date TIMESTAMP WITHOUT TIME ZONE,
	ship_date TIMESTAMP WITHOUT TIME ZONE,
	ship_mode TEXT,
	customer_id TEXT,
	customer_name TEXT,
	segment TEXT,
	country TEXT,
	city TEXT, state TEXT, 
	postal_code BIGINT, 
	region TEXT, 
	product_id TEXT,
	category TEXT, 
	sub_category TEXT,
	product_name TEXT,
	sales NUMERIC,
	quantity INTEGER,
	discount INTEGER, 
	profit NUMERIC
);

-- ШАГ 2 — ЗАГРУЗКА ДАННЫХ

COPY superstore
FROM 'C:\Superstore.csv'
WITH (
	FORMAT csv,
	HEADER TRUE,
	DELIMITER ',',
	ENCODING 'WIN1252'
);

-- ШАГ 3 — ПЕРВИЧНАЯ ПРОВЕРКА ДАННЫХ

SELECT * FROM superstore;

/* Как меняются показатели продаж от месяца к месяцу? */

SELECT TO_CHAR(order_date, 'MM') AS month,
	ROUND(SUM(sales), 2) AS total,
	ROUND(SUM(profit), 2) AS sum_profit,
	ROUND(AVG(sales), 2) AS avg_total,
	ROUND(AVG(discount), 4) AS avg_discount,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT customer_id) AS unique_customers
FROM superstore
GROUP BY TO_CHAR(order_date, 'MM') 
ORDER BY month ASC;

/* Какой способ доставки связан с наибольшими выручкой и прибылью? */

SELECT ship_mode,
	ROUND(SUM(sales), 2) AS total,
	ROUND(SUM(profit), 2) AS sum_profit,
	ROUND(AVG(sales), 2) AS avg_total,
	ROUND(AVG(discount), 4) AS avg_discount,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT customer_id) AS unique_customers
FROM superstore
GROUP BY ship_mode;

/* Какой клиентский сегмент приносит наибольший вклад в бизнес? */

SELECT segment,
	ROUND(SUM(sales), 2) AS total,
	ROUND(SUM(profit), 2) AS sum_profit,
	ROUND(AVG(sales), 2) AS avg_total,
	ROUND(AVG(discount), 4) AS avg_discount,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT customer_id) AS unique_customers
FROM superstore
GROUP BY segment;

/* Какие товарные категории являются основными драйверами бизнеса? */

SELECT category,
	ROUND(SUM(sales), 2) AS total,
	ROUND(SUM(profit), 2) AS sum_profit,
	ROUND(AVG(sales), 2) AS avg_total,
	ROUND(AVG(discount), 4) AS avg_discount,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT customer_id) AS unique_customers
FROM superstore
GROUP BY category;

SELECT category,
	ROUND(SUM(sales), 2) AS total,
	ROUND(SUM(profit), 2) AS sum_profit,
	ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY category;

/* Какие подкатегории продаются лучше всего и дают больше прибыли? */

SELECT
    sub_category,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT order_id) AS orders
FROM superstore
GROUP BY sub_category
ORDER BY profit DESC;

/* Где находятся самые слабые зоны прибыльности? */

SELECT
    sub_category,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY sub_category
ORDER BY profit ASC
LIMIT 10;

/* Какие регионы дают наибольшую выручку и прибыль? */

SELECT
    region,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY region
ORDER BY revenue DESC;

/* Как ранжировать все регионы по прибыли, не оставляя только одного победителя? */

SELECT
    region,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
FROM superstore
GROUP BY region
ORDER BY profit_rank;

/* Какие подкатегории лучше всего работают в каждом регионе? */

WITH subcategory_profit AS (
    SELECT
        region,
        sub_category,
        SUM(profit) AS profit
    FROM superstore
    GROUP BY region, sub_category
)

SELECT
    region,
    sub_category,
    profit,
    RANK() OVER (
        PARTITION BY region
        ORDER BY profit DESC
    ) AS rank_in_region
FROM subcategory_profit
ORDER BY region, rank_in_region;

/* какие клиенты приносят больше всего выручки? */

SELECT
    customer_name,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    COUNT(DISTINCT order_id) AS orders
FROM superstore
GROUP BY customer_name
ORDER BY revenue DESC
LIMIT 10;

/* кто является лидером среди клиентов каждого сегмента? */

WITH customer_stats AS (
    SELECT
        segment,
        customer_name,
        SUM(sales) AS revenue,
        SUM(profit) AS profit
    FROM superstore
    GROUP BY segment, customer_name
)

SELECT
    segment,
    customer_name,
    revenue,
    profit,
    ROW_NUMBER() OVER (
        PARTITION BY segment
        ORDER BY revenue DESC
    ) AS customer_rank
FROM customer_stats
ORDER BY segment, customer_rank;

/* растёт или снижается выручка относительно предыдущего месяца? */

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS revenue,
        SUM(profit) AS profit
    FROM superstore
    GROUP BY month
)

SELECT
    month,
    revenue,
    profit,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) AS revenue_growth_pct
FROM monthly
ORDER BY month;

/* сколько выручки и прибыли накоплено к каждому месяцу? */

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS revenue,
        SUM(profit) AS profit
    FROM superstore
    GROUP BY month
)

SELECT
    month,
    revenue,
    profit,
    SUM(revenue) OVER (
        ORDER BY month
    ) AS cumulative_revenue,
    SUM(profit) OVER (
        ORDER BY month
    ) AS cumulative_profit
FROM monthly
ORDER BY month;

/* как меняются выручка, прибыль и объём продаж при разных скидках? */

SELECT
    discount,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    SUM(quantity) AS units_sold,
    COUNT(*) AS transactions
FROM superstore
GROUP BY discount
ORDER BY discount;

/* связаны ли более высокие скидки с более низкой маржой? */

SELECT
    discount,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY discount
ORDER BY discount;

/* какие товары являются самыми прибыльными в каждой категории? */

WITH product_stats AS (
    SELECT
        category,
        product_name,
        SUM(sales) AS revenue,
        SUM(profit) AS profit
    FROM superstore
    GROUP BY category, product_name
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY profit DESC
        ) AS rank
    FROM product_stats
)

SELECT *
FROM ranked
WHERE rank <= 5
ORDER BY category, rank;

/* какие отдельные товары дают минимальную прибыль или убыток? */

SELECT
    product_name,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    SUM(quantity) AS units_sold,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY product_name
ORDER BY profit
LIMIT 10;

/* как разделить клиентов на четыре группы по объёму выручки? */

WITH customer_stats AS (
    SELECT
        customer_id,
        customer_name,
        SUM(sales) AS revenue,
        SUM(profit) AS profit,
        COUNT(DISTINCT order_id) AS orders
    FROM superstore
    GROUP BY customer_id, customer_name
)

SELECT
    customer_name,
    revenue,
    profit,
    orders,
    NTILE(4) OVER (
        ORDER BY revenue DESC
    ) AS customer_quartile
FROM customer_stats
ORDER BY revenue DESC;

/* сколько выручки и прибыли приходится на каждый квартиль? */

WITH customer_stats AS (
    SELECT
        customer_id,
        SUM(sales) AS revenue,
        SUM(profit) AS profit,
        NTILE(4) OVER (ORDER BY SUM(sales) DESC) AS quartile
    FROM superstore
    GROUP BY customer_id
)

SELECT
    quartile,
    COUNT(*) AS customers,
    SUM(revenue) AS revenue,
    SUM(profit) AS profit
FROM customer_stats
GROUP BY quartile
ORDER BY quartile;

/* сколько выручки в среднем приносит один заказ? */

SELECT
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM superstore;

/* какой сегмент совершает наиболее дорогие заказы? */

SELECT
    segment,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    ROUND(
        SUM(sales) / COUNT(DISTINCT order_id),
        2
    ) AS avg_order_value
FROM superstore
GROUP BY segment
ORDER BY avg_order_value DESC;

/* какие клиенты заказывают чаще всего? */

SELECT
    customer_id,
    customer_name,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    SUM(profit) AS profit
FROM superstore
GROUP BY customer_id, customer_name
ORDER BY orders DESC;

/* как отличается выручка клиентов в зависимости от частоты покупок? */

WITH customer_orders AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(DISTINCT order_id) AS orders,
        SUM(sales) AS revenue
    FROM superstore
    GROUP BY customer_id, customer_name
)

SELECT
    orders,
    COUNT(*) AS customers,
    ROUND(AVG(revenue), 2) AS avg_revenue
FROM customer_orders
GROUP BY orders
ORDER BY orders;

/* связан ли высокий объём выручки со здоровой маржинальностью? */

SELECT
    ship_mode,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY ship_mode
ORDER BY revenue DESC;

/* с каким способом доставки связан самый высокий AOV? */

SELECT
    ship_mode,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    SUM(profit) AS profit
FROM superstore
GROUP BY ship_mode
ORDER BY avg_order_value DESC;

/* меняется ли лучшая категория от региона к региону? */

WITH region_category AS (
    SELECT
        region,
        category,
        SUM(sales) AS revenue,
        SUM(profit) AS profit
    FROM superstore
    GROUP BY region, category
)

SELECT
    region,
    category,
    revenue,
    profit,
    RANK() OVER (
        PARTITION BY region
        ORDER BY profit DESC
    ) AS category_rank
FROM region_category
ORDER BY region, category_rank;

/* какие товары формируют основную часть общей выручки? */

WITH product_sales AS (
    SELECT
        product_name,
        SUM(sales) AS revenue
    FROM superstore
    GROUP BY product_name
),
abc AS (
    SELECT
        product_name,
        revenue,
        SUM(revenue) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM product_sales
)

SELECT
    product_name,
    revenue,
    ROUND(cumulative_revenue / total_revenue * 100, 2) AS cumulative_revenue_pct,
    CASE
        WHEN cumulative_revenue / total_revenue <= 0.80 THEN 'A'
        WHEN cumulative_revenue / total_revenue <= 0.95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM abc
ORDER BY revenue DESC;

/* Какая часть клиентов совершила больше одной покупки? */

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS orders
    FROM superstore
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN orders = 1 THEN '1 order'
        ELSE '2+ orders'
    END AS customer_type,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY
    CASE
        WHEN orders = 1 THEN '1 order'
        ELSE '2+ orders'
    END;

/* Какой процент клиентов возвращается и делает повторные заказы? */

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS orders
    FROM superstore
    GROUP BY customer_id
)

SELECT
    ROUND(
        COUNT(*) FILTER (WHERE orders > 1) * 100.0
        / COUNT(*),
        2
    ) AS repeat_customer_pct
FROM customer_orders;

/* Отличается ли прибыльность при низких, средних и высоких скидках? */

SELECT
    CASE
        WHEN discount = 0 THEN '0%'
        WHEN discount <= 0.10 THEN '1-10%'
        WHEN discount <= 0.20 THEN '11-20%'
        WHEN discount <= 0.30 THEN '21-30%'
        WHEN discount <= 0.40 THEN '31-40%'
        ELSE '40%+'
    END AS discount_range,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY discount_range
ORDER BY MIN(discount);

/* Как меняется прибыль при переходе от одного уровня скидки к другому? */

WITH discount_stats AS (
    SELECT
        discount,
        SUM(sales) AS revenue,
        SUM(profit) AS profit
    FROM superstore
    GROUP BY discount
)

SELECT
    discount,
    revenue,
    profit,
    LAG(profit) OVER (ORDER BY discount) AS previous_discount_profit,
    profit - LAG(profit) OVER (ORDER BY discount) AS profit_change
FROM discount_stats
ORDER BY discount;

/* В каком году существующие клиенты впервые сделали заказ? */

WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM superstore
    GROUP BY customer_id
)

SELECT
    EXTRACT(YEAR FROM first_order_date) AS cohort_year,
    COUNT(*) AS customers
FROM first_orders
GROUP BY cohort_year
ORDER BY cohort_year;

/* Какую выручку и прибыль в рамках датасета приносит каждая когорта? */

WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM superstore
    GROUP BY customer_id
),
customer_cohorts AS (
    SELECT
        customer_id,
        EXTRACT(YEAR FROM first_order_date) AS cohort_year
    FROM first_orders
)

SELECT
    cc.cohort_year,
    SUM(s.sales) AS revenue,
    SUM(s.profit) AS profit,
    COUNT(DISTINCT s.order_id) AS orders
FROM customer_cohorts cc
JOIN superstore s
    ON cc.customer_id = s.customer_id
GROUP BY cc.cohort_year
ORDER BY cc.cohort_year;

/* Какой процент общей выручки приходится на каждую категорию? */

WITH category_sales AS (
    SELECT
        category,
        SUM(sales) AS revenue
    FROM superstore
    GROUP BY category
)

SELECT
    category,
    revenue,
    ROUND(
        revenue / SUM(revenue) OVER () * 100,
        2
    ) AS revenue_share_pct
FROM category_sales
ORDER BY revenue DESC;
