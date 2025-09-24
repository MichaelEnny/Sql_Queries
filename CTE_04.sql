-- 4. Use a CTE to detect and list duplicate entries in a table

WITH duplicate_analysis AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(*) OVER (PARTITION BY customer_name) AS name_count,
        ROW_NUMBER() OVER (PARTITION BY customer_name ORDER BY customer_id) AS duplicate_rank
    FROM customers
),
duplicate_summary AS (
    SELECT
        customer_id,
        customer_name,
        name_count,
        duplicate_rank,
        CASE
            WHEN name_count > 1 THEN 'Name Duplicate'
            ELSE 'No Duplicate'
        END AS duplicate_type
    FROM duplicate_analysis
)
SELECT
    customer_id,
    customer_name,
    duplicate_type,
    name_count,
    duplicate_rank,
    CASE
        WHEN duplicate_rank = 1 THEN 'KEEP'
        ELSE 'REVIEW FOR DELETION'
    END AS recommendation
FROM duplicate_summary
WHERE name_count > 1
ORDER BY customer_name, duplicate_rank;
