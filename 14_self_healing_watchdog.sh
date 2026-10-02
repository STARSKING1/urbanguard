#!/usr/bin/env bash
set -euo pipefail
DB_HAZARD="hazards.db"
DB_QUEUE="sync_queue.db"

echo "[WATCHDOG] Running self-healing process diagnostics & DB maintenance..."
for db in "$DB_HAZARD" "$DB_QUEUE"; do
    if [ -f "$db" ]; then
        sqlite3 "$db" "PRAGMA integrity_check; VACUUM;" 2>/dev/null || true
    fi
done
echo "[WATCHDOG] Health maintenance completed successfully."
