SELECT
    e.employee_id,
    e.first_name AS employee_first_name,
    e.last_name  AS employee_last_name,
    e.salary     AS employee_salary,
    e.department_id,
    e.manager_id,

    m.employee_id AS manager_employee_id,
    m.first_name  AS manager_first_name,
    m.last_name   AS manager_last_name,
    m.salary      AS manager_salary,

    -- Hierarchy analysis
    CASE
        WHEN e.manager_id IS NULL THEN 'TOP LEVEL'
        WHEN m.manager_id IS NULL THEN 'REPORTS TO CEO'
        ELSE 'MID LEVEL'
    END AS hierarchy_level,

    -- Salary comparison
    CASE
        WHEN e.manager_id IS NULL THEN NULL
        WHEN e.salary >  m.salary THEN 'EMPLOYEE EARNS MORE'
        WHEN e.salary =  m.salary THEN 'EQUAL SALARY'
        ELSE 'NORMAL HIERARCHY'
    END AS salary_comparison,

    -- Management span
    COALESCE(dr.direct_reports, 0) AS manager_direct_reports
FROM employees AS e
LEFT JOIN employees AS m
    ON e.manager_id = m.employee_id
LEFT JOIN (
    SELECT
        manager_id,
        COUNT(*) AS direct_reports
    FROM employees
    WHERE manager_id IS NOT NULL
    GROUP BY manager_id
) AS dr
    ON m.employee_id = dr.manager_id
ORDER BY
    CASE WHEN e.manager_id IS NULL THEN 0 ELSE 1 END,  -- Top level first
    COALESCE(m.last_name, ''),  -- avoid NULL sort surprises
    e.last_name
LIMIT 0, 1000;