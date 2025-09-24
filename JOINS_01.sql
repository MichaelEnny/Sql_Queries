-- 1. List all customers, highlighting who placed orders and who didn't (Full Outer Join)

-- LEFT side: all customers with their orders (or no orders)
SELECT
    c.customer_id,
    c.customer_name,
    c.registration_date,
    c.region,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.order_value), 0) AS total_order_value,
    MAX(o.order_date) AS last_order_date,
    CASE
        WHEN o.customer_id IS NULL THEN 'Customer with no orders'
        ELSE 'Active customer'
    END AS customer_status
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.registration_date, c.region

UNION

-- RIGHT side: all orders that don’t have a customer record
SELECT
    o.customer_id,
    NULL AS customer_name,
    NULL AS registration_date,
    NULL AS region,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.order_value), 0) AS total_order_value,
    MAX(o.order_date) AS last_order_date,
    'Order without customer record' AS customer_status
FROM orders o
LEFT JOIN customers c
  ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
GROUP BY o.customer_id
ORDER BY customer_status, total_order_value DESC;

