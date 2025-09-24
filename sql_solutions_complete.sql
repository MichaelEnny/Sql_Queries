-- =====================================================
-- SQL INTERVIEW QUESTIONS - COMPLETE SOLUTIONS
-- 30 Questions Across 6 Categories
-- Optimized for Performance and Cross-Platform Compatibility
-- =====================================================

-- SAMPLE TABLE STRUCTURES FOR REFERENCE
-- These tables will be referenced throughout the solutions

/*
-- Employees Table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    full_name VARCHAR(100), -- For CTE examples
    salary DECIMAL(10,2),
    department_id INT,
    manager_id INT,
    hire_date DATE,
    revenue_generated DECIMAL(15,2)
);

-- Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    registration_date DATE,
    region VARCHAR(50)
);

-- Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    employee_id INT,
    order_date DATE,
    order_value DECIMAL(10,2),
    product_id INT
);

-- Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

-- Sales Table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    employee_id INT,
    sale_date DATE,
    sale_amount DECIMAL(10,2),
    region VARCHAR(50)
);

-- Projects Table
CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    employee_id INT,
    project_name VARCHAR(100)
);
*/

-- =====================================================
-- WINDOW FUNCTIONS (5 Questions)
-- =====================================================

-- 1. Compute the rolling average of sales for the last three months
-- Approach: Use window function with ROWS BETWEEN for sliding window calculation
-- Performance: Index on (employee_id, sale_date) for optimal performance

-- PostgreSQL/SQL Server/Oracle Solution:
WITH monthly_sales AS (
    SELECT
        employee_id,
        DATE_TRUNC('month', sale_date) as sale_month, -- PostgreSQL
        -- DATEPART(YEAR, sale_date) * 100 + DATEPART(MONTH, sale_date) as sale_month, -- SQL Server
        -- TRUNC(sale_date, 'MM') as sale_month, -- Oracle
        SUM(sale_amount) as monthly_total
    FROM sales
    GROUP BY employee_id, DATE_TRUNC('month', sale_date)
)
SELECT
    employee_id,
    sale_month,
    monthly_total,
    AVG(monthly_total) OVER (
        PARTITION BY employee_id
        ORDER BY sale_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as rolling_3_month_avg
FROM monthly_sales
ORDER BY employee_id, sale_month;

-- MySQL Alternative (no DATE_TRUNC):
-- SELECT
--     employee_id,
--     YEAR(sale_date) * 100 + MONTH(sale_date) as sale_month,
--     SUM(sale_amount) as monthly_total,
--     AVG(SUM(sale_amount)) OVER (
--         PARTITION BY employee_id
--         ORDER BY YEAR(sale_date) * 100 + MONTH(sale_date)
--         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--     ) as rolling_3_month_avg
-- FROM sales
-- GROUP BY employee_id, YEAR(sale_date), MONTH(sale_date)
-- ORDER BY employee_id, sale_month;

-- Index Recommendation:
-- CREATE INDEX idx_sales_emp_date ON sales(employee_id, sale_date, sale_amount);

-- =====================================================

-- 2. Rank employees uniquely based on their salaries in descending order
-- Approach: ROW_NUMBER() ensures unique ranking even for tied salaries
-- Performance: Index on salary column for fast sorting

SELECT
    employee_id,
    first_name,
    last_name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) as unique_rank,
    RANK() OVER (ORDER BY salary DESC) as standard_rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank
FROM employees
ORDER BY salary DESC;

-- Alternative with tie-breaking by employee_id:
SELECT
    employee_id,
    first_name,
    last_name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC, employee_id ASC) as unique_rank_with_tiebreaker
FROM employees
ORDER BY salary DESC, employee_id ASC;

-- Index Recommendation:
-- CREATE INDEX idx_employees_salary ON employees(salary DESC, employee_id);

-- =====================================================

-- 3. Identify the earliest and latest purchase dates for each customer
-- Approach: FIRST_VALUE and LAST_VALUE with proper frame specification
-- Performance: Index on (customer_id, order_date) for optimal window function performance

SELECT DISTINCT
    customer_id,
    FIRST_VALUE(order_date) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as earliest_purchase,
    LAST_VALUE(order_date) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as latest_purchase,
    COUNT(*) OVER (PARTITION BY customer_id) as total_orders
FROM orders
ORDER BY customer_id;

-- Alternative using MIN/MAX (often more efficient):
SELECT
    customer_id,
    MIN(order_date) as earliest_purchase,
    MAX(order_date) as latest_purchase,
    COUNT(*) as total_orders
FROM orders
GROUP BY customer_id
ORDER BY customer_id;

-- Index Recommendation:
-- CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- =====================================================

-- 4. Find the second highest salary in each department using window functions
-- Approach: DENSE_RANK to handle tied salaries, filter for rank = 2
-- Performance: Composite index on (department_id, salary) for efficient sorting

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

-- Alternative using OFFSET for single result per department:
SELECT DISTINCT
    department_id,
    NTH_VALUE(salary, 2) OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as second_highest_salary
FROM employees
WHERE NTH_VALUE(salary, 2) OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
) IS NOT NULL
ORDER BY department_id;

-- Index Recommendation:
-- CREATE INDEX idx_employees_dept_salary ON employees(department_id, salary DESC);

-- =====================================================

-- 5. Calculate the percentage contribution of each employee to the company's total revenue
-- Approach: Use SUM() OVER() for total revenue, calculate percentage
-- Performance: Consider materialized view for frequently accessed company totals

SELECT
    employee_id,
    first_name,
    last_name,
    revenue_generated,
    SUM(revenue_generated) OVER () as total_company_revenue,
    ROUND(
        (revenue_generated / SUM(revenue_generated) OVER ()) * 100,
        2
    ) as percentage_contribution,
    -- Running percentage for cumulative analysis
    ROUND(
        (SUM(revenue_generated) OVER (ORDER BY revenue_generated DESC) /
         SUM(revenue_generated) OVER ()) * 100,
        2
    ) as cumulative_percentage
FROM employees
WHERE revenue_generated > 0
ORDER BY revenue_generated DESC;

-- Alternative with CASE for zero division protection:
SELECT
    employee_id,
    first_name,
    last_name,
    revenue_generated,
    CASE
        WHEN SUM(revenue_generated) OVER () = 0 THEN 0
        ELSE ROUND((revenue_generated / SUM(revenue_generated) OVER ()) * 100, 2)
    END as percentage_contribution
FROM employees
ORDER BY revenue_generated DESC;

-- =====================================================
-- COMMON TABLE EXPRESSIONS (CTEs) (5 Questions)
-- =====================================================

-- 1. Use a CTE to separate full names into first and last names
-- Approach: String manipulation functions to parse full_name column
-- Cross-platform note: String functions vary across databases

-- PostgreSQL Solution:
WITH name_parser AS (
    SELECT
        employee_id,
        full_name,
        SPLIT_PART(full_name, ' ', 1) as parsed_first_name,
        CASE
            WHEN POSITION(' ' IN full_name) > 0
            THEN SUBSTRING(full_name FROM POSITION(' ' IN full_name) + 1)
            ELSE ''
        END as parsed_last_name
    FROM employees
    WHERE full_name IS NOT NULL
)
SELECT
    employee_id,
    full_name,
    parsed_first_name,
    parsed_last_name,
    -- Validation: Check if parsing matches existing data
    CASE
        WHEN first_name = parsed_first_name AND last_name = parsed_last_name
        THEN 'Match'
        ELSE 'Mismatch'
    END as validation_status
FROM name_parser np
JOIN employees e USING (employee_id)
ORDER BY employee_id;

-- SQL Server Alternative:
-- WITH name_parser AS (
--     SELECT
--         employee_id,
--         full_name,
--         LEFT(full_name, CHARINDEX(' ', full_name + ' ') - 1) as parsed_first_name,
--         LTRIM(SUBSTRING(full_name, CHARINDEX(' ', full_name + ' '), LEN(full_name))) as parsed_last_name
--     FROM employees
--     WHERE full_name IS NOT NULL
-- )

-- MySQL Alternative:
-- WITH name_parser AS (
--     SELECT
--         employee_id,
--         full_name,
--         SUBSTRING_INDEX(full_name, ' ', 1) as parsed_first_name,
--         SUBSTRING_INDEX(full_name, ' ', -1) as parsed_last_name
--     FROM employees
--     WHERE full_name IS NOT NULL
-- )

-- =====================================================

-- 2. Write a CTE to determine the longest streak of consecutive sales by an employee
-- Approach: Use ROW_NUMBER and grouping to identify consecutive sequences
-- Performance: Index on (employee_id, sale_date) essential for performance

WITH sales_with_sequence AS (
    -- Add row numbers to identify gaps in consecutive dates
    SELECT
        employee_id,
        sale_date,
        sale_amount,
        ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY sale_date) as rn,
        sale_date - INTERVAL '1 day' * ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY sale_date) as group_date
    FROM sales
),
consecutive_groups AS (
    -- Group consecutive sales together
    SELECT
        employee_id,
        group_date,
        COUNT(*) as streak_length,
        MIN(sale_date) as streak_start,
        MAX(sale_date) as streak_end,
        SUM(sale_amount) as streak_total_sales
    FROM sales_with_sequence
    GROUP BY employee_id, group_date
),
longest_streaks AS (
    -- Find the longest streak for each employee
    SELECT
        employee_id,
        streak_length,
        streak_start,
        streak_end,
        streak_total_sales,
        ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY streak_length DESC, streak_total_sales DESC) as rn
    FROM consecutive_groups
)
SELECT
    ls.employee_id,
    e.first_name,
    e.last_name,
    ls.streak_length as longest_consecutive_days,
    ls.streak_start,
    ls.streak_end,
    ls.streak_total_sales
