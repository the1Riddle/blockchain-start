package main

import (
	"fmt"

	"day2/blockchain"
)

type BlockchainInfo struct {
	Chain  string `json:"chain"`
	Blocks int    `json:"blocks"`
}

func Example() error {
	var info BlockchainInfo

	if err := blockchain.RPC(
		"getblockchaininfo",
		nil,
		"",
		&info,
	); err != nil {
		return err
	}

	fmt.Println("Chain:", info.Chain)
	fmt.Println("Blocks:", info.Blocks)

	if err := blockchain.ShoWalletBallance("alice"); err != nil {
		return err
	}

	return nil
}

func main() {
	err := Example()
	if err != nil {
		fmt.Println(err)
	}
}
