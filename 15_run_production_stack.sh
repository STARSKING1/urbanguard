#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}  URBANGUARD RESILIENCE ENGINE - FULL PRODUCTION STACK    ${NC}"
echo -e "${BLUE}==========================================================${NC}"

# 1. Initialize PQC Cryptography & Watchdog
bash 12_pqc_hybrid_kem.sh
bash 14_self_healing_watchdog.sh

# 2. Run Production Launcher & System Diagnostics
bash 11_production_launcher.sh

echo -e "${GREEN}==========================================================${NC}"
echo -e "${GREEN}  FULL SYSTEM ONLINE & OPERATIONAL IN TERMUX               ${NC}"
echo -e "${GREEN}==========================================================${NC}"
