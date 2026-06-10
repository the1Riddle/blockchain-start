#!/usr/bin/env bash
# =============================================================================
# Lightning Network Daemon Installer Script (No sudo version)
# =============================================================================
# Note: Automatically detects architecture (amd64, arm64, armv7, etc.)
#       Supported: x86_64, arm64/aarch64, armv6, armv7
#       For others, download manually from:
#       https://github.com/lightningnetwork/lnd/releases
#
# Usage:
#   ./lndSetup.sh
#   ./lndSetup.sh "https://github.com/lightningnetwork/lnd/releases/download/v0.21.0-beta/lnd-linux-amd64-v0.21.0-beta.tar.gz"

set -euo pipefail

# Configuration -----------------------------
VERSION="v0.21.0-beta"

# Detect architecture
detect_arch() {
    local machine
    machine="$(uname -m)"
    case "$machine" in
        x86_64)         echo "amd64" ;;
        aarch64|arm64)  echo "arm64" ;;
        armv7*)         echo "armv7" ;;
        armv6*)         echo "armv6" ;;
        *)
            echo "ERROR: Unsupported architecture: $machine" >&2
            echo "       Download manually from: https://github.com/lightningnetwork/lnd/releases" >&2
            exit 1
            ;;
    esac
}

ARCH="$(detect_arch)"
DEFAULT_URL="https://github.com/lightningnetwork/lnd/releases/download/${VERSION}/lnd-linux-${ARCH}-${VERSION}.tar.gz"

# Use provided URL or fallback to default
URL="${1:-$DEFAULT_URL}"

INSTALL_DIR="$HOME/.local/bin"
EXTRACTED_DIR="lnd-linux-${ARCH}-${VERSION}"

echo "=== Lightning Network Daemon Installer ==="
echo "Detected architecture : $ARCH ($(uname -m))"
echo "Target URL            : $URL"
echo "Installing binaries to: $INSTALL_DIR"
echo

# Detect shell and rc file ------------------
detect_rc_file() {
    # Check the *running* shell first, then fall back to $SHELL
    if [ -n "${BASH_VERSION:-}" ]; then
        echo "$HOME/.bashrc"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        echo "$HOME/.zshrc"
    else
        # Inspect the SHELL env var as a last resort
        case "${SHELL:-}" in
            */zsh)  echo "$HOME/.zshrc"   ;;
            */fish) echo "$HOME/.config/fish/config.fish" ;;
            *)      echo "$HOME/.profile" ;;
        esac
    fi
}

RC_FILE="$(detect_rc_file)"

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Download & Extract ------------------------
echo "Downloading and extracting LND..."
curl -L --progress-bar "$URL" | tar -xz

if [[ ! -d "$EXTRACTED_DIR" ]]; then
    echo "Error: Extraction failed or directory '$EXTRACTED_DIR' not found."
    exit 1
fi

# Install Binaries --------------------------
echo "Installing lnd and lncli..."
install -m 755 "$EXTRACTED_DIR/lncli" "$INSTALL_DIR/"
install -m 755 "$EXTRACTED_DIR/lnd"   "$INSTALL_DIR/"

# Cleanup -----------------------------------
echo "Cleaning up..."
rm -rf "$EXTRACTED_DIR"

# PATH wiring — write to rc file only if not already present
PATH_SNIPPET='
# Added by lndSetup.sh
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin${PATH:+:}$PATH"
fi'

FISH_PATH_SNIPPET='
# Added by lndSetup.sh
fish_add_path "$HOME/.local/bin"'

if ! grep -q '\.local/bin' "$RC_FILE" 2>/dev/null; then
    if [[ "$RC_FILE" == *.fish ]]; then
        printf '%s\n' "$FISH_PATH_SNIPPET" >> "$RC_FILE"
    else
        printf '%s\n' "$PATH_SNIPPET" >> "$RC_FILE"
    fi
    echo "PATH entry added to $RC_FILE"
else
    echo "PATH entry already present in $RC_FILE — skipping."
fi

# Also export for the current session
export PATH="$INSTALL_DIR${PATH:+:}$PATH"

# Verify Installation -----------------------
echo
if command -v lnd >/dev/null 2>&1; then
    echo "=> Installation successful!"
    echo "   lnd version: $(lnd --version | head -n1)"
else
    echo "XXXXXXXXXXXXXXXX ERROR XXXXXXXXXXXXXXXX"
    echo "=> Binaries installed, but 'lnd' not found in PATH."
    echo "   Make sure $INSTALL_DIR is in your PATH."
fi

# Reload instructions -----------------------
echo
echo "Reload your shell config to use lnd immediately:"
echo "   source $RC_FILE"
