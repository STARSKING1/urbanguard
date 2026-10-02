#!/usr/bin/env bash
# ==============================================================================
# 33_FIX_AND_START_API_SERVER.SH
# Cleans stale socket locks, verifies dependencies, and starts the REST API
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - REST API DIAGNOSTIC & SERVICE STARTER                             ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Clean stale processes holding port 8080
printf "${BLUE}[1/4] Clearing lingering socket locks on port 8080...${NC}\n"
fuser -k -9 8080/tcp 2>/dev/null || true
pkill -9 -f "hazard_engine_server" 2>/dev/null || true
sleep 1

# 2. Verify script permissions and SQLite database setup
printf "${BLUE}[2/4] Verifying execution permissions and spatial database...${NC}\n"
chmod +x *.sh 2>/dev/null || true

if [ ! -f "hazards.db" ]; then
    printf "${YELLOW}[NOTICE] hazards.db missing. Initializing database schema...${NC}\n"
    sqlite3 hazards.db "
        CREATE TABLE IF NOT EXISTS hazards (
            id TEXT PRIMARY KEY,
            latitude REAL,
            longitude REAL,
            severity TEXT,
            description TEXT,
            timestamp INTEGER
        );
        CREATE VIRTUAL TABLE IF NOT EXISTS hazards_rtree USING rtree(
            id, min_lat, max_lat, min_lng, max_lng
        );
    "
fi

# 3. Direct start of hazard engine REST server
printf "${BLUE}[3/4] Launching hazard_engine_server.sh in background...${NC}\n"

if [ -f "hazard_engine_server.sh" ]; then
    nohup bash hazard_engine_server.sh > api_server_output.log 2>&1 &
    sleep 2
elif [ -f "master_control.sh" ]; then
    bash master_control.sh start-services >/dev/null 2>&1
    sleep 2
fi

# 4. Confirm Port 8080 Socket State
printf "${BLUE}[4/4] Verifying port 8080 listener status...${NC}\n"
if nc -z 127.0.0.1 8080 2>/dev/null || lsof -i:8080 >/dev/null 2>&1; then
    printf "\n${GREEN}[SUCCESS] REST API server successfully active on port 8080!${NC}\n"
else
    printf "\n${RED}[ERROR] Service failed to bind to port 8080. Output log contents:${NC}\n"
    if [ -f "api_server_output.log" ]; then
        cat api_server_output.log
    fi
    exit 1
fi
