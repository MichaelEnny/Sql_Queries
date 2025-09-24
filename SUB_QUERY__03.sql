-- 3. Identify products ordered more than 10 times using a subquery

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    product_stats.order_count,
    product_stats.total_revenue,
    product_stats.avg_order_value,
    product_stats.first_order_date,
    product_stats.last_order_date
FROM products p
JOIN (
    SELECT
        product_id,
        COUNT(*) AS order_count,
        SUM(order_value) AS total_revenue,
        AVG(order_value) AS avg_order_value,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY product_id
    HAVING COUNT(*) > 10
) AS product_stats
  ON p.product_id = product_stats.product_id
ORDER BY product_stats.order_count DESC
LIMIT 0, 1000;
