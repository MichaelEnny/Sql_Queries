-- 1. Use a CTE to separate full names into first and last names

WITH name_parser AS (
  SELECT
    employee_id,
    full_name,
    CASE
      WHEN LOCATE(' ', full_name) > 0
        THEN SUBSTRING_INDEX(full_name, ' ', 1)
      ELSE full_name
    END AS parsed_first_name,
    CASE
      WHEN LOCATE(' ', full_name) > 0
        THEN TRIM(SUBSTRING(full_name, LOCATE(' ', full_name) + 1))
      ELSE ''
    END AS parsed_last_name
  FROM employees
  WHERE full_name IS NOT NULL
)
SELECT
  np.employee_id,
  np.full_name,
  np.parsed_first_name,
  np.parsed_last_name,
  CASE
    WHEN e.first_name = np.parsed_first_name
     AND e.last_name  = np.parsed_last_name
    THEN 'Match' ELSE 'Mismatch'
  END AS validation_status
FROM name_parser AS np
JOIN employees AS e
  ON e.employee_id = np.employee_id
ORDER BY np.employee_id;
