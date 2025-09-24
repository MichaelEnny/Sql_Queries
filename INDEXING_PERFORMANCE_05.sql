-- 5. Write a query that bypasses indexing to observe performance variations

EXPLAIN ANALYZE
SELECT
    customer_id,
    customer_name,
    email
FROM customers
WHERE UPPER(email) = UPPER('john.doe@email.com')
   OR LENGTH(customer_name) > 10;

