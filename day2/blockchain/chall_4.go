package blockchain

import (
	"fmt"
)

var tx struct {
	Vin []struct {
		Coinbase string `json:"coinbase"`
		TxID string `json:"txid"`
		Vout int    `json:"vout"`
	} `json:"vin"`
	Vout []struct {
		Value        float64 `json:"value"`
		ScriptPubKey struct {
			Addresses []string `json:"addresses"`
		} `json:"scriptPubKey"`
	} `json:"vout"`
}

func DecodeTransaction(txid string) error {
	if err := RPC(
		"getrawtransaction",
		[]any{txid, true},
		"",
		&tx,
	); err != nil {
		return err
	}

	for i, vin := range tx.Vin {
		if vin.Coinbase != "" {
			fmt.Printf("Input %d: COINBASE\n", i)
		} else {
			fmt.Printf("Input %d: %s\n", i, vin.TxID)
		}

		fmt.Printf("Input %d: %s:%d\n", i, vin.TxID, vin.Vout)
	}

	for i, vout := range tx.Vout {
		fmt.Printf("Output %d: %.8f BTC to %s\n", i, vout.Value, vout.ScriptPubKey.Addresses)
	}

	return nil
}
