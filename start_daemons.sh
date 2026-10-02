#!/usr/bin/env bash
# ==============================================================================
# START_DAEMONS.SH - Multi-Service Background Launcher
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

TMP_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "$TMP_DIR"

# 1. Clean Stale Processes & Sockets
if command -v lsof >/dev/null 2>&1; then
    LSOF_PIDS=$(lsof -t -i:8080 2>/dev/null || true)
    if [ -n "$LSOF_PIDS" ]; then
        for pid in $LSOF_PIDS; do kill -9 "$pid" 2>/dev/null || true; done
    fi
fi
fuser -k -9 8080/tcp 2>/dev/null || true

# 2. Launch REST Spatial API Daemon (:8080)
if [ -f "hazard_engine_server.sh" ]; then
    nohup bash hazard_engine_server.sh > api_server_output.log 2>&1 &
fi

# 3. Launch Self-Healing Watchdog Daemon
if [ -f "14_self_healing_watchdog.sh" ]; then
    nohup bash -c '
    while true; do
        bash 14_self_healing_watchdog.sh --run-once >> watchdog_activity.log 2>&1 || true
        sleep 30
    done
    ' > /dev/null 2>&1 &
fi

# 4. Launch Mutation Sync Worker Daemon
if [ -f "member_sync_worker.sh" ]; then
    nohup bash -c '
    while true; do
        bash member_sync_worker.sh >> sync_worker_activity.log 2>&1 || true
        sleep 15
    done
    ' > /dev/null 2>&1 &
fi

sleep 2
printf "\033[0;32m[SUCCESS] All UrbanGuard background production daemons initialized.\033[0m\n\n"
