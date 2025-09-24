-- 2. Retrieve employees with the lowest salary in their respective departments

SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.department_id,
    e.salary,
    e.hire_date,
    -- Additional context
    dept_stats.avg_dept_salary,
    dept_stats.max_dept_salary,
    dept_stats.employee_count,
    ROUND((dept_stats.avg_dept_salary - e.salary), 2) as salary_gap_from_avg
FROM employees e
JOIN (
    -- Department statistics subquery
    SELECT
        department_id,
        MIN(salary) as min_salary,
        AVG(salary) as avg_dept_salary,
        MAX(salary) as max_dept_salary,
        COUNT(*) as employee_count
    FROM employees
    GROUP BY department_id
) dept_stats ON e.department_id = dept_stats.department_id
                AND e.salary = dept_stats.min_salary
ORDER BY e.department_id, e.hire_date;
