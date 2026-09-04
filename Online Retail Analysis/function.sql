CREATE OR REPLACE FUNCTION get_user_stats(p_customer_id NUMERIC)
RETURNS TABLE (
	customer_id NUMERIC,
	orders BIGINT,
	total_revenue NUMERIC,
	avg_order_value NUMERIC
)
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		customer,
		COUNT(*) AS orders,
		ROUND(SUM(revenue), 2),
        ROUND(AVG(revenue), 2)
	FROM single_order
	WHERE customer = p_customer_id
	GROUP BY customer;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_item_stats(p_stock_code VARCHAR)
RETURNS TABLE (
    item VARCHAR,
    sold_quantity BIGINT,
    returned_quantity BIGINT,
    revenue NUMERIC,
    revenue_rate NUMERIC
)
AS $$
BEGIN 
    RETURN QUERY
    SELECT 
        r.item,
        SUM(CASE WHEN type = 'sold' THEN r.quantity ELSE 0 END),
        SUM(CASE WHEN type = 'returned' THEN -r.quantity ELSE 0 END),
        ROUND(SUM(r.revenue), 2),
        ROUND(
            SUM(CASE WHEN type = 'returned' THEN -r.quantity ELSE 0 END)::NUMERIC
            / NULLIF(SUM(CASE WHEN type = 'sold' THEN r.quantity ELSE 0 END), 0)
            * 100,
            2
        )
    FROM retail_clean r
    WHERE r.item = p_stock_code
    GROUP BY r.item;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_item_stats('85110');