/*
================================================================================
АНАЛИЗ ПРОДАЖ SUPERSTORE | SQL-ПРОЕКТ НА POSTGRESQL

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

/* ШАГ 4 — ОБЗОР ПО МЕСЯЦАМ
Бизнес-вопрос: как меняются показатели продаж от месяца к месяцу?
Цель: рассчитать выручку, прибыль, средние продажи, среднюю скидку,
число заказов и количество уникальных клиентов.
Как: используем SUM, AVG и COUNT(DISTINCT ...) и группируем данные по месяцу.
Важно: группировка только по номеру месяца объединяет одинаковые месяцы разных лет.
Для анализа по календарным месяцам лучше использовать DATE_TRUNC('month', order_date).
*/

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

/* ШАГ 5 — АНАЛИЗ СПОСОБОВ ДОСТАВКИ
Бизнес-вопрос: какой способ доставки связан с наибольшими выручкой и прибылью?
Цель: сравнить способы доставки по выручке, прибыли, средним продажам,
скидке, количеству заказов и уникальных клиентов.
Как: GROUP BY ship_mode формирует отдельную агрегированную строку для каждого способа доставки.
*/

SELECT ship_mode,
	ROUND(SUM(sales), 2) AS total,
	ROUND(SUM(profit), 2) AS sum_profit,
	ROUND(AVG(sales), 2) AS avg_total,
	ROUND(AVG(discount), 4) AS avg_discount,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT customer_id) AS unique_customers
FROM superstore
GROUP BY ship_mode;

/* ШАГ 6 — АНАЛИЗ КЛИЕНТСКИХ СЕГМЕНТОВ
Бизнес-вопрос: какой клиентский сегмент приносит наибольший вклад в бизнес?
Цель: сравнить сегменты по ключевым финансовым и операционным показателям.
Как: группируем данные по segment и рассчитываем выручку, прибыль, скидку,
число заказов и клиентов.
*/

SELECT segment,
	ROUND(SUM(sales), 2) AS total,
	ROUND(SUM(profit), 2) AS sum_profit,
	ROUND(AVG(sales), 2) AS avg_total,
	ROUND(AVG(discount), 4) AS avg_discount,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT customer_id) AS unique_customers
FROM superstore
GROUP BY segment;

/* ШАГ 7 — ЭФФЕКТИВНОСТЬ КАТЕГОРИЙ
Бизнес-вопрос: какие товарные категории являются основными драйверами бизнеса?
Цель: сравнить категории по выручке, прибыли, среднему размеру продажи,
скидке, заказам и клиентам.
Как: группируем данные по category и рассчитываем агрегированные KPI.
*/

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

/* ШАГ 9 — ЭФФЕКТИВНОСТЬ ПОДКАТЕГОРИЙ
Бизнес-вопрос: какие подкатегории продаются лучше всего и дают больше прибыли?
Цель: сравнить выручку, прибыль, количество проданных единиц и заказы.
Как: группируем данные по sub_category и сортируем по прибыли по убыванию.
*/

SELECT
    sub_category,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT order_id) AS orders
FROM superstore
GROUP BY sub_category
ORDER BY profit DESC;

/* ШАГ 10 — ПОДКАТЕГОРИИ С НИЗКОЙ ПРИБЫЛЬЮ
Бизнес-вопрос: где находятся самые слабые зоны прибыльности?
Цель: найти 10 подкатегорий с наименьшей прибылью и проверить их маржинальность.
Как: агрегируем показатели по подкатегории, считаем маржу и оставляем
10 строк с минимальной прибылью.
*/

SELECT
    sub_category,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY sub_category
ORDER BY profit ASC
LIMIT 10;

/* ШАГ 11 — РЕГИОНАЛЬНАЯ ЭФФЕКТИВНОСТЬ
Бизнес-вопрос: какие регионы дают наибольшую выручку и прибыль?
Цель: сравнить регионы по выручке, прибыли и маржинальности.
Как: группируем данные по region и рассчитываем основные показатели прибыльности.
*/

SELECT
    region,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY region
ORDER BY revenue DESC;

/* ШАГ 12 — РАНЖИРОВАНИЕ РЕГИОНОВ
Бизнес-вопрос: как ранжировать все регионы по прибыли, не оставляя только одного победителя?
Цель: присвоить каждому региону место в рейтинге по прибыли.
Как: RANK() OVER (ORDER BY SUM(profit) DESC) ранжирует регионы после агрегации.
В отличие от LIMIT, этот подход сохраняет все регионы.
*/