FROM longest_streaks ls
JOIN employees e ON ls.employee_id = e.employee_id
WHERE ls.rn = 1
ORDER BY ls.streak_length DESC;

-- Index Recommendation:
-- CREATE INDEX idx_sales_emp_date_amount ON sales(employee_id, sale_date, sale_amount);

-- =====================================================

-- 3. Generate a sequence of Fibonacci numbers up to a specific value using a recursive CTE
-- Approach: Recursive CTE with termination condition
-- Performance: Limit recursion depth to prevent infinite loops

WITH RECURSIVE fibonacci_sequence AS (
    -- Base case: First two Fibonacci numbers
    SELECT
        1 as position,
        0 as fib_number,
        1 as next_fib

    UNION ALL

    -- Recursive case: Generate next Fibonacci number
    SELECT
        position + 1,
        next_fib,
        fib_number + next_fib
    FROM fibonacci_sequence
    WHERE next_fib <= 1000  -- Limit: generate up to 1000
    AND position < 50       -- Safety: prevent excessive recursion
)
SELECT
    position,
    fib_number,
    -- Additional calculations
    CASE
        WHEN position > 1
        THEN ROUND(fib_number::NUMERIC / LAG(fib_number) OVER (ORDER BY position), 6)
        ELSE NULL
    END as golden_ratio_approximation
FROM fibonacci_sequence
WHERE fib_number <= 1000
ORDER BY position;

-- Alternative with parameterized limit:
-- Replace 1000 with @max_value parameter in stored procedure

-- Cross-platform note:
-- - PostgreSQL: Works as shown
-- - SQL Server: Use CAST instead of ::NUMERIC
-- - MySQL: Supported in 8.0+
-- - Oracle: Use CONNECT BY for recursive behavior

-- =====================================================

-- 4. Use a CTE to detect and list duplicate entries in a table
-- Approach: Window functions to count occurrences and identify duplicates
-- Performance: Index on columns being checked for duplicates

WITH duplicate_analysis AS (
    SELECT
        customer_id,
        customer_name,
        email,
        phone,
        COUNT(*) OVER (PARTITION BY customer_name, email) as name_email_count,
        COUNT(*) OVER (PARTITION BY phone) as phone_count,
        COUNT(*) OVER (PARTITION BY email) as email_count,
        ROW_NUMBER() OVER (PARTITION BY customer_name, email ORDER BY customer_id) as duplicate_rank
    FROM customers
),
duplicate_summary AS (
    SELECT
        customer_id,
        customer_name,
        email,
        phone,
        name_email_count,
        phone_count,
        email_count,
        duplicate_rank,
        -- Categorize type of duplicate
        CASE
            WHEN name_email_count > 1 AND phone_count > 1 THEN 'Complete Duplicate'
            WHEN name_email_count > 1 THEN 'Name-Email Duplicate'
            WHEN phone_count > 1 THEN 'Phone Duplicate'
            WHEN email_count > 1 THEN 'Email Duplicate'
            ELSE 'No Duplicate'
        END as duplicate_type
    FROM duplicate_analysis
)
SELECT
    customer_id,
    customer_name,
    email,
    phone,
    duplicate_type,
    name_email_count,
    duplicate_rank,
    -- Recommendation for cleanup
    CASE
        WHEN duplicate_rank = 1 THEN 'KEEP'
        ELSE 'REVIEW FOR DELETION'
    END as recommendation
FROM duplicate_summary
WHERE name_email_count > 1 OR phone_count > 1 OR email_count > 1
ORDER BY duplicate_type, customer_name, duplicate_rank;

-- Cleanup query to remove duplicates (keep first occurrence):
-- DELETE FROM customers
-- WHERE customer_id IN (
--     SELECT customer_id FROM duplicate_summary
--     WHERE duplicate_rank > 1 AND duplicate_type = 'Complete Duplicate'
-- );

-- Index Recommendations:
-- CREATE INDEX idx_customers_name_email ON customers(customer_name, email);
-- CREATE INDEX idx_customers_phone ON customers(phone);
-- CREATE INDEX idx_customers_email ON customers(email);

-- =====================================================

-- 5. Calculate total sales per category and filter out categories with sales below a specific threshold using a CTE
-- Approach: Aggregate sales by category, then filter using CTE
-- Performance: Index on (category, price) for efficient aggregation

WITH category_sales AS (
    SELECT
        p.category,
        COUNT(DISTINCT o.order_id) as total_orders,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        SUM(o.order_value) as total_sales,
        AVG(o.order_value) as avg_order_value,
        MIN(o.order_date) as first_sale_date,
        MAX(o.order_date) as last_sale_date
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.category
),
sales_ranking AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank,
        ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2) as market_share_pct
    FROM category_sales
)
SELECT
    category,
    total_orders,
    unique_customers,
    total_sales,
    avg_order_value,
    sales_rank,
    market_share_pct,
    first_sale_date,
    last_sale_date,
    -- Performance indicators
    ROUND(total_sales / total_orders, 2) as revenue_per_order,
    ROUND(total_sales / unique_customers, 2) as revenue_per_customer
FROM sales_ranking
WHERE total_sales >= 50000  -- Threshold: $50,000 minimum sales
ORDER BY total_sales DESC;

-- Dynamic threshold using parameters:
-- DECLARE @sales_threshold DECIMAL(15,2) = 50000;
-- Add: WHERE total_sales >= @sales_threshold

-- Index Recommendations:
-- CREATE INDEX idx_orders_product_value ON orders(product_id, order_value, order_date);
-- CREATE INDEX idx_products_category ON products(category, product_id);

-- =====================================================
-- JOINS (5 Questions)
-- =====================================================

-- 1. List all customers, highlighting who placed orders and who didn't (Full Outer Join)
-- Approach: FULL OUTER JOIN to show all customers and all orders
-- Cross-platform note: MySQL doesn't support FULL OUTER JOIN directly

-- PostgreSQL/SQL Server/Oracle Solution:
SELECT
    COALESCE(c.customer_id, o.customer_id) as customer_id,
    c.customer_name,
    c.registration_date,
    c.region,
    COUNT(o.order_id) as total_orders,
    COALESCE(SUM(o.order_value), 0) as total_order_value,
    MAX(o.order_date) as last_order_date,
    CASE
        WHEN c.customer_id IS NULL THEN 'Order without customer record'
        WHEN o.customer_id IS NULL THEN 'Customer with no orders'
        ELSE 'Active customer'
    END as customer_status
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY
    COALESCE(c.customer_id, o.customer_id),
    c.customer_name,
    c.registration_date,
    c.region
ORDER BY customer_status, total_order_value DESC;

-- MySQL Alternative (using UNION):
-- SELECT
--     c.customer_id,
--     c.customer_name,
--     c.registration_date,
--     c.region,
--     COUNT(o.order_id) as total_orders,
--     COALESCE(SUM(o.order_value), 0) as total_order_value,
--     'Customer' as record_type
-- FROM customers c
-- LEFT JOIN orders o ON c.customer_id = o.customer_id
-- GROUP BY c.customer_id, c.customer_name, c.registration_date, c.region
--
-- UNION ALL
--
-- SELECT
--     o.customer_id,
--     'UNKNOWN' as customer_name,
--     NULL as registration_date,
--     NULL as region,
--     COUNT(o.order_id) as total_orders,
--     SUM(o.order_value) as total_order_value,
--     'Orphaned Order' as record_type
-- FROM orders o
-- LEFT JOIN customers c ON o.customer_id = c.customer_id
-- WHERE c.customer_id IS NULL
-- GROUP BY o.customer_id;

-- =====================================================

-- 2. Identify employees assigned to more than one project using a self-join
-- Approach: Self-join on projects table to find employees with multiple projects
-- Performance: Index on employee_id for efficient self-join

SELECT DISTINCT
    p1.employee_id,
    e.first_name,
    e.last_name,
    COUNT(DISTINCT p1.project_id) as total_projects,
    STRING_AGG(p1.project_name, ', ' ORDER BY p1.project_name) as project_list
FROM projects p1
JOIN projects p2 ON p1.employee_id = p2.employee_id
                AND p1.project_id != p2.project_id
JOIN employees e ON p1.employee_id = e.employee_id
GROUP BY p1.employee_id, e.first_name, e.last_name
HAVING COUNT(DISTINCT p1.project_id) > 1
ORDER BY total_projects DESC, e.last_name;

-- Alternative using window function (often more efficient):
WITH project_counts AS (
    SELECT
        employee_id,
        project_id,
        project_name,
        COUNT(*) OVER (PARTITION BY employee_id) as project_count
    FROM projects
)
SELECT
    pc.employee_id,
    e.first_name,
    e.last_name,
    pc.project_count as total_projects,
    STRING_AGG(pc.project_name, ', ' ORDER BY pc.project_name) as project_list
FROM project_counts pc
JOIN employees e ON pc.employee_id = e.employee_id
WHERE pc.project_count > 1
GROUP BY pc.employee_id, e.first_name, e.last_name, pc.project_count
ORDER BY pc.project_count DESC, e.last_name;

