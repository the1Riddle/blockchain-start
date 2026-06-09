package blockchain

import (
	"fmt"
)

var txs []struct {
	Category string `json:"category"`
	Amount  float64 `json:"amount"`
	TxID    string `json:"txid"`
	Confirmations int `json:"confirmations"`
}

func ListTransactions(wallet string, count int) error {
	_ = RPC("loadwallet", []any{wallet}, "", nil)

	if err := RPC(
		"listtransactions",
		[]any{"*", count},
		wallet,
		&txs,
	); err != nil {
		return err
	}

	for _, tx := range txs {
		dir := "OUT"
		if tx.Category == "receive" || tx.Category == "generate" || tx.Category == "immature" {
			dir = "IN"
		}
		fmt.Printf("%s %8f BTC | %d confs\n", dir, tx.Amount, tx.Confirmations)
		fmt.Printf("  %s\n", tx.TxID)
		decodeErr := DecodeTransaction(tx.TxID)
		if decodeErr != nil {
			fmt.Printf("  (failed to decode transaction: %s)\n", decodeErr)
		}
		fmt.Println()
	}

	return nil
}
