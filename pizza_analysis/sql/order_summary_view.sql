CREATE OR REPLACE VIEW order_summary AS(
    SELECT order_id,
        month,
        hour,
        sum(quantity) AS total_pizzas,
        count(DISTINCT pizza_id) AS pizza_types,
        sum(revenue) AS total
    FROM pizza_table
    GROUP BY order_id, month, hour
    ORDER BY order_id
);
SELECT * FROM order_summary;
