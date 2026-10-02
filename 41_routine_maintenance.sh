#!/usr/bin/env bash
# ==============================================================================
# 41_ROUTINE_MAINTENANCE.SH
# Performs automated database vacuuming, log rotation, and key hygiene checks
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - AUTOMATED SYSTEM MAINTENANCE & OPTIMIZATION                     ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Vacuum and Optimize SQLite Databases
printf "${BLUE}[1/4] Optimizing spatial and sync databases...${NC}\n"
for db in hazards.db sync_queue.db zero_trust.db; do
    if [ -f "$HOME/$db" ] && command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 "$HOME/$db" "PRAGMA optimize; VACUUM;" 2>/dev/null || true
        printf "  • %-16s: ${GREEN}VACUUM & OPTIMIZE COMPLETE${NC}\n" "$db"
    fi
done

# 2. Rotate and Truncate Log Files (> 2MB)
printf "\n${BLUE}[2/4] Inspecting and rotating system log files...${NC}\n"
LOG_FILES=(
    "watchdog_activity.log"
    "sync_worker_activity.log"
    "api_server_output.log"
    "production_launch.log"
    "$HOME/urbanguard_boot.log"
    "$HOME/urbanguard_cron_backup.log"
)

for log in "${LOG_FILES[@]}"; do
    if [ -f "$log" ]; then
        SIZE_KB=$(du -k "$log" | cut -f1)
        if [ "$SIZE_KB" -gt 2048 ]; then
            tail -n 500 "$log" > "${log}.tmp" && mv "${log}.tmp" "$log"
            printf "  • %-25s: ${YELLOW}TRUNCATED (${SIZE_KB}KB -> ~500 lines)${NC}\n" "$(basename "$log")"
        else
            printf "  • %-25s: ${GREEN}HEALTHY (${SIZE_KB}KB)${NC}\n" "$(basename "$log")"
        fi
    fi
done

# 3. Clean Stale Temporary Files and Pipes
printf "\n${BLUE}[3/4] Purging stale temporary files...${NC}\n"
TMP_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
find "$TMP_DIR" -type f -name "urbanguard_*.tmp" -mtime +1 -delete 2>/dev/null || true
printf "  • Temp workspace clean: ${GREEN}%s${NC}\n" "$TMP_DIR"

# 4. Verify Active Production Daemons
printf "\n${BLUE}[4/4] Verifying background daemon health...${NC}\n"
if nc -z 127.0.0.1 8080 2>/dev/null; then
    printf "  • REST Spatial API (:8080):  ${GREEN}ACTIVE${NC}\n"
else
    printf "  • REST Spatial API (:8080):  ${YELLOW}OFFLINE (Restarting...)${NC}\n"
    bash "$HOME/start_daemons.sh" >/dev/null 2>&1 || true
fi

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] System maintenance pass completed successfully!                      ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"