SELECT
    region,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
FROM superstore
GROUP BY region
ORDER BY profit_rank;

/* ШАГ 13 — РАНЖИРОВАНИЕ ПОДКАТЕГОРИЙ ВНУТРИ РЕГИОНА
Бизнес-вопрос: какие подкатегории лучше всего работают в каждом регионе?
Цель: построить отдельный рейтинг внутри каждого региона.
Как: сначала агрегируем прибыль по region и sub_category в CTE,
затем RANK() с PARTITION BY region создаёт независимый рейтинг для каждого региона.
*/

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

/* ШАГ 14 — ТОП-КЛИЕНТЫ ПО ВЫРУЧКЕ
Бизнес-вопрос: какие клиенты приносят больше всего выручки?
Цель: найти 10 крупнейших клиентов.
Как: агрегируем выручку, прибыль и количество заказов по клиенту,
сортируем по выручке и оставляем первые 10 строк.
*/

SELECT
    customer_name,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    COUNT(DISTINCT order_id) AS orders
FROM superstore
GROUP BY customer_name
ORDER BY revenue DESC
LIMIT 10;

/* ШАГ 15 — РАНЖИРОВАНИЕ КЛИЕНТОВ ВНУТРИ СЕГМЕНТОВ
Бизнес-вопрос: кто является лидером среди клиентов каждого сегмента?
Цель: ранжировать клиентов по выручке отдельно внутри каждого segment.
Как: CTE формирует клиентские показатели, а ROW_NUMBER() с PARTITION BY
создаёт независимый рейтинг внутри каждого сегмента.
*/

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

/* ШАГ 16 — ПОМЕСЯЧНЫЙ РОСТ ВЫРУЧКИ
Бизнес-вопрос: растёт или снижается выручка относительно предыдущего месяца?
Цель: получить выручку, прибыль, показатель прошлого месяца и процент роста.
Как: DATE_TRUNC формирует месяцы, LAG() возвращает значение предыдущего месяца,
а разница делится на предыдущую выручку.
*/

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

/* ШАГ 17 — НАКОПИТЕЛЬНЫЕ ПОКАЗАТЕЛИ
Бизнес-вопрос: сколько выручки и прибыли накоплено к каждому месяцу?
Цель: рассчитать накопительные итоги по времени.
Как: SUM(...) OVER (ORDER BY month) добавляет текущий месяц ко всем предыдущим,
сохраняя при этом отдельную строку для каждого месяца.
*/

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

/* ШАГ 18 — АНАЛИЗ УРОВНЕЙ СКИДКИ
Бизнес-вопрос: как меняются выручка, прибыль и объём продаж при разных скидках?
Цель: сравнить финансовые результаты на каждом уровне discount.
Как: группируем данные по discount и рассчитываем выручку, прибыль,
количество единиц и число транзакций.
*/

SELECT
    discount,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    SUM(quantity) AS units_sold,
    COUNT(*) AS transactions
FROM superstore
GROUP BY discount
ORDER BY discount;

/* ШАГ 19 — ВЛИЯНИЕ СКИДКИ НА ПРИБЫЛЬНОСТЬ
Бизнес-вопрос: связаны ли более высокие скидки с более низкой маржой?
Цель: оценить выручку, прибыль и маржинальность на каждом уровне скидки.
Как: агрегируем показатели по discount и рассчитываем прибыль / выручка × 100.
*/

SELECT
    discount,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY discount
ORDER BY discount;

/* ШАГ 20 — ТОП-5 ТОВАРОВ ПО ПРИБЫЛИ ВНУТРИ КАТЕГОРИИ
Бизнес-вопрос: какие товары являются самыми прибыльными в каждой категории?
Цель: найти пять лидеров внутри каждой категории.
Как: сначала агрегируем показатели на уровне товара, затем ROW_NUMBER()
с PARTITION BY category присваивает каждому товару место в своей категории.
*/

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

/* ШАГ 21 — ТОВАРЫ С НАИМЕНЬШЕЙ ПРИБЫЛЬЮ
Бизнес-вопрос: какие отдельные товары дают минимальную прибыль или убыток?
Цель: найти 10 самых слабых товаров и посмотреть их маржу и объём продаж.
Как: агрегируем показатели по товару и сортируем прибыль по возрастанию.
*/

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

/* ШАГ 22 — КВАРТИЛИ КЛИЕНТОВ ПО ВЫРУЧКЕ
Бизнес-вопрос: как разделить клиентов на четыре группы по объёму выручки?
Цель: присвоить каждому клиенту квартиль.
Как: NTILE(4) сортирует клиентов по выручке от максимальной к минимальной
и делит их на четыре примерно равные по размеру группы.
*/

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

