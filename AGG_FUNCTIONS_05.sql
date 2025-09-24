SELECT
  c.customer_id,
  c.customer_name,
  c.region,
  c.registration_date,

  COALESCE(cm.order_count, 0)            AS total_orders,
  COALESCE(cm.total_order_value, 0)      AS total_spent,
  COALESCE(cm.avg_order_value, 0)        AS avg_order_value,
  cm.min_order_value,
  cm.max_order_value,
  cm.first_order_date,
  cm.last_order_date,

  -- Customer lifecycle analysis
  CASE
    WHEN cm.order_count IS NULL THEN 'No Orders'
    WHEN cm.order_count = 1     THEN 'Single Purchase'
    WHEN cm.order_count <= 5    THEN 'Occasional'
    WHEN cm.order_count <= 15   THEN 'Regular'
    ELSE 'Frequent'
  END AS customer_segment,

  -- Time-based metrics (difference in days)
  CASE
    WHEN cm.first_order_date IS NOT NULL
    THEN DATEDIFF(cm.last_order_date, cm.first_order_date)
    ELSE NULL
  END AS customer_lifespan_days,

  -- Value-based ranking (requires MySQL 8.0)
  RANK() OVER (ORDER BY cm.avg_order_value  DESC) AS avg_order_value_rank,
  RANK() OVER (ORDER BY cm.total_order_value DESC) AS total_value_rank

FROM customers AS c
LEFT JOIN (
  SELECT
    customer_id,
    COUNT(*)        AS order_count,
    SUM(order_value) AS total_order_value,
    AVG(order_value) AS avg_order_value,
    MIN(order_value) AS min_order_value,
    MAX(order_value) AS max_order_value,
    MIN(order_date)  AS first_order_date,
    MAX(order_date)  AS last_order_date,
    STDDEV(order_value) AS order_value_stddev
  FROM orders
  GROUP BY customer_id
) AS cm
  ON cm.customer_id = c.customer_id

-- Emulate NULLS LAST in MySQL
ORDER BY
  (cm.avg_order_value IS NULL),          -- false(0) first, true(1) last
  cm.avg_order_value DESC;