-- Cross-platform STRING_AGG alternatives:
-- SQL Server: STRING_AGG(project_name, ', ')
-- MySQL: GROUP_CONCAT(project_name ORDER BY project_name SEPARATOR ', ')
-- Oracle: LISTAGG(project_name, ', ') WITHIN GROUP (ORDER BY project_name)

-- Index Recommendation:
-- CREATE INDEX idx_projects_employee ON projects(employee_id, project_id, project_name);

-- =====================================================

-- 3. Match orders with customers and display unmatched orders as well (Left Join)
-- Approach: LEFT JOIN to show all orders, including orphaned ones
-- Performance: Index on customer_id for efficient join

SELECT
    o.order_id,
    o.order_date,
    o.order_value,
    o.customer_id,
    COALESCE(c.customer_name, 'CUSTOMER NOT FOUND') as customer_name,
    c.region,
    c.registration_date,
    -- Data quality indicators
    CASE
        WHEN c.customer_id IS NULL THEN 'ORPHANED ORDER'
        WHEN c.registration_date > o.order_date THEN 'DATA INCONSISTENCY'
        ELSE 'VALID ORDER'
    END as order_status,
    -- Customer metrics
    CASE
        WHEN c.customer_id IS NOT NULL THEN
            DATEDIFF(o.order_date, c.registration_date)  -- Days since registration
        ELSE NULL
    END as days_since_registration
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
ORDER BY
    CASE WHEN c.customer_id IS NULL THEN 0 ELSE 1 END,  -- Orphaned orders first
    o.order_date DESC;

-- Summary of unmatched orders:
WITH order_analysis AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_value,
        c.customer_name,
        CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END as is_orphaned
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.customer_id
)
SELECT
    COUNT(*) as total_orders,
    SUM(is_orphaned) as orphaned_orders,
    ROUND((SUM(is_orphaned) * 100.0 / COUNT(*)), 2) as orphaned_percentage,
    SUM(CASE WHEN is_orphaned = 1 THEN order_value ELSE 0 END) as orphaned_order_value
FROM order_analysis;

-- Index Recommendations:
-- CREATE INDEX idx_orders_customer ON orders(customer_id, order_date, order_value);
-- CREATE INDEX idx_customers_id_name ON customers(customer_id, customer_name);

-- =====================================================

-- 4. Create unique product combinations using a Cross Join while excluding identical product pairs
-- Approach: CROSS JOIN with filtering to avoid duplicates and self-pairs
-- Performance: Use WHERE clause efficiently to reduce result set

SELECT
    p1.product_id as product1_id,
    p1.product_name as product1_name,
    p1.category as product1_category,
    p1.price as product1_price,
    p2.product_id as product2_id,
    p2.product_name as product2_name,
    p2.category as product2_category,
    p2.price as product2_price,
    -- Combination metrics
    ABS(p1.price - p2.price) as price_difference,
    (p1.price + p2.price) as bundle_price,
    CASE
        WHEN p1.category = p2.category THEN 'Same Category'
        ELSE 'Cross Category'
    END as combination_type,
    -- Suggested bundle discount
    ROUND((p1.price + p2.price) * 0.9, 2) as discounted_bundle_price
FROM products p1
CROSS JOIN products p2
WHERE p1.product_id < p2.product_id  -- Ensure unique pairs and avoid self-pairs
    AND p1.category != p2.category   -- Optional: only cross-category combinations
ORDER BY
    combination_type,
    bundle_price DESC;

-- Alternative: Include same-category combinations but with different logic
SELECT
    p1.product_id as product1_id,
    p1.product_name as product1_name,
    p2.product_id as product2_id,
    p2.product_name as product2_name,
    p1.category as category,
    (p1.price + p2.price) as bundle_price,
    -- Compatibility score based on price similarity
    CASE
        WHEN ABS(p1.price - p2.price) <= 10 THEN 'High Compatibility'
        WHEN ABS(p1.price - p2.price) <= 50 THEN 'Medium Compatibility'
        ELSE 'Low Compatibility'
    END as price_compatibility
FROM products p1
CROSS JOIN products p2
WHERE p1.product_id != p2.product_id  -- Exclude identical products
    AND p1.product_id < p2.product_id  -- Avoid duplicate pairs (A,B) and (B,A)
ORDER BY bundle_price DESC;

-- Performance note: CROSS JOIN can be expensive with large tables
-- Consider adding LIMIT clause for initial analysis
-- Index Recommendation:
-- CREATE INDEX idx_products_category_price ON products(category, price, product_id);

-- =====================================================

-- 5. Retrieve employees along with their direct managers using a self-join
-- Approach: Self-join on employees table using manager_id
-- Performance: Index on manager_id for efficient hierarchical queries

SELECT
    e.employee_id,
    e.first_name as employee_first_name,
    e.last_name as employee_last_name,
    e.salary as employee_salary,
    e.department_id,
    e.manager_id,
    m.employee_id as manager_employee_id,
    m.first_name as manager_first_name,
    m.last_name as manager_last_name,
    m.salary as manager_salary,
    -- Hierarchy analysis
    CASE
        WHEN e.manager_id IS NULL THEN 'TOP LEVEL'
        WHEN m.manager_id IS NULL THEN 'REPORTS TO CEO'
        ELSE 'MID LEVEL'
    END as hierarchy_level,
    -- Salary comparison
    CASE
        WHEN e.manager_id IS NULL THEN NULL
        WHEN e.salary > m.salary THEN 'EMPLOYEE EARNS MORE'
        WHEN e.salary = m.salary THEN 'EQUAL SALARY'
        ELSE 'NORMAL HIERARCHY'
    END as salary_comparison,
    -- Management span
    COALESCE(m.direct_reports, 0) as manager_direct_reports
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
LEFT JOIN (
    -- Count direct reports for each manager
    SELECT
        manager_id,
        COUNT(*) as direct_reports
    FROM employees
    WHERE manager_id IS NOT NULL
    GROUP BY manager_id
) dr ON m.employee_id = dr.manager_id
ORDER BY
    CASE WHEN e.manager_id IS NULL THEN 0 ELSE 1 END,  -- Top level first
    m.last_name,
    e.last_name;

-- Hierarchical query with levels (recursive approach for deeper hierarchy):
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: Top-level employees (no manager)
    SELECT
        employee_id,
        first_name,
        last_name,
        manager_id,
        salary,
        1 as level,
        CAST(last_name AS VARCHAR(1000)) as hierarchy_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: Employees with managers
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        e.salary,
        eh.level + 1,
        CAST(eh.hierarchy_path || ' -> ' || e.last_name AS VARCHAR(1000))
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
    WHERE eh.level < 10  -- Prevent infinite recursion
)
SELECT
    employee_id,
    REPEAT('  ', level - 1) || first_name || ' ' || last_name as indented_name,
    level,
    hierarchy_path,
    salary
FROM employee_hierarchy
ORDER BY hierarchy_path;

-- Index Recommendations:
-- CREATE INDEX idx_employees_manager ON employees(manager_id, employee_id);
-- CREATE INDEX idx_employees_dept_manager ON employees(department_id, manager_id);

-- =====================================================
-- SUBQUERIES (4 Questions)
-- =====================================================

-- 1. Find customers whose total purchase value exceeds the average order value
-- Approach: Correlated subquery to compare customer total vs average
-- Performance: Consider materialized view for frequently accessed aggregations

SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    customer_totals.total_purchase_value,
    customer_totals.order_count,
    ROUND(customer_totals.total_purchase_value / customer_totals.order_count, 2) as avg_order_value,
    overall_avg.company_avg_order_value,
    ROUND(
        (customer_totals.total_purchase_value / overall_avg.company_avg_order_value - 1) * 100,
        2
    ) as percentage_above_average
FROM customers c
JOIN (
    -- Customer totals subquery
    SELECT
        customer_id,
        SUM(order_value) as total_purchase_value,
        COUNT(*) as order_count
    FROM orders
    GROUP BY customer_id
) customer_totals ON c.customer_id = customer_totals.customer_id
CROSS JOIN (
    -- Overall average subquery
    SELECT AVG(order_value) as company_avg_order_value
    FROM orders
) overall_avg
WHERE customer_totals.total_purchase_value > overall_avg.company_avg_order_value
ORDER BY customer_totals.total_purchase_value DESC;

-- Alternative with window function (single pass):
WITH customer_analysis AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.region,
        SUM(o.order_value) as total_purchase_value,
        COUNT(o.order_id) as order_count,
        AVG(SUM(o.order_value)) OVER () as avg_customer_total,
        AVG(o.order_value) OVER () as avg_order_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.region
)
SELECT
    customer_id,
    customer_name,
    region,
    total_purchase_value,
    order_count,
    avg_order_value,
    ROUND((total_purchase_value / avg_customer_total - 1) * 100, 2) as pct_above_avg_customer
FROM customer_analysis
WHERE total_purchase_value > avg_customer_total
ORDER BY total_purchase_value DESC;

-- Index Recommendations:
-- CREATE INDEX idx_orders_customer_value ON orders(customer_id, order_value);

-- =====================================================

-- 2. Retrieve employees with the lowest salary in their respective departments
-- Approach: Correlated subquery to find minimum salary per department
-- Performance: Index on (department_id, salary) for efficient subquery execution

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

