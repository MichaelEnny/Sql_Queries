-- 5. Calculate total sales per category and filter out categories with sales below a specific threshold using a CTE

WITH category_sales AS (
    SELECT
        p.category,
        COUNT(DISTINCT o.order_id) as total_orders,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        SUM(o.order_value) as total_sales,
        AVG(o.order_value) as avg_order_value,
        MIN(o.order_date) as first_sale_date,
        MAX(o.order_date) as last_sale_date
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.category
),
sales_ranking AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank,
        ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2) as market_share_pct
    FROM category_sales
)
SELECT
    category,
    total_orders,
    unique_customers,
    total_sales,
    avg_order_value,
    sales_rank,
    market_share_pct,
    first_sale_date,
    last_sale_date,
    -- Performance indicators
    ROUND(total_sales / total_orders, 2) as revenue_per_order,
    ROUND(total_sales / unique_customers, 2) as revenue_per_customer
FROM sales_ranking
WHERE total_sales >= 50000  -- Threshold: $50,000 minimum sales
ORDER BY total_sales DESC;
