SELECT
    employee_id,
    first_name,
    last_name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS unique_rank,
    RANK() OVER (ORDER BY salary DESC) AS standard_rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dens_rank
FROM employees
ORDER BY salary DESC;