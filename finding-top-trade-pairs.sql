-- This query is designed to identify the top trading pairs for a specific wallet, based on the volume of assets traded. 
-- By analyzing the amount of each asset sold and bought, the query calculates the total traded amounts and the slippage incurred for each trading pair.
-- This code will be used for this dashboard - https://flipsidecrypto.xyz/HitmonleeCrypto/your-total-jupiter-volume-txn-count-checker-dpjD_a


select 
    swap_from_symbol || '-' || swap_to_symbol as "TOP_SWAP_PAIRS (Sold-Bought)",
    sum(swap_from_amount_usd) as total_swap_from_amount_usd, 
    sum(swap_to_amount_usd) as total_swap_to_amount_usd,
    sum(swap_to_amount_usd) - sum(swap_from_amount_usd) AS slippage_usd

from 
    solana.defi.ez_dex_swaps
where 
    swapper = '{{Address}}' 
    and swap_program ILIKE '%jupiter%'
--    and swap_from_amount_usd >= 1 AND
  --  swap_to_amount_usd >= 1
group by 
    swap_from_symbol || '-' || swap_to_symbol
 having 
    "TOP_SWAP_PAIRS (Sold-Bought)" IS NOT NULL AND "TOP_SWAP_PAIRS (Sold-Bought)" <> ''
order by 
    total_swap_from_amount_usd DESC
