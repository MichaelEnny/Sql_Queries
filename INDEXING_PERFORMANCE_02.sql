-- 2. Evaluate the effect of a composite index on query performance

-- Actual (executes the query & reports timing)
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS order_count,
    SUM(order_value) AS total_value,
    AVG(order_value) AS avg_value,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order
FROM orders
WHERE customer_id BETWEEN 1000 AND 2000
  AND order_date >= '2023-01-01'
  AND order_date <  '2024-01-01'
GROUP BY customer_id
ORDER BY customer_id;