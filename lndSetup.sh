#!/usr/bin/env bash
# =============================================================================
# Lightning Network Daemon Installer Script (No sudo version)
# =============================================================================
# Note: This script is optimized for x86_64 Linux systems.
#       For other architectures, download the appropriate binary from:
#       https://github.com/lightningnetwork/lnd/releases
#
# Usage:
#   ./lndSetup.sh
#   ./lndSetup.sh "https://github.com/lightningnetwork/lnd/releases/download/v0.21.0-beta/lnd-linux-amd64-v0.21.0-beta.tar.gz"

set -euo pipefail

# Configuration -----------------------------
VERSION="v0.21.0-beta"
DEFAULT_URL="https://github.com/lightningnetwork/lnd/releases/download/${VERSION}/lnd-linux-amd64-${VERSION}.tar.gz"

# Use provided URL or fallback to default
URL="${1:-$DEFAULT_URL}"

INSTALL_DIR="$HOME/.local/bin"

echo "=== Lightning Network Daemon Installer ==="
echo "Target URL: $URL"
echo "Installing binaries to: $INSTALL_DIR"
echo

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

echo "Downloading and extracting LND..."
curl -L --progress-bar "$URL" | tar -xz

EXTRACTED_DIR="lnd-linux-amd64-${VERSION}"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
    echo "Error: Extraction failed or directory not found."
    exit 1
fi

# Install Binaries --------------------------
echo "Installing lnd and lncli..."

install -m 755 "$EXTRACTED_DIR/lncli"       "$INSTALL_DIR/"
install -m 755 "$EXTRACTED_DIR/lnd"         "$INSTALL_DIR/"

# Cleanup -----------------------------------
echo "Cleaning up..."
rm -rf "$EXTRACTED_DIR"

# Verify Installation -----------------------
echo
if command -v lnd >/dev/null 2>&1; then
    echo "=> Installation successful!"
    echo "   lnd version: $(lnd --version | head -n1)"
else
    echo "XXXXXXXXXXXXXXXX ERROR XXXXXXXXXXXXXXXX"
    echo "=> Binaries installed, but 'lndd' not found in PATH."
    echo "   Make sure $INSTALL_DIR is in your PATH."
fi

if [ -n "$BASH_VERSION" ]; then
    rc_file="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    rc_file="$HOME/.zshrc"
else
    rc_file="$HOME/.profile"
fi


# PATH Instructions -------------------------

echo
echo "You can now reload your shell:"
echo "   source ~/.bashrc          # if using bash"
echo "   source ~/.zshrc           # if using zsh"
