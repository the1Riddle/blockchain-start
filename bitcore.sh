#!/usr/bin/env bash
# =============================================================================
# Bitcoin Core Installer Script (No sudo version)
# =============================================================================
# Note: This script is optimized for x86_64 Linux systems.
#       For other architectures, download the appropriate binary from:
#       https://bitcoincore.org/en/download/
#
# Usage:
#   ./bitcore.sh
#   ./bitcore.sh "https://bitcoincore.org/bin/bitcoin-core-31.0/bitcoin-31.0-x86_64-linux-gnu.tar.gz"

set -euo pipefail

# Configuration -----------------------------
VERSION="31.0"
DEFAULT_URL="https://bitcoincore.org/bin/bitcoin-core-${VERSION}/bitcoin-${VERSION}-x86_64-linux-gnu.tar.gz"

# Use provided URL or fallback to default
URL="${1:-$DEFAULT_URL}"

INSTALL_DIR="$HOME/.local/bin"

echo "=== Bitcoin Core Installer ==="
echo "Target URL: $URL"
echo "Installing binaries to: $INSTALL_DIR"
echo

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

echo "Downloading and extracting Bitcoin Core..."
curl -L --progress-bar "$URL" | tar -xz

EXTRACTED_DIR="bitcoin-${VERSION}"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
    echo "Error: Extraction failed or directory not found."
    exit 1
fi

# Install Binaries --------------------------
echo "Installing bitcoind, bitcoin-cli, bitcoin-qt, bitcoin-tx, and bitcoin-wallet..."

install -m 755 "$EXTRACTED_DIR/bin/bitcoind"        "$INSTALL_DIR/"
install -m 755 "$EXTRACTED_DIR/bin/bitcoin-cli"     "$INSTALL_DIR/"
install -m 755 "$EXTRACTED_DIR/bin/bitcoin-qt"      "$INSTALL_DIR/" 2>/dev/null || true
install -m 755 "$EXTRACTED_DIR/bin/bitcoin-tx"      "$INSTALL_DIR/" 2>/dev/null || true
install -m 755 "$EXTRACTED_DIR/bin/bitcoin-wallet"  "$INSTALL_DIR/" 2>/dev/null || true

# Cleanup -----------------------------------
echo "Cleaning up..."
rm -rf "$EXTRACTED_DIR"

# Verify Installation -----------------------
echo
if command -v bitcoind >/dev/null 2>&1; then
    echo "=> Installation successful!"
    echo "   bitcoind version: $(bitcoind --version | head -n1)"
else
    echo "XXXXXXXXXXXXXXXX ERROR XXXXXXXXXXXXXXXX"
    echo "=> Binaries installed, but 'bitcoind' not found in PATH."
    echo "   Make sure $INSTALL_DIR is in your PATH."
fi

if [ -n "$BASH_VERSION" ]; then
    rc_file="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    rc_file="$HOME/.zshrc"
else
    rc_file="$HOME/.profile"
fi

# Create the config file --------------------

BITCOIN_DIR="$HOME/.bitcoin"
BITCOIN_CONF="$BITCOIN_DIR/bitcoin.conf"

mkdir -p "$BITCOIN_DIR"

if [ -f "$BITCOIN_CONF" ]; then
    echo "=> Existing bitcoin.conf found at:"
    echo "   $BITCOIN_CONF ..."
    echo
    echo "Skipping configuration creation."
else
    RPC_USER="bitcoinrpc"
    RPC_PASSWORD="$(openssl rand -hex 32)"

    cat > "$BITCOIN_CONF" <<EOF
regtest=1
server=1
daemon=1

[regtest]
rpcuser=$RPC_USER
rpcpassword=$RPC_PASSWORD
rpcport=18443

rpcallowip=127.0.0.1
rpcbind=127.0.0.1

fallbackfee=0.0001
EOF

    chmod 600 "$BITCOIN_CONF"

    echo "✓ Yey, Created $BITCOIN_CONF"
    echo
    echo "RPC Credentials:"
    echo "   User: $RPC_USER"
    echo "   Password: $RPC_PASSWORD"
fi


# PATH Instructions -------------------------

echo
echo "You can now reload your shell:"
echo "   source ~/.bashrc          # if using bash"
echo "   source ~/.zshrc           # if using zsh"
echo
echo "Then you can run:"
echo "   bitcoind -regtest"
echo "   bitcoin-cli -regtest getblockchaininfo"
