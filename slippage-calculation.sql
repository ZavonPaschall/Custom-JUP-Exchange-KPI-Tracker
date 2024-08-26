-- This query is designed to calculate the slippage incurred by a user during their trading activity on a specific exchange. 
-- Slippage is determined by the difference between the total amount spent on trades (in USD) and the total amount received (in USD). 
-- This metric allows the user to understand how their trades are performing on the exchange, particularly in terms of execution quality and cost efficiency.

select sum(swap_from_amount_usd) as total_spent_usd,
       sum(swap_to_amount_usd) as total_received_usd,
       sum(swap_to_amount_usd) - sum(swap_from_amount_usd) as slippage_value_in_usd
   --    count(swap_from_amount_usd) as trade_count,
     --  (sum(swap_from_amount_usd) - sum(swap_to_amount_usd)) / count(swap_from_amount_usd) as your_avg_slippage_loss_per_trade
from (
    select distinct tx_id, swap_program, swap_from_amount_usd, swap_to_amount_usd
    from solana.defi.ez_dex_swaps
    where swapper = '{{Address}}'
    and swap_program ILIKE '%jupiter%'

) as distinct_swaps
