#!/usr/bin/env bash
set -euo pipefail
TMP_DIR="${TMPDIR:-$HOME/tmp}"
mkdir -p "$TMP_DIR"
DB_TRUST="zero_trust.db"

init_trust_db() {
    sqlite3 "$DB_TRUST" "CREATE TABLE IF NOT EXISTS processed_nonces (nonce TEXT PRIMARY KEY, node_id TEXT NOT NULL, timestamp TEXT NOT NULL);" 2>/dev/null || true
}

verify_and_register_nonce() {
    local node_id="$1" nonce="$2"
    init_trust_db
    local exists
    exists=$(sqlite3 "$DB_TRUST" "SELECT COUNT(*) FROM processed_nonces WHERE nonce='$nonce';" 2>/dev/null || echo "0")
    if [ "$exists" -gt 0 ]; then return 1; fi
    sqlite3 "$DB_TRUST" "INSERT INTO processed_nonces VALUES ('$nonce', '$node_id', datetime('now'));" 2>/dev/null || true
    return 0
}

init_trust_db
if [[ "${1:-}" == "--test-replay" ]]; then
    verify_and_register_nonce "node_test" "nonce_101" || true
    if ! verify_and_register_nonce "node_test" "nonce_101"; then
        echo "[ZERO_TRUST] Anti-Replay Defense Verified."
    fi
else
    echo "[ZERO_TRUST] Registry Ready."
fi
