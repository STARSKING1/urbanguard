#!/usr/bin/env bash
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure hazards.db contains the spatial hazard payload
if command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 hazards.db "
        CREATE TABLE IF NOT EXISTS hazards (
            id TEXT PRIMARY KEY,
            description TEXT,
            severity TEXT,
            latitude REAL,
            longitude REAL
        );
        INSERT OR REPLACE INTO hazards (id, description, severity, latitude, longitude)
        VALUES ('h1', 'Flash Flood Warning', 'Flood', 12.9716, 77.5946);
    " 2>/dev/null || true
fi

printf "${BLUE}[1/3] Verifying active REST API on port 8080...${NC}\n"
if nc -z 127.0.0.1 8080 2>/dev/null; then
    printf "  • Status: ${GREEN}ONLINE${NC}\n"
else
    bash start_daemons.sh >/dev/null 2>&1
    sleep 2
fi

printf "${BLUE}[2/3] Simulating daemon crash...${NC}\n"
pids=$(ps aux 2>/dev/null | grep "hazard_engine_server" | grep -v "grep" | awk '{print $2}' || true)
if [ -n "$pids" ]; then
    for pid in $pids; do kill -9 "$pid" 2>/dev/null || true; done
fi
sleep 2

printf "${BLUE}[3/3] Executing watchdog recovery pass...${NC}\n"
bash start_daemons.sh >/dev/null 2>&1
sleep 2

if nc -z 127.0.0.1 8080 2>/dev/null; then
    printf "${GREEN}[PASSED] Service successfully restored on port 8080.${NC}\n"
    printf "${CYAN}Endpoint Response Payload:${NC}\n"
    curl -s http://127.0.0.1:8080
    printf "\n"
else
    printf "${RED}[FAILED] Service remains offline.${NC}\n"
    exit 1
fi
