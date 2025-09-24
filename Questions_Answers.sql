-- Question 1: Final Account Balance: Write a SQL query to retrieve the final account balance for each account by calculating the 
-- net amount from deposits and withdrawals.
select account_id, sum(
case when transaction_type='deposit' then amount
when transaction_type='withdrawal' then -amount
else 0 end
) as final_account_balance from transactions
group by account_id;

-- Question 2: Average Transaction Amount per User :Write a SQL query to compute the average transaction amount for each user and rank the users 
-- in descending order based on their average transaction amount.
select u.user_id, u.user_name, avg(t.amount) as Avg_transaction,
rank() over (order by avg(t.amount) desc) as ranking from users u
inner join transactions t
on t.sender_id = u.user_id
group by u.user_id, u.user_name
order by avg_transaction;

-- Question 3: Unique Money Transfer Relationships: Write a SQL query to determine the number of unique two-way money
-- transfer relationships, where a two-way relationship is established if a user has sent money to another user and also received money from the same user.
SELECT COUNT(*) AS two_way_relationships
FROM (
  SELECT DISTINCT
         LEAST(t1.sender_id, t1.receiver_id)  AS user_a,
         GREATEST(t1.sender_id, t1.receiver_id) AS user_b
  FROM Transactions t1
  JOIN Transactions t2
    ON t1.sender_id = t2.receiver_id
   AND t1.receiver_id = t2.sender_id
  WHERE t1.transaction_type = 'transfer'
    AND t2.transaction_type = 'transfer'
    AND t1.is_fraud = FALSE
    AND t2.is_fraud = FALSE
) pairs;

-- Question 4: Determining High-Value Customers: Write a SQL query to identify users who, in the last month, have either sent payments over 1000 or 
-- received payments over 5000, excluding those flagged as fraudulent.
SELECT 
  u.user_id,
  u.user_name
FROM Users u
WHERE u.is_fraudulent = FALSE
  AND (
    -- sent > 1000 in the last month
    EXISTS (
      SELECT 1
      FROM Transactions t
      WHERE t.sender_id = u.user_id
        AND t.transaction_type = 'transfer'
        AND t.is_fraud = FALSE
        AND t.amount > 1000
        AND t.transaction_date >= NOW() - INTERVAL 1 MONTH
    )
    OR
    -- received > 5000 in the last month
    EXISTS (
      SELECT 1
      FROM Transactions t
      WHERE t.receiver_id = u.user_id
        AND t.transaction_type = 'transfer'
        AND t.is_fraud = FALSE
        AND t.amount > 5000
        AND t.transaction_date >= NOW() - INTERVAL 1 MONTH
    )
  )
ORDER BY u.user_id;

-- Question 5: Analyzing User Transaction Data: Write a SQL query that calculates the total and average transaction amount for each user, 
-- including only those users who have made at least two transactions.
SELECT
  u.user_id,
  u.user_name,
  COUNT(*) AS txn_count,
  ROUND(SUM(t.amount), 2) AS total_amount,
  ROUND(AVG(t.amount), 2) AS avg_amount
FROM Users u
JOIN Transactions t
  ON t.sender_id = u.user_id
GROUP BY u.user_id, u.user_name
HAVING COUNT(*) >= 2
ORDER BY total_amount DESC;

