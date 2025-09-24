-- 4. Create unique product combinations using a Cross Join while excluding identical product pairs

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