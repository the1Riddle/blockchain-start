#!/usr/bin/env bash
# =============================================================================
# Bitcoin Regtest Setup Script
# =============================================================================
# This script helps you quickly set up a regtest environment with two wallets
# (Alice & Bob), generate blocks, send a transaction, and create different
# address types.

set -euo pipefail

echo "=== Bitcoin Regtest Setup Script ==="
echo

REGTEST_RUNNING=false

# Check if bitcoind is already running on regtest
if bitcoin-cli -regtest getblockchaininfo >/dev/null 2>&1; then
    echo "✓ Bitcoin daemon is already running on regtest."
    REGTEST_RUNNING=true
else
    echo "Bitcoin daemon is not running."
    read -p "Do you want to start it now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting bitcoind in regtest mode..."
        bitcoind -regtest -daemon -server -txindex=1
        
        echo "Waiting for bitcoind to initialize..."
        sleep 3
        
        # Wait until it's responsive
        for i in {1..20}; do
            if bitcoin-cli -regtest getblockchaininfo >/dev/null 2>&1; then
                echo "✓ Bitcoin daemon started successfully."
                REGTEST_RUNNING=true
                break
            fi
            sleep 1
        done
        
        if [[ "$REGTEST_RUNNING" != true ]]; then
            echo "XXX Failed to start bitcoind. Please check logs. XXX"
            exit 1
        fi
    else
        echo "Exiting. Please start bitcoind manually with: bitcoind -regtest -daemon"
        exit 1
    fi
fi

echo
echo "Creating wallets: alice and bob..."

bitcoin-cli -regtest createwallet "alice" >/dev/null 2>&1 || true
bitcoin-cli -regtest createwallet "bob"   >/dev/null 2>&1 || true


echo "Generating addresses..."

ALICE=$(bitcoin-cli -regtest -rpcwallet=alice getnewaddress "" "bech32")
BOB=$(bitcoin-cli -regtest -rpcwallet=bob getnewaddress "" "bech32")

echo "Alice's address: $ALICE"
echo "Bob's address:   $BOB"


echo
echo "Mining 101 blocks to Alice..."
bitcoin-cli -regtest generatetoaddress 101 "$ALICE" >/dev/null


echo "Sending 10 BTC from Alice to Bob..."
TXID=$(bitcoin-cli -regtest -rpcwallet=alice sendtoaddress "$BOB" 10)

echo "Transaction ID: $TXID"

echo "Mining 1 confirmation block..."
bitcoin-cli -regtest generatetoaddress 1 "$ALICE" >/dev/null


echo
echo "Generating different address types for Alice..."
LEGACY=$(bitcoin-cli -regtest -rpcwallet=alice getnewaddress "" "legacy")
BECH32=$(bitcoin-cli -regtest -rpcwallet=alice getnewaddress "" "bech32")
BECH32M=$(bitcoin-cli -regtest -rpcwallet=alice getnewaddress "" "bech32m")

echo "Legacy (P2PKH):   $LEGACY"
echo "Bech32 (P2WPKH):  $BECH32"
echo "Bech32m (P2TR):   $BECH32M"

echo
echo "✓ Regtest setup completed successfully!"
echo
bitcoin-cli -regtest -rpcwallet=alice getbalance | xargs echo "Alice balance:"
bitcoin-cli -regtest -rpcwallet=bob getbalance   | xargs echo "Bob balance:"


if [[ "$REGTEST_RUNNING" != false ]]; then
    echo
    echo "Stopping bitcoind (since we started it)..."
    bitcoin-cli -regtest stop
fi

echo
echo "You can start the regtest daemon anytime with:"
echo "   bitcoind -regtest"
echo
echo "Useful commands:"
echo "   bitcoin-cli -regtest getblockchaininfo"
echo "   bitcoin-cli -regtest -rpcwallet=alice getbalance"