/* ШАГ 23 — ЦЕННОСТЬ КЛИЕНТСКИХ КВАРТИЛЕЙ
Бизнес-вопрос: сколько выручки и прибыли приходится на каждый квартиль?
Цель: сравнить финансовую ценность четырёх групп клиентов.
Как: сначала рассчитываем квартиль для каждого клиента, затем группируем
клиентов по нему и суммируем выручку и прибыль.
*/

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

/* ШАГ 24 — СРЕДНИЙ ЧЕК ЗАКАЗА (AOV)
Бизнес-вопрос: сколько выручки в среднем приносит один заказ?
Цель: получить базовый AOV для всего бизнеса.
Формула: AOV = общая выручка / количество уникальных заказов.
Как: SUM(sales) считает выручку, а COUNT(DISTINCT order_id) не даёт
ошибочно считать отдельные строки товаров отдельными заказами.
*/

SELECT
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM superstore;

/* ШАГ 25 — AOV ПО КЛИЕНТСКИМ СЕГМЕНТАМ
Бизнес-вопрос: какой сегмент совершает наиболее дорогие заказы?
Цель: сравнить средний чек между сегментами.
Как: группируем данные по segment и отдельно рассчитываем AOV для каждой группы.
*/

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

/* ШАГ 26 — ЧАСТОТА ЗАКАЗОВ КЛИЕНТОВ
Бизнес-вопрос: какие клиенты заказывают чаще всего?
Цель: найти клиентов с наибольшим количеством уникальных заказов.
Как: COUNT(DISTINCT order_id) измеряет частоту покупок, а выручка и прибыль
дают дополнительный контекст.
*/

SELECT
    customer_id,
    customer_name,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    SUM(profit) AS profit
FROM superstore
GROUP BY customer_id, customer_name
ORDER BY orders DESC;

/* ШАГ 27 — РАСПРЕДЕЛЕНИЕ КЛИЕНТОВ ПО ЧИСЛУ ЗАКАЗОВ
Бизнес-вопрос: как отличается выручка клиентов в зависимости от частоты покупок?
Цель: показать число клиентов с 1, 2, 3 и более заказами и их среднюю выручку.
Как: сначала создаём одну строку на клиента, затем группируем клиентов
по количеству заказов.
*/

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

/* ШАГ 28 — ПРИБЫЛЬНОСТЬ СПОСОБОВ ДОСТАВКИ
Бизнес-вопрос: связан ли высокий объём выручки со здоровой маржинальностью?
Цель: сравнить заказы, выручку, прибыль и маржу по способам доставки.
Как: агрегируем все финансовые показатели на уровне ship_mode.
*/

SELECT
    ship_mode,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin
FROM superstore
GROUP BY ship_mode
ORDER BY revenue DESC;

/* ШАГ 29 — СРЕДНИЙ ЧЕК ПО СПОСОБУ ДОСТАВКИ
Бизнес-вопрос: с каким способом доставки связан самый высокий AOV?
Цель: сравнить средний чек и прибыль по способам доставки.
Как: делим общую выручку каждой группы на количество уникальных заказов.
*/

SELECT
    ship_mode,
    COUNT(DISTINCT order_id) AS orders,
    SUM(sales) AS revenue,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    SUM(profit) AS profit
FROM superstore
GROUP BY ship_mode
ORDER BY avg_order_value DESC;

/* ШАГ 30 — РАНЖИРОВАНИЕ КАТЕГОРИЙ ВНУТРИ РЕГИОНОВ
Бизнес-вопрос: меняется ли лучшая категория от региона к региону?
Цель: отдельно ранжировать категории внутри каждого региона.
Как: сначала агрегируем данные по region и category, затем применяем
RANK() с PARTITION BY region.
*/

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

/* ШАГ 31 — ABC-АНАЛИЗ ТОВАРОВ
Бизнес-вопрос: какие товары формируют основную часть общей выручки?
Цель: разделить товары на A, B и C по накопительной доле выручки:
A — первые 80%, B — следующие 15%, C — оставшиеся 5%.
Как: агрегируем выручку по товару, рассчитываем накопительную сумму
оконной функцией, делим её на общую выручку и присваиваем класс через CASE.
Бизнес-смысл: анализ помогает определить товары, которым стоит уделять
приоритетное внимание в запасах, продажах и ассортименте.
*/

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