-- Alternative using window function:
WITH salary_ranks AS (
    SELECT
        employee_id,
        first_name,
        last_name,
        department_id,
        salary,
        hire_date,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary ASC, hire_date ASC) as salary_rank,
        MIN(salary) OVER (PARTITION BY department_id) as dept_min_salary,
        AVG(salary) OVER (PARTITION BY department_id) as dept_avg_salary
    FROM employees
)
SELECT
    employee_id,
    first_name,
    last_name,
    department_id,
    salary,
    hire_date,
    dept_avg_salary,
    ROUND(dept_avg_salary - salary, 2) as salary_gap_from_avg
FROM salary_ranks
WHERE salary_rank = 1  -- Lowest salary (with tie-breaking by hire_date)
ORDER BY department_id;

-- Multiple employees with same lowest salary:
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.department_id,
    e.salary,
    e.hire_date
FROM employees e
WHERE e.salary = (
    SELECT MIN(salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
)
ORDER BY e.department_id, e.hire_date;

-- Index Recommendation:
-- CREATE INDEX idx_employees_dept_salary_hire ON employees(department_id, salary, hire_date);

-- =====================================================

-- 3. Identify products ordered more than 10 times using a subquery
-- Approach: EXISTS subquery with HAVING clause for efficient filtering
-- Performance: Index on product_id for fast aggregation

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    product_stats.order_count,
    product_stats.total_quantity,
    product_stats.total_revenue,
    product_stats.avg_order_value,
    product_stats.first_order_date,
    product_stats.last_order_date
FROM products p
JOIN (
    -- Product order statistics subquery
    SELECT
        product_id,
        COUNT(*) as order_count,
        SUM(quantity) as total_quantity,  -- Assuming quantity column exists
        SUM(order_value) as total_revenue,
        AVG(order_value) as avg_order_value,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date
    FROM orders
    GROUP BY product_id
    HAVING COUNT(*) > 10
) product_stats ON p.product_id = product_stats.product_id
ORDER BY product_stats.order_count DESC;

-- Alternative using EXISTS (more readable):
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    (SELECT COUNT(*) FROM orders o WHERE o.product_id = p.product_id) as order_count
FROM products p
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.product_id = p.product_id
    GROUP BY o.product_id
    HAVING COUNT(*) > 10
)
ORDER BY order_count DESC;

-- Performance analysis query:
WITH product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        COUNT(o.order_id) as order_count,
        SUM(o.order_value) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(o.order_value) as avg_order_value
    FROM products p
    LEFT JOIN orders o ON p.product_id = o.product_id
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT
    product_id,
    product_name,
    category,
    order_count,
    total_revenue,
    unique_customers,
    avg_order_value,
    CASE
        WHEN order_count > 50 THEN 'High Demand'
        WHEN order_count > 10 THEN 'Medium Demand'
        WHEN order_count > 0 THEN 'Low Demand'
        ELSE 'No Orders'
    END as demand_category
FROM product_performance
WHERE order_count > 10
ORDER BY order_count DESC;

-- Index Recommendations:
-- CREATE INDEX idx_orders_product_date ON orders(product_id, order_date, order_value);
-- CREATE INDEX idx_products_category_name ON products(category, product_name);

-- =====================================================

-- 4. List regions where the highest sales value is below a specified threshold
-- Approach: Subquery to find max sales per region, filter by threshold
-- Performance: Index on (region, sale_amount) for efficient MAX calculation

-- Method 1: Using subquery with MAX
SELECT
    region_data.region,
    region_data.max_sale_value,
    region_data.total_sales,
    region_data.sale_count,
    region_data.avg_sale_value,
    region_data.min_sale_value
FROM (
    SELECT
        region,
        MAX(sale_amount) as max_sale_value,
        SUM(sale_amount) as total_sales,
        COUNT(*) as sale_count,
        AVG(sale_amount) as avg_sale_value,
        MIN(sale_amount) as min_sale_value
    FROM sales
    GROUP BY region
) region_data
WHERE region_data.max_sale_value < 5000  -- Threshold: $5,000
ORDER BY region_data.max_sale_value DESC;

-- Method 2: Using window function for additional context
WITH region_analysis AS (
    SELECT
        region,
        sale_amount,
        sale_date,
        MAX(sale_amount) OVER (PARTITION BY region) as region_max_sale,
        AVG(sale_amount) OVER (PARTITION BY region) as region_avg_sale,
        COUNT(*) OVER (PARTITION BY region) as region_sale_count,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY sale_amount DESC) as sale_rank
    FROM sales
),
region_summary AS (
    SELECT DISTINCT
        region,
        region_max_sale,
        region_avg_sale,
        region_sale_count,
        -- Performance metrics
        CASE
            WHEN region_max_sale < 1000 THEN 'Very Low Performance'
            WHEN region_max_sale < 5000 THEN 'Low Performance'
            WHEN region_max_sale < 10000 THEN 'Medium Performance'
            ELSE 'High Performance'
        END as performance_category
    FROM region_analysis
)
SELECT
    region,
    region_max_sale,
    region_avg_sale,
    region_sale_count,
    performance_category,
    -- Recommendations
    CASE
        WHEN region_max_sale < 5000 THEN 'Needs attention: Consider training or market analysis'
        ELSE 'Performing well'
    END as recommendation
FROM region_summary
WHERE region_max_sale < 5000  -- Configurable threshold
ORDER BY region_max_sale ASC;

-- Method 3: Parameterized version for stored procedure
-- DECLARE @threshold DECIMAL(10,2) = 5000;
--
-- SELECT
--     s.region,
--     MAX(s.sale_amount) as max_sale_value,
--     COUNT(*) as total_sales,
--     AVG(s.sale_amount) as avg_sale_value
-- FROM sales s
-- GROUP BY s.region
-- HAVING MAX(s.sale_amount) < @threshold
-- ORDER BY MAX(s.sale_amount) DESC;

-- Additional analysis: Compare with overall company performance
WITH region_performance AS (
    SELECT
        region,
        MAX(sale_amount) as max_sale_value,
        SUM(sale_amount) as total_sales,
        COUNT(*) as sale_count
    FROM sales
    GROUP BY region
),
company_benchmark AS (
    SELECT
        AVG(max_sale_value) as company_avg_max_sale,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY max_sale_value) as company_median_max_sale
    FROM region_performance
)
SELECT
    rp.region,
    rp.max_sale_value,
    rp.total_sales,
    rp.sale_count,
    cb.company_avg_max_sale,
    ROUND((rp.max_sale_value / cb.company_avg_max_sale - 1) * 100, 2) as pct_vs_company_avg
FROM region_performance rp
CROSS JOIN company_benchmark cb
WHERE rp.max_sale_value < 5000
ORDER BY rp.max_sale_value DESC;

-- Index Recommendations:
-- CREATE INDEX idx_sales_region_amount ON sales(region, sale_amount DESC);
-- CREATE INDEX idx_sales_region_date_amount ON sales(region, sale_date, sale_amount);

-- =====================================================
-- AGGREGATE FUNCTIONS (5 Questions)
-- =====================================================

-- 1. Compute the median salary for each department
-- Approach: Use PERCENTILE_CONT for accurate median calculation
-- Cross-platform note: Median functions vary across databases

-- PostgreSQL/SQL Server/Oracle Solution:
SELECT
    department_id,
    COUNT(*) as employee_count,
    MIN(salary) as min_salary,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) as median_salary,
    AVG(salary) as mean_salary,
    MAX(salary) as max_salary,
    STDDEV(salary) as salary_std_dev,
    -- Additional percentiles for salary distribution analysis
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) as q1_salary,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) as q3_salary,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) as p90_salary
FROM employees
WHERE salary IS NOT NULL
GROUP BY department_id
ORDER BY median_salary DESC;

-- MySQL Alternative (no PERCENTILE_CONT):
-- SELECT
--     department_id,
--     COUNT(*) as employee_count,
--     MIN(salary) as min_salary,
--     CASE
--         WHEN COUNT(*) % 2 = 1 THEN
--             (SELECT salary FROM employees e2
--              WHERE e2.department_id = e1.department_id
--              ORDER BY salary
--              LIMIT 1 OFFSET (COUNT(*) DIV 2))
--         ELSE
--             (SELECT AVG(salary) FROM (
--                 SELECT salary FROM employees e3
--                 WHERE e3.department_id = e1.department_id
--                 ORDER BY salary
--                 LIMIT 2 OFFSET (COUNT(*) DIV 2 - 1)
--             ) t)
--     END as median_salary,
--     AVG(salary) as mean_salary,
--     MAX(salary) as max_salary
-- FROM employees e1
-- WHERE salary IS NOT NULL
-- GROUP BY department_id
-- ORDER BY median_salary DESC;

-- Alternative using window functions (works on most modern databases):
WITH salary_rankings AS (
    SELECT
        department_id,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary) as row_num,
        COUNT(*) OVER (PARTITION BY department_id) as total_count
    FROM employees
    WHERE salary IS NOT NULL
),
median_calc AS (
    SELECT
        department_id,
        AVG(salary) as median_salary
    FROM salary_rankings
    WHERE row_num IN (
        (total_count + 1) / 2,  -- For odd count
        (total_count + 2) / 2   -- For even count
    )
    GROUP BY department_id
)
SELECT
    mc.department_id,
    COUNT(e.employee_id) as employee_count,
    MIN(e.salary) as min_salary,
    mc.median_salary,
    AVG(e.salary) as mean_salary,
    MAX(e.salary) as max_salary,
    -- Salary distribution analysis
    ROUND(mc.median_salary - AVG(e.salary), 2) as median_mean_diff
