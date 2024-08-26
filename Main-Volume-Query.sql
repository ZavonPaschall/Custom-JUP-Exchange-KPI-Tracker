-- This code will be used for the Volume History Details section of this dashboard. - https://flipsidecrypto.xyz/HitmonleeCrypto/your-total-jupiter-volume-txn-count-checker-dpjD_a

WITH 
-- Filtered swaps data for relevant address and conditions, ensuring they all contain the user provided {{Address}} and the specific Swap, DCA and limit trades we are looking for. 
filtered_swaps AS (
  SELECT
    DATE_TRUNC('month', block_timestamp) AS month,
    swap_from_amount_usd,
    swapper,
    swap_program,
    tx_id
  FROM
    solana.defi.ez_dex_swaps
  WHERE
    (swapper = '{{Address}}' AND swap_program LIKE 'jupiter%')
    OR swapper ILIKE 'DCA%'
    OR (swapper ILIKE 'j1%' AND swap_program ILIKE '%jupiter%')
),
  
-- Monthly trade volume 
monthly_trade_volume AS (
  SELECT
    month,
    SUM(swap_from_amount_usd) AS monthly_trade_total
  FROM
    filtered_swaps
  WHERE
    swapper = '{{Address}}' AND swap_program LIKE 'jupiter%'
  GROUP BY
    month
),
  
-- Monthly DCA volume
monthly_dca_volume AS (
  SELECT
    DATE_TRUNC('month', s.block_timestamp) AS month,
    SUM(s.swap_from_amount_usd) AS monthly_dca_total
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
  
-- Monthly limit volume
monthly_limit_volume AS (
  SELECT
    DATE_TRUNC('month', s.block_timestamp) AS month,
    SUM(s.swap_from_amount_usd) AS monthly_limit_total
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
  
-- Union of all relevant months
all_months AS (
  SELECT DISTINCT month FROM monthly_trade_volume
  UNION
  SELECT DISTINCT month FROM monthly_dca_volume
  UNION
  SELECT DISTINCT month FROM monthly_limit_volume
),
  
-- Calculate running totals based on the volumes previously calculated in each CTE
running_totals AS (
  SELECT
    m.month,
    COALESCE(mt.monthly_trade_total, 0) AS monthly_trade_total,
    COALESCE(md.monthly_dca_total, 0) AS monthly_dca_total,
    COALESCE(ml.monthly_limit_total, 0) AS monthly_limit_total,
    COALESCE(mt.monthly_trade_total, 0) + COALESCE(md.monthly_dca_total, 0) + COALESCE(ml.monthly_limit_total, 0) AS total_volume,
    SUM(COALESCE(mt.monthly_trade_total, 0)) OVER (ORDER BY m.month) AS running_trade_total,
    SUM(COALESCE(md.monthly_dca_total, 0)) OVER (ORDER BY m.month) AS running_dca_total,
    SUM(COALESCE(ml.monthly_limit_total, 0)) OVER (ORDER BY m.month) AS running_limit_total,
    SUM(COALESCE(mt.monthly_trade_total, 0) + COALESCE(md.monthly_dca_total, 0) + COALESCE(ml.monthly_limit_total, 0)) OVER (ORDER BY m.month) AS running_total_volume
  FROM
    all_months m
  LEFT JOIN
    monthly_trade_volume mt ON m.month = mt.month
  LEFT JOIN
    monthly_dca_volume md ON m.month = md.month
  LEFT JOIN
    monthly_limit_volume ml ON m.month = ml.month
)
  -- Finally, we can print each of the variables and then lastly calculated the volume in 2024 and prior to 2024
SELECT
  r.month,
  r.monthly_trade_total,
  r.monthly_dca_total,
  r.monthly_limit_total,
  r.total_volume,
  r.running_trade_total,
  r.running_dca_total,
  r.running_limit_total,
  r.running_total_volume,
  SUM(CASE WHEN DATE_PART('year', r.month) = 2024 THEN r.total_volume ELSE 0 END) OVER () AS volume_2024,
  SUM(CASE WHEN DATE_PART('year', r.month) < 2024 THEN r.total_volume ELSE 0 END) OVER () AS volume_prior_2024,
  ROUND((SUM(CASE WHEN DATE_PART('year', r.month) = 2024 THEN r.total_volume ELSE 0 END) OVER () * 100.0) / SUM(r.total_volume) OVER (), 2) AS pct_volume_2024,
  ROUND((SUM(CASE WHEN DATE_PART('year', r.month) < 2024 THEN r.total_volume ELSE 0 END) OVER () * 100.0) / SUM(r.total_volume) OVER (), 2) AS pct_volume_prior_2024
FROM
  running_totals r
ORDER BY
  r.month DESC;
