-- 3. Identify high-cardinality columns that could benefit from indexing

SELECT
    t.table_name,
    c.column_name,
    t.table_rows,
    c.data_type,
    c.ordinal_position,
    c.column_type
FROM information_schema.columns c
JOIN information_schema.tables t
  ON c.table_schema = t.table_schema
 AND c.table_name   = t.table_name
WHERE c.table_schema = DATABASE()
  AND c.table_name IN ('customers', 'orders', 'employees', 'products', 'sales')
ORDER BY t.table_name, c.ordinal_position;