FROM median_calc mc
JOIN employees e ON mc.department_id = e.department_id
WHERE e.salary IS NOT NULL
GROUP BY mc.department_id, mc.median_salary
ORDER BY mc.median_salary DESC;

-- Index Recommendation:
-- CREATE INDEX idx_employees_dept_salary ON employees(department_id, salary);

-- =====================================================

-- 2. Summarize monthly sales and rank them in descending order
-- Approach: Extract month/year, aggregate sales, apply ranking functions
-- Performance: Index on sale_date for efficient date-based grouping

SELECT
    sales_year,
    sales_month,
    month_name,
    total_sales,
    sale_count,
    avg_sale_amount,
    unique_employees,
    -- Ranking metrics
    RANK() OVER (ORDER BY total_sales DESC) as sales_rank,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) as dense_sales_rank,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) as unique_rank,
    -- Performance analysis
    ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2) as market_share_pct,
    LAG(total_sales) OVER (ORDER BY sales_year, sales_month) as prev_month_sales,
    ROUND(
        ((total_sales - LAG(total_sales) OVER (ORDER BY sales_year, sales_month)) /
         LAG(total_sales) OVER (ORDER BY sales_year, sales_month)) * 100,
        2
    ) as month_over_month_growth
FROM (
    SELECT
        EXTRACT(YEAR FROM sale_date) as sales_year,
        EXTRACT(MONTH FROM sale_date) as sales_month,
        TO_CHAR(sale_date, 'Month') as month_name,  -- PostgreSQL
        -- DATENAME(MONTH, sale_date) as month_name,  -- SQL Server
        -- TO_CHAR(sale_date, 'Month') as month_name,  -- Oracle
        SUM(sale_amount) as total_sales,
        COUNT(*) as sale_count,
        AVG(sale_amount) as avg_sale_amount,
        COUNT(DISTINCT employee_id) as unique_employees
    FROM sales
    GROUP BY
        EXTRACT(YEAR FROM sale_date),
        EXTRACT(MONTH FROM sale_date),
        TO_CHAR(sale_date, 'Month')
) monthly_summary
ORDER BY sales_rank;

-- Cross-platform date extraction:
-- PostgreSQL: EXTRACT(YEAR FROM date), DATE_TRUNC('month', date)
-- MySQL: YEAR(date), MONTH(date), DATE_FORMAT(date, '%Y-%m')
-- SQL Server: YEAR(date), MONTH(date), FORMAT(date, 'yyyy-MM')
-- Oracle: EXTRACT(YEAR FROM date), TRUNC(date, 'MM')

-- Alternative with moving averages:
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', sale_date) as sale_month,
        SUM(sale_amount) as monthly_total,
        COUNT(*) as transaction_count,
        COUNT(DISTINCT employee_id) as active_employees
    FROM sales
    GROUP BY DATE_TRUNC('month', sale_date)
),
sales_with_trends AS (
    SELECT
        sale_month,
        monthly_total,
        transaction_count,
        active_employees,
        -- Trend analysis
        AVG(monthly_total) OVER (
            ORDER BY sale_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as three_month_avg,
        AVG(monthly_total) OVER (
            ORDER BY sale_month
            ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ) as twelve_month_avg,
        -- Ranking
        RANK() OVER (ORDER BY monthly_total DESC) as rank_by_total
    FROM monthly_sales
)
SELECT
    TO_CHAR(sale_month, 'YYYY-MM') as month_year,
    monthly_total,
    transaction_count,
    active_employees,
    rank_by_total,
    ROUND(three_month_avg, 2) as three_month_avg,
    ROUND(twelve_month_avg, 2) as twelve_month_avg,
    -- Performance indicators
    CASE
        WHEN monthly_total > twelve_month_avg * 1.1 THEN 'Above Average'
        WHEN monthly_total < twelve_month_avg * 0.9 THEN 'Below Average'
        ELSE 'Average'
    END as performance_category
FROM sales_with_trends
ORDER BY rank_by_total;

-- Index Recommendations:
-- CREATE INDEX idx_sales_date_amount_emp ON sales(sale_date, sale_amount, employee_id);

-- =====================================================

-- 3. Count the number of unique customers for each product
-- Approach: COUNT(DISTINCT) with comprehensive product analysis
-- Performance: Index on (product_id, customer_id) for efficient distinct counting

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    COUNT(o.order_id) as total_orders,
    SUM(o.order_value) as total_revenue,
    AVG(o.order_value) as avg_order_value,
    MIN(o.order_date) as first_order_date,
    MAX(o.order_date) as last_order_date,
    -- Customer penetration metrics
    ROUND(
        COUNT(DISTINCT o.customer_id) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id) FROM orders),
        2
    ) as customer_penetration_pct,
    -- Repeat customer analysis
    ROUND(
        COUNT(o.order_id) * 1.0 / COUNT(DISTINCT o.customer_id),
        2
    ) as avg_orders_per_customer
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name, p.category, p.price
ORDER BY unique_customers DESC, total_revenue DESC;

-- Advanced analysis with customer segmentation:
WITH product_customer_analysis AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        COUNT(o.order_id) as total_orders,
        SUM(o.order_value) as total_revenue,
        -- Customer value segmentation
        COUNT(DISTINCT CASE WHEN customer_totals.customer_value > 1000 THEN o.customer_id END) as high_value_customers,
        COUNT(DISTINCT CASE WHEN customer_totals.customer_value BETWEEN 500 AND 1000 THEN o.customer_id END) as medium_value_customers,
        COUNT(DISTINCT CASE WHEN customer_totals.customer_value < 500 THEN o.customer_id END) as low_value_customers
    FROM products p
    LEFT JOIN orders o ON p.product_id = o.product_id
    LEFT JOIN (
        SELECT
            customer_id,
            SUM(order_value) as customer_value
        FROM orders
        GROUP BY customer_id
    ) customer_totals ON o.customer_id = customer_totals.customer_id
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT
    product_id,
    product_name,
    category,
    unique_customers,
    total_orders,
    total_revenue,
    high_value_customers,
    medium_value_customers,
    low_value_customers,
    -- Customer mix analysis
    ROUND(high_value_customers * 100.0 / NULLIF(unique_customers, 0), 2) as high_value_customer_pct,
    -- Product popularity ranking
    RANK() OVER (ORDER BY unique_customers DESC) as popularity_rank,
    RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank
FROM product_customer_analysis
WHERE unique_customers > 0
ORDER BY unique_customers DESC;

-- Performance optimization for large datasets:
-- Consider using approximate count distinct for very large tables
-- PostgreSQL: SELECT APPROX_COUNT_DISTINCT(customer_id)
-- SQL Server: SELECT APPROX_COUNT_DISTINCT(customer_id)

-- Index Recommendations:
-- CREATE INDEX idx_orders_product_customer ON orders(product_id, customer_id, order_value);
-- CREATE INDEX idx_products_category_id ON products(category, product_id);

-- =====================================================

-- 4. Identify the top five regions based on total sales
-- Approach: Aggregate by region, rank and limit to top 5
-- Performance: Index on (region, sale_amount) for efficient aggregation

WITH region_performance AS (
    SELECT
        region,
        SUM(sale_amount) as total_sales,
        COUNT(*) as sale_count,
        COUNT(DISTINCT employee_id) as active_employees,
        AVG(sale_amount) as avg_sale_amount,
        MIN(sale_amount) as min_sale_amount,
        MAX(sale_amount) as max_sale_amount,
        STDDEV(sale_amount) as sale_amount_stddev,
        MIN(sale_date) as first_sale_date,
        MAX(sale_date) as last_sale_date
    FROM sales
    GROUP BY region
),
region_rankings AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank,
        RANK() OVER (ORDER BY avg_sale_amount DESC) as avg_sale_rank,
        RANK() OVER (ORDER BY sale_count DESC) as volume_rank,
        -- Market share calculation
        ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2) as market_share_pct,
        -- Performance consistency (coefficient of variation)
        ROUND((sale_amount_stddev / avg_sale_amount) * 100, 2) as coefficient_of_variation
    FROM region_performance
)
SELECT
    sales_rank,
    region,
    total_sales,
    market_share_pct,
    sale_count,
    active_employees,
    avg_sale_amount,
    avg_sale_rank,
    volume_rank,
    coefficient_of_variation,
    first_sale_date,
    last_sale_date,
    -- Performance indicators
    CASE
        WHEN coefficient_of_variation < 50 THEN 'Consistent'
        WHEN coefficient_of_variation < 100 THEN 'Moderate Variance'
        ELSE 'High Variance'
    END as performance_consistency,
    -- Sales productivity
    ROUND(total_sales / active_employees, 2) as sales_per_employee
FROM region_rankings
WHERE sales_rank <= 5
ORDER BY sales_rank;

-- Alternative with additional metrics:
SELECT
    region,
    total_sales,
    sale_count,
    avg_sale_amount,
    active_employees,
    -- Growth analysis (requires historical data)
    LAG(total_sales) OVER (ORDER BY region) as prev_period_sales,
    -- Efficiency metrics
    ROUND(total_sales / sale_count, 2) as revenue_per_transaction,
    ROUND(total_sales / active_employees, 2) as revenue_per_employee,
    -- Regional performance score (weighted)
    ROUND(
        (total_sales * 0.4 + avg_sale_amount * sale_count * 0.3 + active_employees * avg_sale_amount * 0.3) /
        (SELECT MAX(total_sales) FROM (
            SELECT SUM(sale_amount) as total_sales
            FROM sales
            GROUP BY region
        ) max_sales) * 100,
        2
    ) as performance_score
