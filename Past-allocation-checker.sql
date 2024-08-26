-- In this query, I needed to extract specific account details from a JSON object within the instruction field in the fact_events table.
-- This was done to accurately filter transactions involving the correct recipients (accounts[4] or accounts[3]) of JUP allocations. 
-- Additionally, I checked the transaction logs for the "NewClaim" instruction to ensure only relevant claims were included.

-- This code will be used for this dashboard. - https://flipsidecrypto.xyz/HitmonleeCrypto/your-total-jupiter-volume-txn-count-checker-dpjD_a

WITH claimed_jup AS (
    SELECT 
        t.block_timestamp, 
        t.amount AS JUP_Claimed, 
        p.price AS current_jup_price,
        p.price * t.amount AS current_value_usd,
        t.mint, 
        t.tx_from,
        t.tx_to,  -- Include tx_to here
        t.tx_id,
        e.instruction
    FROM 
        solana.core.fact_transfers t
    JOIN 
        solana.price.ez_prices_hourly p 
    ON 
        t.mint = p.token_address
    AND 
        p.hour = (SELECT MAX(hour) FROM solana.price.ez_prices_hourly WHERE token_address = t.mint)
    INNER JOIN 
        solana.core.fact_events e
    ON 
        t.block_timestamp = e.block_timestamp
    AND 
        t.tx_id = e.tx_id
    INNER JOIN 
        solana.core.fact_transactions tx
    ON 
        t.block_timestamp = tx.block_timestamp
    AND 
        t.tx_id = tx.tx_id
    WHERE 
        tx.succeeded
    AND 
        e.program_id = 'meRjbQXFNf5En86FXT2YPz1dQzLj4Yb3xK8u1MVgqpb'
    AND 
        t.mint = 'JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN'
    AND 
        (t.tx_to = e.instruction:accounts[4] OR t.tx_to = e.instruction:accounts[3])
    AND 
        NOT t.tx_to = t.tx_from
    AND 
        ARRAY_CONTAINS('Program log: Instruction: NewClaim'::variant, tx.log_messages)
)

SELECT 
    *
FROM 
    claimed_jup
WHERE 
    tx_to = '{{Address}}';
