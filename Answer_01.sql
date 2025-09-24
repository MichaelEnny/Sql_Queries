-- 1. Compute the rolling average of sales for the last three months
WITH monthly_sales AS (
  SELECT
    employee_id,
    DATE(sale_date - INTERVAL (DAYOFMONTH(sale_date) - 1) DAY) AS sale_month, -- first day of month
    SUM(sale_amount) AS monthly_total
  FROM sales
  GROUP BY
    employee_id,
    DATE(sale_date - INTERVAL (DAYOFMONTH(sale_date) - 1) DAY)
)
SELECT
  employee_id,
  sale_month,
  monthly_total,
  AVG(monthly_total) OVER (
    PARTITION BY employee_id
    ORDER BY sale_month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rolling_3_month_avg
FROM monthly_sales
ORDER BY employee_id, sale_month;
