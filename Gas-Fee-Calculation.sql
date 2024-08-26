-- this query will be able to sum the Transaction fees that the provided {{Address}} has done overtime and then convert the value from Lamports to SOL for better understanding by the user. 

SELECT
        sum(tx.fee) as lamport_fees,
        sum(tx.fee) / 1000000000 as sol_fees,
        count(tx.fee) as fee_count,
        (sum(tx.fee) / 1000000000) / count(tx.fee) as avg_sol_fee
  FROM
    solana.core.fact_transactions tx
  JOIN
   solana.defi.ez_dex_swaps s ON tx.tx_id = s.tx_id
  WHERE
    s.swapper = '{{Address}}'