/* ШАГ 32 — ПОВТОРНЫЕ И РАЗОВЫЕ КЛИЕНТЫ
Бизнес-вопрос: какая часть клиентов совершила больше одной покупки?
Цель: разделить клиентов на разовых и повторных.
Как: в CTE считаем количество заказов по каждому клиенту и классифицируем
его с помощью CASE.
*/

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

/* ШАГ 33 — ДОЛЯ ПОВТОРНЫХ КЛИЕНТОВ
Бизнес-вопрос: какой процент клиентов возвращается и делает повторные заказы?
Цель: превратить предыдущую сегментацию в один KPI.
Формула: повторные клиенты / все клиенты × 100.
Как: FILTER учитывает только клиентов, у которых больше одного заказа.
*/

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

/* ШАГ 34 — ДИАПАЗОНЫ СКИДОК
Бизнес-вопрос: отличается ли прибыльность при низких, средних и высоких скидках?
Цель: объединить отдельные значения скидки в понятные бизнес-диапазоны.
Как: CASE распределяет значения discount по диапазонам, после чего
для каждого диапазона считаются выручка, прибыль и маржа.
*/

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

/* ШАГ 35 — ИЗМЕНЕНИЕ ПРИБЫЛИ ПРИ РОСТЕ СКИДКИ
Бизнес-вопрос: как меняется прибыль при переходе от одного уровня скидки к другому?
Цель: сравнить каждый уровень скидки с предыдущим наблюдаемым уровнем.
Как: сначала агрегируем прибыль по discount, затем LAG() получает предыдущую
прибыль, после чего вычисляем разницу.
*/

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

/* ШАГ 36 — КОГОРТЫ ПО ГОДУ ПЕРВОЙ ПОКУПКИ
Бизнес-вопрос: в каком году существующие клиенты впервые сделали заказ?
Цель: посчитать количество клиентов по году их первой покупки.
Как: MIN(order_date) находит дату первой покупки каждого клиента,
после чего группировка по году формирует когорты привлечения.
*/

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

/* ШАГ 37 — ВЫРУЧКА И ПРИБЫЛЬ КОГОРТ
Бизнес-вопрос: какую выручку и прибыль в рамках датасета приносит каждая когорта?
Цель: сравнить клиентов по году их первой покупки.
Как: формируем cohort_year по первой покупке, присоединяем его ко всем
транзакциям клиента и агрегируем выручку, прибыль и заказы.
Важно: это анализ общей эффективности когорт, а не полноценный анализ удержания.
Для retention нужно отдельно измерять возврат клиентов в последующие периоды.
*/

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

/* ШАГ 38 — ДОЛЯ КАТЕГОРИИ В ОБЩЕЙ ВЫРУЧКЕ
Бизнес-вопрос: какой процент общей выручки приходится на каждую категорию?
Цель: понять структуру общей выручки.
Как: сначала считаем выручку по категориям, затем SUM(revenue) OVER ()
получает общую выручку. Это позволяет вычислить долю каждой категории,
не теряя строки на уровне категорий.
*/

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


























/*
================================================================================
ИТОГИ ПРОЕКТА / СЛЕДУЮЩИЕ ШАГИ
================================================================================

Скрипт уже покрывает:
- загрузку и первичную проверку данных;
- анализ базовых KPI;
- выручку, прибыль и маржинальность;
- анализ клиентов и сегментов;
- AOV и частоту заказов;
- ранжирование с помощью RANK(), ROW_NUMBER() и NTILE();
- временной анализ с LAG() и накопительными итогами;
- анализ скидок;
- ABC-сегментацию товаров;
- клиентские когорты и структуру выручки.

Чтобы проект выглядел сильнее на GitHub, следующим слоем стоит добавить README с:
1. Описанием бизнес-задачи и датасета.
2. Предположениями о качестве данных и решениями по очистке.
3. Ключевыми выводами с цифрами и графиками.
4. Бизнес-рекомендациями.
5. Инструкцией по локальному запуску SQL.

Рекомендуемые технические улучшения перед публикацией:
- переименовать `region` в `region`;
- использовать десятичный тип для `discount`, если источник содержит дробные значения;
- заменить локальный путь в COPY на документированный переносимый способ загрузки;
- добавить явные проверки NULL, дубликатов и диапазонов значений;
- использовать DATE_TRUNC('month', order_date) при сравнении нескольких лет;
- защищать расчёты отношений с помощью NULLIF(sales, 0) в production-версии.

================================================================================
*/
