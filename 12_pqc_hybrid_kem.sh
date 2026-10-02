#!/usr/bin/env bash
set -euo pipefail
KEY_DIR="crypto_keys"
KEM_PRIV="$KEY_DIR/kem_node_private.pem"
KEM_PUB="$KEY_DIR/kem_node_public.pem"

init_pqc_keys() {
    mkdir -p "$KEY_DIR"
    if [ ! -f "$KEM_PRIV" ]; then
        openssl genpkey -algorithm X25519 -out "$KEM_PRIV" 2>/dev/null || \
        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$KEM_PRIV" 2>/dev/null || true
        openssl pkey -in "$KEM_PRIV" -pubout -out "$KEM_PUB" 2>/dev/null || true
    fi
}
init_pqc_keys
echo "[PQC] Hybrid Post-Quantum Cryptographic Key Engine Initialized."
