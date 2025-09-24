-- 4. Find the second highest salary in each department using window functions
-- Approach: DENSE_RANK to handle tied salaries, filter for rank = 2

WITH ranked_salaries AS (
    SELECT
        employee_id,
        first_name,
        last_name,
        department_id,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department_id
            ORDER BY salary DESC
        ) as salary_rank
    FROM employees
)
SELECT
    employee_id,
    first_name,
    last_name,
    department_id,
    salary
FROM ranked_salaries
WHERE salary_rank = 2
ORDER BY department_id, salary DESC;