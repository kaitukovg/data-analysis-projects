CREATE OR REPLACE VIEW pizza_table AS (
	SELECT o.order_id,
        EXTRACT(month FROM o.date) AS month,
        EXTRACT(hour FROM o."time") AS hour,
        od.quantity,
        p.pizza_id,
        pt.name,
        pt.category,
        p.size,
        p.price,
        p.price * od.quantity::double precision AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON p.pizza_id = od.pizza_id
    JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
    ORDER BY o.order_id
);
SELECT * FROM pizza_table;
