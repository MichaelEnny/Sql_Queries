-- 5. Calculate the percentage contribution of each employee to the company's total revenue

SELECT
    employee_id,
    first_name,
    last_name,
    revenue_generated,
    SUM(revenue_generated) OVER () as total_company_revenue,
    ROUND(
        (revenue_generated / SUM(revenue_generated) OVER ()) * 100,
        2
    ) as percentage_contribution,
    -- Running percentage for cumulative analysis
    ROUND(
        (SUM(revenue_generated) OVER (ORDER BY revenue_generated DESC) /
         SUM(revenue_generated) OVER ()) * 100,
        2
    ) as cumulative_percentage
FROM employees
WHERE revenue_generated > 0
ORDER BY revenue_generated DESC;