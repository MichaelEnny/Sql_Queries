-- 1. Compute the median salary for each department

WITH ordered AS (
  SELECT
    department_id,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary) AS rn,
    COUNT(*) OVER (PARTITION BY department_id) AS cnt
  FROM employees
  WHERE salary IS NOT NULL
)
SELECT
  department_id,
  MIN(salary) AS min_salary,
  MAX(salary) AS max_salary,
  AVG(salary) AS mean_salary,
  STDDEV(salary) AS salary_std_dev,
  -- Median: middle value (or average of 2 middle values if even count)
  CASE
    WHEN cnt % 2 = 1 THEN
      MAX(CASE WHEN rn = (cnt + 1) / 2 THEN salary END)
    ELSE
      AVG(CASE WHEN rn IN (cnt/2, cnt/2 + 1) THEN salary END)
  END AS median_salary
FROM ordered
GROUP BY department_id
ORDER BY median_salary DESC;
