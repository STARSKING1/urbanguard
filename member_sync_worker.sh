#!/usr/bin/env bash
set -euo pipefail
QUEUE_DB="sync_queue.db"
init_queue() {
    sqlite3 "$QUEUE_DB" "CREATE TABLE IF NOT EXISTS pending_mutations (id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT NOT NULL, payload_json TEXT NOT NULL, retry_count INTEGER DEFAULT 0, created_at TEXT NOT NULL);" 2>/dev/null || true
}
enqueue_mutation() {
    init_queue
    sqlite3 "$QUEUE_DB" "INSERT INTO pending_mutations (action, payload_json, created_at) VALUES ('$1', '$2', datetime('now'));" 2>/dev/null || true
}
init_queue
case "${1:-}" in
    --init) init_queue ;;
    --add-pro) enqueue_mutation "UPDATE_PRO_STATUS" '{"user_id":"'"${2:-usr_101}"'","is_pro":true}' ;;
    --update-role) enqueue_mutation "UPDATE_MEMBER_ROLE" '{"user_id":"'"${2:-usr_101}"'","role":"'"${3:-Responder}"'"}' ;;
    --process) echo "[WORKER] Processing queue..." ;;
esac
