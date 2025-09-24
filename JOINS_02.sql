-- 2. Identify employees assigned to more than one project using a self-join

SELECT
    p.employee_id,
    e.first_name,
    e.last_name,
    COUNT(DISTINCT p.project_id) AS total_projects,
    GROUP_CONCAT(DISTINCT p.project_name ORDER BY p.project_name SEPARATOR ', ') AS project_list
FROM projects p
JOIN employees e
  ON p.employee_id = e.employee_id
GROUP BY p.employee_id, e.first_name, e.last_name
HAVING COUNT(DISTINCT p.project_id) > 1
ORDER BY total_projects DESC, e.last_name;

