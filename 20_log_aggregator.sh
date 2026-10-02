#!/usr/bin/env bash
# ==============================================================================
# 20_LOG_AGGREGATOR.SH
# Real-time multi-file log tail and stream aggregator for UrbanGuard daemons
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILES=(
    "watchdog_activity.log"
    "production_launch.log"
    "audit_report.log"
    "test_report.log"
    "$HOME/urbanguard_boot.log"
    "$HOME/urbanguard_cron_backup.log"
)

# Ensure log targets exist
for file in "${LOG_FILES[@]}"; do
    touch "$file"
done

clear 2>/dev/null || printf "\033c"
printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD RESILIENCE ENGINE - LIVE LOG STREAM AGGREGATOR                    ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"
printf " Monitoring active logs:\n"
printf "   • Watchdog:    watchdog_activity.log\n"
printf "   • Deployment:  production_launch.log\n"
printf "   • Audit:       audit_report.log\n"
printf "   • E2E Testing: test_report.log\n"
printf "   • Termux Boot: ~/urbanguard_boot.log\n"
printf "   • Cron Backup: ~/urbanguard_cron_backup.log\n"
printf "${BLUE}================================================================================${NC}\n"
printf " [Press Ctrl+C to exit]\n\n"

tail -n 5 -f "${LOG_FILES[@]}" 2>/dev/null
