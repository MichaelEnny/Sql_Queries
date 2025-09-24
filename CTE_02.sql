-- 2. Write a CTE to determine the longest streak of consecutive sales by an employee

WITH s1 AS (
  SELECT
    employee_id,
    sale_date,
    sale_amount,
    DENSE_RANK() OVER (
      PARTITION BY employee_id
      ORDER BY sale_date
    ) AS rnk
  FROM sales
),
sales_with_sequence AS (
  SELECT
    employee_id,
    sale_date,
    sale_amount,
    rnk,
    -- same value for consecutive-day runs:
    DATE_SUB(sale_date, INTERVAL rnk DAY) AS group_date
  FROM s1
),
consecutive_groups AS (
  SELECT
    employee_id,
    group_date,
    COUNT(*)            AS streak_length,
    MIN(sale_date)      AS streak_start,
    MAX(sale_date)      AS streak_end,
    SUM(sale_amount)    AS streak_total_sales
  FROM sales_with_sequence
  GROUP BY employee_id, group_date
),
longest_streaks AS (
  SELECT
    employee_id,
    streak_length,
    streak_start,
    streak_end,
    streak_total_sales,
    ROW_NUMBER() OVER (
      PARTITION BY employee_id
      ORDER BY streak_length DESC, streak_total_sales DESC, streak_end DESC
    ) AS rn
  FROM consecutive_groups
)
SELECT
  ls.employee_id,
  e.first_name,
  e.last_name,
  ls.streak_length AS longest_consecutive_days,
  ls.streak_start,
  ls.streak_end,
  ls.streak_total_sales
FROM longest_streaks AS ls
JOIN employees AS e
  ON e.employee_id = ls.employee_id
WHERE ls.rn = 1
ORDER BY longest_consecutive_days DESC, ls.streak_total_sales DESC;
