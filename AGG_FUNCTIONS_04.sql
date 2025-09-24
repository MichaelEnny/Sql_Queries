-- 4. Identify the top five regions based on total sales

WITH region_performance AS (
    SELECT
        region,
        SUM(sale_amount) as total_sales,
        COUNT(*) as sale_count,
        COUNT(DISTINCT employee_id) as active_employees,
        AVG(sale_amount) as avg_sale_amount,
        MIN(sale_amount) as min_sale_amount,
        MAX(sale_amount) as max_sale_amount,
        STDDEV(sale_amount) as sale_amount_stddev,
        MIN(sale_date) as first_sale_date,
        MAX(sale_date) as last_sale_date
    FROM sales
    GROUP BY region
),
region_rankings AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank,
        RANK() OVER (ORDER BY avg_sale_amount DESC) as avg_sale_rank,
        RANK() OVER (ORDER BY sale_count DESC) as volume_rank,
        -- Market share calculation
        ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2) as market_share_pct,
        -- Performance consistency (coefficient of variation)
        ROUND((sale_amount_stddev / avg_sale_amount) * 100, 2) as coefficient_of_variation
    FROM region_performance
)
SELECT
    sales_rank,
    region,
    total_sales,
    market_share_pct,
    sale_count,
    active_employees,
    avg_sale_amount,
    avg_sale_rank,
    volume_rank,
    coefficient_of_variation,
    first_sale_date,
    last_sale_date,
    -- Performance indicators
    CASE
        WHEN coefficient_of_variation < 50 THEN 'Consistent'
        WHEN coefficient_of_variation < 100 THEN 'Moderate Variance'
        ELSE 'High Variance'
    END as performance_consistency,
    -- Sales productivity
    ROUND(total_sales / active_employees, 2) as sales_per_employee
FROM region_rankings
WHERE sales_rank <= 5
ORDER BY sales_rank;