FROM (
    SELECT
        region,
        SUM(sale_amount) as total_sales,
        COUNT(*) as sale_count,
        AVG(sale_amount) as avg_sale_amount,
        COUNT(DISTINCT employee_id) as active_employees
    FROM sales
    GROUP BY region
) region_summary
ORDER BY total_sales DESC
LIMIT 5;

-- Comparative analysis with benchmarks:
WITH region_stats AS (
    SELECT
        region,
        SUM(sale_amount) as total_sales,
        COUNT(*) as sale_count,
        AVG(sale_amount) as avg_sale_amount
    FROM sales
    GROUP BY region
),
benchmarks AS (
    SELECT
        AVG(total_sales) as avg_region_sales,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY total_sales) as top_20_threshold
    FROM region_stats
)
SELECT
    rs.region,
    rs.total_sales,
    rs.sale_count,
    rs.avg_sale_amount,
    b.avg_region_sales,
    ROUND((rs.total_sales / b.avg_region_sales - 1) * 100, 2) as vs_average_pct,
    CASE
        WHEN rs.total_sales >= b.top_20_threshold THEN 'Top Performer'
        WHEN rs.total_sales >= b.avg_region_sales THEN 'Above Average'
        ELSE 'Below Average'
    END as performance_category,
    ROW_NUMBER() OVER (ORDER BY rs.total_sales DESC) as rank
FROM region_stats rs
CROSS JOIN benchmarks b
WHERE ROW_NUMBER() OVER (ORDER BY rs.total_sales DESC) <= 5
ORDER BY rs.total_sales DESC;

-- Index Recommendations:
-- CREATE INDEX idx_sales_region_amount_date ON sales(region, sale_amount, sale_date);
-- CREATE INDEX idx_sales_region_employee ON sales(region, employee_id, sale_amount);

-- =====================================================

-- 5. Calculate the average order value for every customer
-- Approach: GROUP BY customer with comprehensive customer analysis
-- Performance: Index on (customer_id, order_value) for efficient grouping

SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    c.registration_date,
    COALESCE(customer_metrics.order_count, 0) as total_orders,
    COALESCE(customer_metrics.total_order_value, 0) as total_spent,
    COALESCE(customer_metrics.avg_order_value, 0) as avg_order_value,
    customer_metrics.min_order_value,
    customer_metrics.max_order_value,
    customer_metrics.first_order_date,
    customer_metrics.last_order_date,
    -- Customer lifecycle analysis
    CASE
        WHEN customer_metrics.order_count IS NULL THEN 'No Orders'
        WHEN customer_metrics.order_count = 1 THEN 'Single Purchase'
        WHEN customer_metrics.order_count <= 5 THEN 'Occasional'
        WHEN customer_metrics.order_count <= 15 THEN 'Regular'
        ELSE 'Frequent'
    END as customer_segment,
    -- Time-based metrics
    CASE
        WHEN customer_metrics.first_order_date IS NOT NULL THEN
            EXTRACT(DAY FROM (customer_metrics.last_order_date - customer_metrics.first_order_date))
        ELSE NULL
    END as customer_lifespan_days,
    -- Value-based ranking
    RANK() OVER (ORDER BY customer_metrics.avg_order_value DESC) as avg_order_value_rank,
    RANK() OVER (ORDER BY customer_metrics.total_order_value DESC) as total_value_rank
FROM customers c
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(*) as order_count,
        SUM(order_value) as total_order_value,
        AVG(order_value) as avg_order_value,
        MIN(order_value) as min_order_value,
        MAX(order_value) as max_order_value,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        STDDEV(order_value) as order_value_stddev
    FROM orders
    GROUP BY customer_id
) customer_metrics ON c.customer_id = customer_metrics.customer_id
ORDER BY customer_metrics.avg_order_value DESC NULLS LAST;

-- Advanced customer analysis with percentiles:
WITH customer_order_analysis AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.region,
        c.registration_date,
        COUNT(o.order_id) as order_count,
        SUM(o.order_value) as total_order_value,
        AVG(o.order_value) as avg_order_value,
        -- Percentile analysis of order values
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY o.order_value) as median_order_value,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY o.order_value) as q1_order_value,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY o.order_value) as q3_order_value,
        MIN(o.order_value) as min_order_value,
        MAX(o.order_value) as max_order_value
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.region, c.registration_date
),
customer_benchmarks AS (
    SELECT
        AVG(avg_order_value) as company_avg_order_value,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY avg_order_value) as top_20_avg_threshold
    FROM customer_order_analysis
    WHERE order_count > 0
)
SELECT
    coa.customer_id,
    coa.customer_name,
    coa.region,
    coa.order_count,
    coa.total_order_value,
    coa.avg_order_value,
    coa.median_order_value,
    cb.company_avg_order_value,
    -- Performance vs company average
    ROUND(
        (coa.avg_order_value / cb.company_avg_order_value - 1) * 100,
        2
    ) as vs_company_avg_pct,
    -- Customer value tier
    CASE
        WHEN coa.avg_order_value >= cb.top_20_avg_threshold THEN 'Premium'
        WHEN coa.avg_order_value >= cb.company_avg_order_value THEN 'Standard'
        WHEN coa.order_count > 0 THEN 'Economy'
        ELSE 'Inactive'
    END as customer_tier,
    -- Order consistency (coefficient of variation)
    CASE
        WHEN coa.order_count > 1 THEN
            ROUND(((coa.q3_order_value - coa.q1_order_value) / coa.median_order_value) * 100, 2)
        ELSE NULL
    END as order_consistency_score
FROM customer_order_analysis coa
CROSS JOIN customer_benchmarks cb
ORDER BY coa.avg_order_value DESC NULLS LAST;

-- Customer lifetime value prediction:
WITH customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) as order_count,
        AVG(order_value) as avg_order_value,
        SUM(order_value) as total_value,
        MAX(order_date) as last_order_date,
        MIN(order_date) as first_order_date,
        -- Order frequency (orders per month)
        CASE
            WHEN MAX(order_date) != MIN(order_date) THEN
                COUNT(*) * 30.0 / EXTRACT(DAY FROM (MAX(order_date) - MIN(order_date)))
            ELSE NULL
        END as orders_per_month
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    cm.order_count,
    cm.avg_order_value,
    cm.total_value,
    cm.orders_per_month,
    -- Predicted annual value (simplified)
    CASE
        WHEN cm.orders_per_month IS NOT NULL THEN
            ROUND(cm.orders_per_month * 12 * cm.avg_order_value, 2)
        ELSE NULL
    END as predicted_annual_value,
    -- Recency analysis
    EXTRACT(DAY FROM (CURRENT_DATE - cm.last_order_date)) as days_since_last_order,
    CASE
        WHEN EXTRACT(DAY FROM (CURRENT_DATE - cm.last_order_date)) <= 30 THEN 'Active'
        WHEN EXTRACT(DAY FROM (CURRENT_DATE - cm.last_order_date)) <= 90 THEN 'At Risk'
        ELSE 'Inactive'
    END as customer_status
FROM customers c
JOIN customer_metrics cm ON c.customer_id = cm.customer_id
ORDER BY cm.avg_order_value DESC;

-- Index Recommendations:
-- CREATE INDEX idx_orders_customer_value_date ON orders(customer_id, order_value, order_date);
-- CREATE INDEX idx_customers_region_reg_date ON customers(region, registration_date);

-- =====================================================
-- INDEXING AND PERFORMANCE (5 Questions)
-- =====================================================

-- 1. Write a query to locate duplicate entries in a column with an index
-- Approach: Leverage index for efficient duplicate detection
-- Performance: Demonstrate index usage vs full table scan

-- Create index for demonstration (commented out - would be created separately):
-- CREATE INDEX idx_customers_email ON customers(email);
-- CREATE INDEX idx_customers_phone ON customers(phone);

-- Efficient duplicate detection using indexed columns:
SELECT
    email,
    COUNT(*) as duplicate_count,
    STRING_AGG(customer_id::TEXT, ', ' ORDER BY customer_id) as customer_ids,
    MIN(customer_id) as keep_customer_id,
    MAX(customer_id) as latest_customer_id
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, email;

-- Performance comparison query (with execution plan analysis):
-- Method 1: Using indexed column (efficient)
EXPLAIN (ANALYZE, BUFFERS)
SELECT email, COUNT(*)
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;

-- Method 2: Using non-indexed column (slower)
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT customer_name, COUNT(*)
-- FROM customers
-- WHERE customer_name IS NOT NULL
-- GROUP BY customer_name
-- HAVING COUNT(*) > 1;

-- Advanced duplicate analysis with index utilization:
WITH duplicate_analysis AS (
    SELECT
        email,
        customer_id,
        customer_name,
        registration_date,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY registration_date ASC, customer_id ASC) as rn,
        COUNT(*) OVER (PARTITION BY email) as duplicate_count
    FROM customers
    WHERE email IS NOT NULL
)
SELECT
    email,
    duplicate_count,
    customer_id,
    customer_name,
    registration_date,
    CASE
        WHEN rn = 1 THEN 'KEEP - Original'
        ELSE 'DUPLICATE - Consider removal'
    END as action_recommendation,
    -- Data quality metrics
    CASE
        WHEN duplicate_count > 5 THEN 'High duplication'
        WHEN duplicate_count > 2 THEN 'Medium duplication'
        ELSE 'Low duplication'
    END as duplication_severity
