package blockchain

import (
	"fmt"
)

func ShoWalletBallance(wallet string) error {
	_ = RPC("loadwallet", []any{wallet}, "", nil)
	var balance float64

	if err := RPC(
		"getbalance",
		nil,
		"alice",
		&balance,
	); err != nil {
		return err
	}

	fmt.Printf("Alice has %.8f BTC\n", balance)

	return nil
}
