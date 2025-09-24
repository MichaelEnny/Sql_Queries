-- 3. Match orders with customers and display unmatched orders as well (Left Join)

SELECT
    o.order_id,
    o.order_date,
    o.order_value,
    o.customer_id,
    COALESCE(c.customer_name, 'CUSTOMER NOT FOUND') as customer_name,
    c.region,
    c.registration_date,
    -- Data quality indicators
    CASE
        WHEN c.customer_id IS NULL THEN 'ORPHANED ORDER'
        WHEN c.registration_date > o.order_date THEN 'DATA INCONSISTENCY'
        ELSE 'VALID ORDER'
    END as order_status,
    -- Customer metrics
    CASE
        WHEN c.customer_id IS NOT NULL THEN
            DATEDIFF(o.order_date, c.registration_date)  -- Days since registration
        ELSE NULL
    END as days_since_registration
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
ORDER BY
    CASE WHEN c.customer_id IS NULL THEN 0 ELSE 1 END,  -- Orphaned orders first
    o.order_date DESC;

-- Summary of unmatched orders:
WITH order_analysis AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_value,
        c.customer_name,
        CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END as is_orphaned
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.customer_id
)
SELECT
    COUNT(*) as total_orders,
    SUM(is_orphaned) as orphaned_orders,
    ROUND((SUM(is_orphaned) * 100.0 / COUNT(*)), 2) as orphaned_percentage,
    SUM(CASE WHEN is_orphaned = 1 THEN order_value ELSE 0 END) as orphaned_order_value
FROM order_analysis;