FROM duplicate_analysis
WHERE duplicate_count > 1
ORDER BY duplicate_count DESC, email, rn;

-- Index effectiveness query:
-- This query shows how the index is being used
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'customers'
    AND indexname LIKE '%email%';

-- Alternative for SQL Server:
-- SELECT
--     i.name as index_name,
--     s.user_seeks,
--     s.user_scans,
--     s.user_lookups,
--     s.user_updates
-- FROM sys.dm_db_index_usage_stats s
-- JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
-- WHERE OBJECT_NAME(s.object_id) = 'customers';

-- =====================================================

-- 2. Evaluate the effect of a composite index on query performance
-- Approach: Compare queries with and without composite index usage
-- Performance: Demonstrate covering index benefits

-- Composite index creation (commented - would be created separately):
-- CREATE INDEX idx_orders_customer_date_value ON orders(customer_id, order_date, order_value);
-- CREATE INDEX idx_orders_covering ON orders(customer_id, order_date) INCLUDE (order_value, product_id);

-- Query optimized for composite index usage:
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_id,
    COUNT(*) as order_count,
    SUM(order_value) as total_value,
    AVG(order_value) as avg_value,
    MIN(order_date) as first_order,
    MAX(order_date) as last_order
FROM orders
WHERE customer_id BETWEEN 1000 AND 2000
    AND order_date >= '2023-01-01'
    AND order_date < '2024-01-01'
GROUP BY customer_id
ORDER BY customer_id;

-- Performance comparison: Range query vs equality
-- This query benefits from the composite index leading column
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 1500
    AND order_date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY order_date;

-- Index coverage analysis:
WITH index_usage AS (
    SELECT
        customer_id,
        order_date,
        order_value,
        -- This query should use index-only scan with covering index
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as recent_order_rank
    FROM orders
    WHERE customer_id IN (1001, 1002, 1003, 1004, 1005)
)
SELECT
    customer_id,
    order_date,
    order_value
FROM index_usage
WHERE recent_order_rank <= 3
ORDER BY customer_id, recent_order_rank;

-- Composite index effectiveness test:
-- Test different WHERE clause orders to show index column order importance
-- Query 1: Follows index column order (efficient)
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM orders
WHERE customer_id > 1000
    AND order_date > '2023-01-01'
    AND order_value > 100;

-- Query 2: Doesn't follow index column order (less efficient)
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM orders
WHERE order_date > '2023-01-01'
    AND order_value > 100
    AND customer_id > 1000;

-- Index statistics query to show composite index usage:
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    -- Index efficiency ratio
    CASE
        WHEN idx_tup_read > 0 THEN
            ROUND((idx_tup_fetch::DECIMAL / idx_tup_read) * 100, 2)
        ELSE 0
    END as efficiency_ratio
FROM pg_stat_user_indexes
WHERE tablename = 'orders'
ORDER BY idx_scan DESC;

