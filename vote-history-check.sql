-- This query is designed to count the number of past voting transactions made by a specific wallet on-chain. 
-- It provides a detailed list of transactions where the wallet has participated in voting, along with the total count of such votes.

-- This code will be used for this dashboard - https://flipsidecrypto.xyz/HitmonleeCrypto/your-total-jupiter-volume-txn-count-checker-dpjD_a


select
  block_timestamp,
  signers,
  count(*) over () as total_vote_count,
  program_id,
  tx_id
from
  solana.core.fact_events
where
  program_id = 'GovaE4iu227srtG2s3tZzB4RmWBzw8sTwrCLZz7kN7rY' 
  and '{{Address}}' = signers [0]
order by
  block_timestamp DESC
