-- 4. List regions where the highest sales value is below a specified threshold

SELECT
    region_data.region,
    region_data.max_sale_value,
    region_data.total_sales,
    region_data.sale_count,
    region_data.avg_sale_value,
    region_data.min_sale_value
FROM (
    SELECT
        region,
        MAX(sale_amount) as max_sale_value,
        SUM(sale_amount) as total_sales,
        COUNT(*) as sale_count,
        AVG(sale_amount) as avg_sale_value,
        MIN(sale_amount) as min_sale_value
    FROM sales
    GROUP BY region
) region_data
WHERE region_data.max_sale_value < 5000  -- Threshold: $5,000
ORDER BY region_data.max_sale_value DESC;
