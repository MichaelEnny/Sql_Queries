-- 3. Count the number of unique customers for each product

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    COUNT(o.order_id) as total_orders,
    SUM(o.order_value) as total_revenue,
    AVG(o.order_value) as avg_order_value,
    MIN(o.order_date) as first_order_date,
    MAX(o.order_date) as last_order_date,
    -- Customer penetration metrics
    ROUND(
        COUNT(DISTINCT o.customer_id) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id) FROM orders),
        2
    ) as customer_penetration_pct,
    -- Repeat customer analysis
    ROUND(
        COUNT(o.order_id) * 1.0 / COUNT(DISTINCT o.customer_id),
        2
    ) as avg_orders_per_customer
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name, p.category, p.price
ORDER BY unique_customers DESC, total_revenue DESC;

-- Advanced analysis with customer segmentation:
WITH product_customer_analysis AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        COUNT(o.order_id) as total_orders,
        SUM(o.order_value) as total_revenue,
        -- Customer value segmentation
        COUNT(DISTINCT CASE WHEN customer_totals.customer_value > 1000 THEN o.customer_id END) as high_value_customers,
        COUNT(DISTINCT CASE WHEN customer_totals.customer_value BETWEEN 500 AND 1000 THEN o.customer_id END) as medium_value_customers,
        COUNT(DISTINCT CASE WHEN customer_totals.customer_value < 500 THEN o.customer_id END) as low_value_customers
    FROM products p
    LEFT JOIN orders o ON p.product_id = o.product_id
    LEFT JOIN (
        SELECT
            customer_id,
            SUM(order_value) as customer_value
        FROM orders
        GROUP BY customer_id
    ) customer_totals ON o.customer_id = customer_totals.customer_id
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT
    product_id,
    product_name,
    category,
    unique_customers,
    total_orders,
    total_revenue,
    high_value_customers,
    medium_value_customers,
    low_value_customers,
    -- Customer mix analysis
    ROUND(high_value_customers * 100.0 / NULLIF(unique_customers, 0), 2) as high_value_customer_pct,
    -- Product popularity ranking
    RANK() OVER (ORDER BY unique_customers DESC) as popularity_rank,
    RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank
FROM product_customer_analysis
WHERE unique_customers > 0
ORDER BY unique_customers DESC;