-- Performance benchmark query:
-- Shows the difference between using and not using the composite index
WITH performance_test AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date) as order_month,
        SUM(order_value) as monthly_total,
        COUNT(*) as monthly_orders
    FROM orders
    WHERE customer_id BETWEEN 1000 AND 5000  -- Uses index efficiently
        AND order_date >= '2023-01-01'
        AND order_date < '2024-01-01'
    GROUP BY customer_id, DATE_TRUNC('month', order_date)
)
SELECT
    customer_id,
    order_month,
    monthly_total,
    monthly_orders,
    AVG(monthly_total) OVER (
        PARTITION BY customer_id
        ORDER BY order_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as rolling_avg
FROM performance_test
ORDER BY customer_id, order_month;

-- =====================================================

-- 3. Identify high-cardinality columns that could benefit from indexing
-- Approach: Analyze column statistics to identify indexing candidates
-- Performance: Query system catalogs for cardinality analysis

-- PostgreSQL column cardinality analysis:
WITH column_stats AS (
    SELECT
        schemaname,
        tablename,
        attname as column_name,
        n_distinct,
        correlation,
        -- Estimate actual cardinality
        CASE
            WHEN n_distinct > 0 THEN n_distinct
            WHEN n_distinct < 0 THEN ABS(n_distinct) * reltuples
            ELSE NULL
        END as estimated_distinct_values,
        reltuples as table_rows
    FROM pg_stats ps
    JOIN pg_class pc ON ps.tablename = pc.relname
    WHERE schemaname = 'public'
        AND tablename IN ('customers', 'orders', 'employees', 'products', 'sales')
),
index_candidates AS (
    SELECT
        tablename,
        column_name,
        estimated_distinct_values,
        table_rows,
        -- Cardinality ratio (selectivity)
        CASE
            WHEN table_rows > 0 THEN
                ROUND((estimated_distinct_values / table_rows) * 100, 2)
            ELSE 0
        END as cardinality_ratio,
        correlation,
        -- Index recommendation score
        CASE
            WHEN estimated_distinct_values / table_rows > 0.1 THEN 'High Priority'
            WHEN estimated_distinct_values / table_rows > 0.05 THEN 'Medium Priority'
            WHEN estimated_distinct_values / table_rows > 0.01 THEN 'Low Priority'
            ELSE 'Not Recommended'
        END as index_recommendation
    FROM column_stats
    WHERE estimated_distinct_values IS NOT NULL
        AND table_rows > 1000  -- Only consider tables with sufficient data
)
SELECT
    tablename,
    column_name,
    estimated_distinct_values,
    table_rows,
    cardinality_ratio,
    correlation,
    index_recommendation,
    -- Specific recommendations
    CASE
        WHEN cardinality_ratio > 50 THEN 'Excellent candidate for B-tree index'
        WHEN cardinality_ratio > 10 THEN 'Good candidate for B-tree index'
        WHEN cardinality_ratio > 1 AND correlation > 0.1 THEN 'Consider for composite index'
        WHEN cardinality_ratio < 1 THEN 'Consider bitmap index (if supported)'
        ELSE 'Low cardinality - not suitable for indexing'
    END as detailed_recommendation
FROM index_candidates
ORDER BY cardinality_ratio DESC, table_rows DESC;

-- Cross-platform alternative using actual queries:
-- This approach works on all database systems
WITH table_analysis AS (
    -- Analyze customers table
    SELECT
        'customers' as table_name,
        'customer_id' as column_name,
        COUNT(DISTINCT customer_id) as distinct_values,
        COUNT(*) as total_rows,
        'Primary Key' as column_type
    FROM customers

    UNION ALL

    SELECT
        'customers',
        'region',
        COUNT(DISTINCT region),
        COUNT(*),
        'Categorical'
    FROM customers

    UNION ALL

    SELECT
        'customers',
        'customer_name',
        COUNT(DISTINCT customer_name),
        COUNT(*),
        'Text'
    FROM customers

    UNION ALL

    -- Analyze orders table
    SELECT
        'orders',
        'customer_id',
        COUNT(DISTINCT customer_id),
        COUNT(*),
        'Foreign Key'
    FROM orders

    UNION ALL

    SELECT
        'orders',
        'order_date',
        COUNT(DISTINCT order_date),
        COUNT(*),
        'Date'
    FROM orders

    UNION ALL

    SELECT
        'orders',
        'order_value',
        COUNT(DISTINCT order_value),
        COUNT(*),
        'Numeric'
    FROM orders
)
SELECT
    table_name,
    column_name,
    column_type,
    distinct_values,
    total_rows,
    ROUND((distinct_values::DECIMAL / total_rows) * 100, 2) as selectivity_pct,
    CASE
        WHEN distinct_values::DECIMAL / total_rows > 0.8 THEN 'Unique - Primary/Unique index'
        WHEN distinct_values::DECIMAL / total_rows > 0.1 THEN 'High selectivity - Good for indexing'
        WHEN distinct_values::DECIMAL / total_rows > 0.01 THEN 'Medium selectivity - Consider composite index'
        ELSE 'Low selectivity - Not suitable for B-tree index'
    END as index_suitability,
    -- Estimated index size (rough calculation)
    CASE
        WHEN column_type = 'Text' THEN total_rows * 20  -- Assume avg 20 bytes
        WHEN column_type = 'Date' THEN total_rows * 8
        WHEN column_type = 'Numeric' THEN total_rows * 8
        ELSE total_rows * 4
    END as estimated_index_size_bytes
FROM table_analysis
ORDER BY selectivity_pct DESC;

-- Query to identify columns used in WHERE clauses (for index recommendations):
-- This would typically be done by analyzing query logs
SELECT
    'orders' as table_name,
    'Frequently filtered columns' as analysis_type,
    'customer_id, order_date, order_value' as recommended_indexes,
    'CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
     CREATE INDEX idx_orders_date_value ON orders(order_date, order_value);' as suggested_ddl

UNION ALL

SELECT
    'customers',
    'Lookup columns',
    'email, phone, region',
    'CREATE INDEX idx_customers_email ON customers(email);
     CREATE INDEX idx_customers_region ON customers(region);'

UNION ALL

SELECT
    'employees',
    'Hierarchy and salary analysis',
    'department_id, manager_id, salary',
    'CREATE INDEX idx_employees_dept_salary ON employees(department_id, salary);
     CREATE INDEX idx_employees_manager ON employees(manager_id);';

-- =====================================================

-- 4. Compare query execution times before and after implementing a clustered index
-- Approach: Demonstrate clustered index impact on range queries and sorting
-- Performance: Show physical data organization benefits

-- Clustered index creation (commented - implementation specific):
-- SQL Server: CREATE CLUSTERED INDEX idx_orders_date_clustered ON orders(order_date);
-- PostgreSQL: CLUSTER orders USING idx_orders_date; (after creating B-tree index)

-- Baseline query performance (before clustered index):
-- Range query that benefits from clustered index
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY order_date;

-- Performance test query - date range aggregation:
EXPLAIN (ANALYZE, BUFFERS)
WITH monthly_aggregates AS (
    SELECT
        DATE_TRUNC('day', order_date) as order_day,
        COUNT(*) as daily_orders,
        SUM(order_value) as daily_revenue,
        AVG(order_value) as avg_order_value
    FROM orders
    WHERE order_date >= '2023-01-01'
        AND order_date < '2024-01-01'
    GROUP BY DATE_TRUNC('day', order_date)
)
SELECT
    order_day,
    daily_orders,
    daily_revenue,
    avg_order_value,
    SUM(daily_revenue) OVER (ORDER BY order_day) as cumulative_revenue
FROM monthly_aggregates
ORDER BY order_day;

-- Sequential scan performance test:
-- This query should show significant improvement with clustered index
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COUNT(*) as total_orders,
    SUM(order_value) as total_revenue,
    MIN(order_date) as first_date,
    MAX(order_date) as last_date
FROM orders
WHERE order_date >= '2023-01-01'
    AND order_date <= '2023-12-31';

-- Page access pattern analysis (PostgreSQL specific):
-- Shows physical I/O improvement with clustered data
SELECT
    heap_blks_read,
    heap_blks_hit,
    idx_blks_read,
    idx_blks_hit,
    -- Cache hit ratio
    ROUND(
        (heap_blks_hit::DECIMAL / (heap_blks_hit + heap_blks_read)) * 100,
        2
    ) as heap_hit_ratio,
    ROUND(
        (idx_blks_hit::DECIMAL / (idx_blks_hit + idx_blks_read)) * 100,
        2
    ) as index_hit_ratio
FROM pg_statio_user_tables
WHERE relname = 'orders';

-- Clustering effectiveness query:
-- Measures how well the physical order matches the logical order
SELECT
    schemaname,
    tablename,
    indexname,
    correlation
FROM pg_stats
WHERE tablename = 'orders'
    AND attname = 'order_date';

-- Performance comparison framework:
-- Create a timing function to measure query performance
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
BEGIN
    -- Time the range query
    start_time := clock_timestamp();

    PERFORM COUNT(*)
    FROM orders
    WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30';

    end_time := clock_timestamp();
    execution_time := end_time - start_time;

    RAISE NOTICE 'Range query execution time: %', execution_time;
END $$;

-- Alternative SQL Server performance comparison:
-- SET STATISTICS TIME ON;
-- SET STATISTICS IO ON;
--
-- SELECT COUNT(*)
-- FROM orders
-- WHERE order_date BETWEEN '2023-06-01' AND '2023-06-30';
--
-- SET STATISTICS TIME OFF;
-- SET STATISTICS IO OFF;

-- Clustered index maintenance analysis:
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    -- Index maintenance cost indicator
    CASE
        WHEN idx_scan > 0 THEN
            ROUND(idx_tup_read::DECIMAL / idx_scan, 2)
        ELSE 0
    END as avg_tuples_per_scan
FROM pg_stat_user_indexes
WHERE tablename = 'orders'
    AND indexname LIKE '%clustered%'
ORDER BY idx_scan DESC;

-- =====================================================

-- 5. Write a query that bypasses indexing to observe performance variations
-- Approach: Force full table scan to demonstrate index value
-- Performance: Use query hints and functions to disable index usage

-- Force full table scan using functions that disable index usage:
-- Method 1: Using functions on indexed columns
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_id,
    customer_name,
    email
FROM customers
WHERE UPPER(email) = UPPER('john.doe@email.com')  -- Function disables index on email
    OR LENGTH(customer_name) > 10;  -- Function disables index on customer_name

-- Method 2: Using arithmetic operations on indexed columns:
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE customer_id + 0 = 1500  -- Adding 0 disables index on customer_id
    AND order_date + INTERVAL '0 days' BETWEEN '2023-01-01' AND '2023-12-31';

-- Method 3: Using OR conditions that force full scan:
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    employee_id,
    first_name,
    last_name,
    salary
FROM employees
WHERE salary > 50000
    OR employee_id IS NOT NULL;  -- This OR condition forces full scan

-- Method 4: Using inequality operations on low-cardinality columns:
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    product_id,
    product_name,
    category,
    price
FROM products
WHERE category != 'Electronics'  -- Inequality on low-cardinality column
    AND price != 0;

-- Performance comparison: Index vs No Index usage
-- Query 1: Optimized for index usage
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_id,
    order_date,
    order_value
FROM orders
WHERE customer_id = 1500
    AND order_date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY order_date;

-- Query 2: Same logic but bypassing indexes
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_id,
    order_date,
    order_value
FROM orders
WHERE customer_id * 1 = 1500  -- Disable customer_id index
    AND EXTRACT(YEAR FROM order_date) = 2023  -- Disable date index
    AND EXTRACT(MONTH FROM order_date) = 6
ORDER BY order_date + INTERVAL '0 seconds';  -- Disable ORDER BY optimization

-- Using query hints to disable index usage (database specific):
-- PostgreSQL: Use pg_hint_plan extension
-- /*+ SeqScan(orders) */
-- SELECT * FROM orders WHERE customer_id = 1500;

-- SQL Server example:
-- SELECT * FROM orders WITH (INDEX(0))  -- Force table scan
-- WHERE customer_id = 1500;

-- Oracle example:
-- SELECT /*+ FULL(orders) */ * FROM orders
-- WHERE customer_id = 1500;

-- Performance monitoring query to show the difference:
WITH index_usage_stats AS (
    SELECT
        schemaname,
        tablename,
        indexname,
        idx_scan as scans_with_index,
        seq_scan as sequential_scans,
        seq_tup_read as tuples_read_sequentially,
        idx_tup_read as tuples_read_via_index
    FROM pg_stat_user_indexes psi
    JOIN pg_stat_user_tables pst USING (schemaname, tablename)
    WHERE tablename = 'orders'
)
SELECT
    tablename,
    indexname,
    scans_with_index,
    sequential_scans,
    -- Efficiency metrics
    CASE
        WHEN (scans_with_index + sequential_scans) > 0 THEN
            ROUND(
                (scans_with_index::DECIMAL / (scans_with_index + sequential_scans)) * 100,
                2
            )
        ELSE 0
    END as index_usage_percentage,
    tuples_read_via_index,
    tuples_read_sequentially,
    -- Performance indicator
    CASE
        WHEN tuples_read_via_index > 0 AND tuples_read_sequentially > 0 THEN
            ROUND(tuples_read_sequentially::DECIMAL / tuples_read_via_index, 2)
        ELSE NULL
    END as seq_vs_index_ratio
FROM index_usage_stats
ORDER BY index_usage_percentage DESC;

-- Demonstration of index selectivity impact:
-- Low selectivity query (doesn't benefit much from index):
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM employees
WHERE salary > 30000;  -- If most employees earn > 30k, index won't help much

-- High selectivity query (benefits significantly from index):
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM employees
WHERE employee_id = 12345;  -- Unique lookup, index provides huge benefit

-- Cost comparison query:
-- Shows the query planner's cost estimates
EXPLAIN (COSTS, BUFFERS)
SELECT
    o.order_id,
    o.order_date,
    c.customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= '2023-01-01'
ORDER BY o.order_date;

-- Final performance summary:
-- This query summarizes the impact of different query patterns
SELECT
    'Index-Optimized Query' as query_type,
    'Uses indexes effectively' as description,
    'Low cost, fast execution' as expected_performance

UNION ALL

SELECT
    'Index-Bypassing Query',
    'Forces full table scans',
    'High cost, slow execution'

UNION ALL

SELECT
    'Mixed Query',
    'Some parts use indexes, others dont',
    'Variable performance based on data distribution'

UNION ALL

SELECT
    'Recommendation',
    'Always test with representative data volumes',
    'Monitor execution plans in production';

-- =====================================================
-- END OF SQL SOLUTIONS
-- =====================================================

-- PERFORMANCE OPTIMIZATION NOTES:
-- 1. Always analyze execution plans before and after index creation
-- 2. Consider data distribution and query patterns when designing indexes
-- 3. Monitor index usage statistics to identify unused indexes
-- 4. Use covering indexes for frequently accessed columns
-- 5. Partition large tables by date or other logical boundaries
-- 6. Update table statistics regularly for optimal query planning
-- 7. Consider columnstore indexes for analytical workloads
-- 8. Use appropriate data types to minimize storage and improve performance
-- 9. Implement proper constraint checking for data integrity
-- 10. Regular maintenance: REINDEX, UPDATE STATISTICS, ANALYZE TABLE

-- CROSS-PLATFORM COMPATIBILITY NOTES:
-- - PostgreSQL: Advanced features like LATERAL joins, array functions
-- - MySQL: Different syntax for string functions, no FULL OUTER JOIN
-- - SQL Server: T-SQL specific functions, excellent window function support
-- - Oracle: Advanced analytical functions, hierarchical queries with CONNECT BY
-- - SQLite: Limited window function support in older versions
-- - Always test queries on target database platform
-- - Use ANSI SQL standards when possible for maximum portability