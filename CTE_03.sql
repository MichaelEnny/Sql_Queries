-- 3. Generate a sequence of Fibonacci numbers up to a specific value using a recursive CTE

WITH RECURSIVE fibonacci_sequence AS (
  -- Base row
  SELECT
    1 AS position,
    0 AS fib_number,
    1 AS next_fib
  UNION ALL
  -- Recursive step
  SELECT
    position + 1,
    next_fib,
    fib_number + next_fib
  FROM fibonacci_sequence
  WHERE next_fib <= 1000
    AND position < 50
)
SELECT
  position,
  fib_number,
  CASE
    WHEN position > 1 THEN
      ROUND(
        CAST(fib_number AS DECIMAL(30,10)) /
        NULLIF(LAG(fib_number) OVER (ORDER BY position), 0),
        6
      )
    ELSE NULL
  END AS golden_ratio_approximation
FROM fibonacci_sequence
WHERE fib_number <= 1000
ORDER BY position;
