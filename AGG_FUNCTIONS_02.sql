-- 2. Summarize monthly sales and rank them in descending order

SELECT
  sales_year,
  sales_month,
  -- derive the month name from the month number (no grouping issue)
  MONTHNAME(STR_TO_DATE(LPAD(sales_month, 2, '0'), '%m')) AS month_name,

  total_sales,
  sale_count,
  avg_sale_amount,
  unique_employees,

  -- rankings
  RANK()        OVER (ORDER BY total_sales DESC)       AS sales_rank,
  DENSE_RANK()  OVER (ORDER BY total_sales DESC)       AS dense_sales_rank,
  ROW_NUMBER()  OVER (ORDER BY total_sales DESC)       AS unique_rank,

  -- % of total
  ROUND(total_sales / SUM(total_sales) OVER () * 100, 2) AS market_share_pct,

  -- month-over-month
  LAG(total_sales) OVER (ORDER BY sales_year, sales_month) AS prev_month_sales,
  ROUND(
    (total_sales - LAG(total_sales) OVER (ORDER BY sales_year, sales_month))
    / NULLIF(LAG(total_sales) OVER (ORDER BY sales_year, sales_month), 0) * 100,
    2
  ) AS month_over_month_growth
FROM (
  SELECT
    YEAR(sale_date)  AS sales_year,
    MONTH(sale_date) AS sales_month,
    SUM(sale_amount)            AS total_sales,
    COUNT(*)                    AS sale_count,
    AVG(sale_amount)            AS avg_sale_amount,
    COUNT(DISTINCT employee_id) AS unique_employees
  FROM sales
  GROUP BY YEAR(sale_date), MONTH(sale_date)
) AS monthly_summary
ORDER BY sales_rank;
