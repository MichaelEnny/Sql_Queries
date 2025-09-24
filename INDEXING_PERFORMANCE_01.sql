-- 1. Write a query to locate duplicate entries in a column with an index
-- Approach: Leverage index for efficient duplicate detection
-- Performance: Demonstrate index usage vs full table scan

SELECT
  customer_name,
  COUNT(*) AS duplicate_count,
  GROUP_CONCAT(customer_id ORDER BY customer_id SEPARATOR ', ') AS customer_ids,
  MIN(customer_id) AS keep_customer_id,
  MAX(customer_id) AS latest_customer_id
FROM customers
GROUP BY customer_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, customer_name;


