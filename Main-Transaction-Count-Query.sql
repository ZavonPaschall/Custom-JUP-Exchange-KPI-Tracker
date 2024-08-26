-- This code will be used for the Transaction History Details section of this dashboard. - https://flipsidecrypto.xyz/HitmonleeCrypto/your-total-jupiter-volume-txn-count-checker-dpjD_a

WITH 
-- Filtered swaps data to show only the necessary information on-chain that we will be using to calculate the transaction count for the user provided {{Address}}
filtered_swaps AS (
  SELECT
    DATE_TRUNC('month', block_timestamp) AS month,
    swapper,
    swap_program,
    tx_id,
    EXTRACT(YEAR FROM block_timestamp) AS year
  FROM
    solana.defi.ez_dex_swaps
  WHERE
    (swapper = '{{Address}}' AND swap_program LIKE 'jupiter%')
    OR swapper ILIKE 'DCA%'
    OR (swapper ILIKE 'j1%' AND swap_program ILIKE '%jupiter%')
),
  
-- Monthly trade transactions count
monthly_trade_transactions AS (
  SELECT
    month,
    COUNT(DISTINCT tx_id) AS trade_transactions
  FROM
    filtered_swaps
  WHERE
    swapper = '{{Address}}' AND swap_program LIKE 'jupiter%'
  GROUP BY
    month
),
  
-- Monthly DCA transactions count
monthly_dca_transactions AS (
  SELECT
    DATE_TRUNC('month', s.block_timestamp) AS month,
    COUNT(DISTINCT s.tx_id) AS dca_transactions
  FROM
    solana.defi.ez_dex_swaps AS s
  INNER JOIN 
    solana.core.fact_transfers AS t
    ON t.tx_id = s.tx_id
  WHERE 
    t.tx_to = '{{Address}}'
    AND s.swapper ILIKE 'DCA%'
  GROUP BY
    month
),
-- Monthly limit transactions count
monthly_limit_transactions AS (
  SELECT
    DATE_TRUNC('month', s.block_timestamp) AS month,
    COUNT(DISTINCT s.tx_id) AS limit_transactions
  FROM
    solana.defi.ez_dex_swaps AS s
  INNER JOIN 
    solana.core.fact_transfers AS t
    ON t.tx_id = s.tx_id
  WHERE 
    s.swapper ILIKE 'j1%'
    AND t.tx_to LIKE '{{Address}}'
    AND swap_program ILIKE '%jupiter%'
  GROUP BY
    month
),
-- Union of all relevant months and data
all_months AS (
  SELECT DISTINCT month FROM monthly_trade_transactions
  UNION
  SELECT DISTINCT month FROM monthly_dca_transactions
  UNION
  SELECT DISTINCT month FROM monthly_limit_transactions
)

  -- Finally we can select all of the variables from our various CTE's and then calculate the total volume within 2024 and prior to 2024. 
SELECT
  m.month,
  COALESCE(mt.trade_transactions, 0) AS trade_transactions,
  COALESCE(md.dca_transactions, 0) AS dca_transactions,
  COALESCE(ml.limit_transactions, 0) AS limit_transactions,
  COALESCE(mt.trade_transactions, 0) + COALESCE(md.dca_transactions, 0) + COALESCE(ml.limit_transactions, 0) AS total_transactions,
  SUM(COALESCE(mt.trade_transactions, 0) + COALESCE(md.dca_transactions, 0) + COALESCE(ml.limit_transactions, 0)) OVER (ORDER BY m.month) AS running_total_transactions,
  SUM(COALESCE(mt.trade_transactions, 0)) OVER (ORDER BY m.month) AS running_total_trade_transactions,
  SUM(COALESCE(md.dca_transactions, 0)) OVER (ORDER BY m.month) AS running_total_dca_transactions,
  SUM(COALESCE(ml.limit_transactions, 0)) OVER (ORDER BY m.month) AS running_total_limit_transactions,
  SUM(CASE WHEN EXTRACT(YEAR FROM m.month) = 2024 THEN COALESCE(mt.trade_transactions, 0) + COALESCE(md.dca_transactions, 0) + COALESCE(ml.limit_transactions, 0) ELSE 0 END) OVER () AS total_transactions_2024,
  SUM(CASE WHEN EXTRACT(YEAR FROM m.month) < 2024 THEN COALESCE(mt.trade_transactions, 0) + COALESCE(md.dca_transactions, 0) + COALESCE(ml.limit_transactions, 0) ELSE 0 END) OVER () AS total_transactions_before_2024,
  ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM m.month) = 2024 THEN COALESCE(mt.trade_transactions, 0) + COALESCE(md.dca_transactions, 0) + COALESCE(ml.limit_transactions, 0) ELSE 0 END) OVER () * 100.0 / SUM(COALESCE(mt.trade_transactions, 0) + COALESCE(md.dca_transactions, 0) + COALESCE(ml.limit_transactions, 0)) OVER (), 2) AS pct_transactions_2024,
  ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM m.month) < 2024 THEN COALESCE(mt.trade_transactions, 0) + COALESCE(md.dca_transactions, 0) + COALESCE(ml.limit_transactions, 0) ELSE 0 END) OVER () * 100.0 / SUM(COALESCE(mt.trade_transactions, 0) + COALESCE(md.dca_transactions, 0) + COALESCE(ml.limit_transactions, 0)) OVER (), 2) AS pct_transactions_before_2024

FROM
  all_months m
LEFT JOIN
  monthly_trade_transactions mt ON m.month = mt.month
LEFT JOIN
  monthly_dca_transactions md ON m.month = md.month
LEFT JOIN
  monthly_limit_transactions ml ON m.month = ml.month
ORDER BY
  m.month DESC;
