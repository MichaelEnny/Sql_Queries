-- 4. Compare query execution times before and after implementing a clustered index

EXPLAIN
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY order_date;


EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY order_date;
