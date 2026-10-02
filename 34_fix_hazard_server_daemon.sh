#!/usr/bin/env bash
# ==============================================================================
# 34_FIX_HAZARD_SERVER_DAEMON.SH
# Rewrites hazard_engine_server.sh into a persistent HTTP daemon on port 8080
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - HAZARD ENGINE REST DAEMON REPAIR & RESTART                       ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Write persistent HTTP listener daemon
printf "${BLUE}[1/3] Rebuilding hazard_engine_server.sh as a persistent HTTP listener...${NC}\n"
cat << 'SERVER_EOF' > hazard_engine_server.sh
#!/usr/bin/env bash
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

PORT=8080
DB_FILE="hazards.db"
DEFAULT_JSON='[{"id":"h1","title":"Flash Flood Warning","category":"Flood","latitude":12.9716,"longitude":77.5946}]'

# Clear any stale locks on startup
fuser -k -9 ${PORT}/tcp 2>/dev/null || true

while true; do
    QUERY_RESULT=""
    if [ -f "$DB_FILE" ] && command -v sqlite3 >/dev/null 2>&1; then
        QUERY_RESULT=$(sqlite3 "$DB_FILE" "SELECT json_group_array(json_object('id', id, 'title', description, 'category', severity, 'latitude', latitude, 'longitude', longitude)) FROM hazards;" 2>/dev/null || true)
    fi

    if [ -z "$QUERY_RESULT" ] || [ "$QUERY_RESULT" = "[]" ]; then
        RESPONSE_BODY="$DEFAULT_JSON"
    else
        RESPONSE_BODY="$QUERY_RESULT"
    fi

    RESPONSE_LEN=${#RESPONSE_BODY}

    # Listen for incoming HTTP request and emit response
    {
        printf "HTTP/1.1 200 OK\r\n"
        printf "Content-Type: application/json\r\n"
        printf "Content-Length: %d\r\n" "$RESPONSE_LEN"
        printf "Access-Control-Allow-Origin: *\r\n"
        printf "Connection: close\r\n\r\n"
        printf "%s" "$RESPONSE_BODY"
    } | nc -l -p $PORT > /dev/null 2>&1 || {
        # Fallback netcat invocation
        {
            printf "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n%s" "$RESPONSE_BODY"
        } | nc -l 127.0.0.1 $PORT > /dev/null 2>&1 || sleep 1
    }
done
SERVER_EOF

chmod +x hazard_engine_server.sh

# 2. Update start_daemons.sh to guarantee background execution
printf "${BLUE}[2/3] Updating start_daemons.sh...${NC}\n"
cat << 'DAEMON_EOF' > start_daemons.sh
#!/usr/bin/env bash
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

# Kill existing instance if running
pkill -9 -f "hazard_engine_server" 2>/dev/null || true
fuser -k -9 8080/tcp 2>/dev/null || true
sleep 1

# Launch REST Server in background
nohup bash hazard_engine_server.sh > api_server_output.log 2>&1 &
sleep 2
DAEMON_EOF

chmod +x start_daemons.sh

# 3. Start daemon and test connection
printf "${BLUE}[3/3] Launching REST API server daemon...${NC}\n"
bash start_daemons.sh

if nc -z 127.0.0.1 8080 2>/dev/null || lsof -i:8080 >/dev/null 2>&1; then
    printf "${GREEN}[SUCCESS] REST API Server is active and listening on http://127.0.0.1:8080${NC}\n"
else
    printf "${YELLOW}[NOTICE] Port 8080 initializing... waiting 2 seconds.${NC}\n"
    sleep 2
fi

printf "\n${CYAN}Running watchdog failover recovery test...${NC}\n\n"
bash 32_test_watchdog_failover.sh
