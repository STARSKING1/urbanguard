#!/usr/bin/env bash
set -euo pipefail

KEY_DIR="crypto_keys"
PRIV_KEY="$KEY_DIR/node_private.pem"
PUB_KEY="$KEY_DIR/node_public.pem"

init_node_keys() {
    mkdir -p "$KEY_DIR"
    if [ ! -f "$PRIV_KEY" ]; then
        openssl genpkey -algorithm Ed25519 -out "$PRIV_KEY" 2>/dev/null || true
        openssl pkey -in "$PRIV_KEY" -pubout -out "$PUB_KEY" 2>/dev/null || true
    fi
}

case "${1:-}" in
    --init) init_node_keys ;;
    *) init_node_keys ;;
esac
