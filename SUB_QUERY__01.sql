-- 1. Find customers whose total purchase value exceeds the average order value

SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    customer_totals.total_purchase_value,
    customer_totals.order_count,
    ROUND(customer_totals.total_purchase_value / customer_totals.order_count, 2) as avg_order_value,
    overall_avg.company_avg_order_value,
    ROUND(
        (customer_totals.total_purchase_value / overall_avg.company_avg_order_value - 1) * 100,
        2
    ) as percentage_above_average
FROM customers c
JOIN (
    -- Customer totals subquery
    SELECT
        customer_id,
        SUM(order_value) as total_purchase_value,
        COUNT(*) as order_count
    FROM orders
    GROUP BY customer_id
) customer_totals ON c.customer_id = customer_totals.customer_id
CROSS JOIN (
    -- Overall average subquery
    SELECT AVG(order_value) as company_avg_order_value
    FROM orders
) overall_avg
WHERE customer_totals.total_purchase_value > overall_avg.company_avg_order_value
ORDER BY customer_totals.total_purchase_value DESC;
