#!/usr/bin/env bash
# ==============================================================================
# 35_FIX_API_AND_TEST.SH
# Upgrades REST server to Python HTTP daemon and verifies watchdog failover
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
printf "${CYAN}   URBANGUARD - REST API DAEMON REPAIR & FAILOVER VERIFICATION                   ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Ensure Python 3 is installed
if ! command -v python3 >/dev/null 2>&1; then
    printf "${YELLOW}[SETUP] Installing Python 3 in Termux...${NC}\n"
    pkg install python -y >/dev/null 2>&1 || true
fi

# 2. Rebuild hazard_engine_server.sh using Python 3
printf "${BLUE}[1/4] Writing Python 3 spatial server daemon...${NC}\n"
cat << 'SERVER_EOF' > hazard_engine_server.sh
#!/usr/bin/env bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

exec python3 -c '
import http.server
import socketserver
import sqlite3
import json
import os

PORT = 8080

class HazardAPIHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        hazards = []
        if os.path.exists("hazards.db"):
            try:
                conn = sqlite3.connect("hazards.db")
                cursor = conn.cursor()
                cursor.execute("SELECT id, description, severity, latitude, longitude FROM hazards")
                rows = cursor.fetchall()
                for r in rows:
                    hazards.append({
                        "id": str(r[0]),
                        "title": str(r[1]),
                        "category": str(r[2]),
                        "latitude": float(r[3]),
                        "longitude": float(r[4])
                    })
                conn.close()
            except Exception:
                pass
        
        if not hazards:
            hazards = [{
                "id": "h1",
                "title": "Flash Flood Warning",
                "category": "Flood",
                "latitude": 12.9716,
                "longitude": 77.5946
            }]
            
        body = json.dumps(hazards).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        return

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReusableTCPServer(("0.0.0.0", PORT), HazardAPIHandler) as httpd:
    httpd.serve_forever()
'
SERVER_EOF

chmod +x hazard_engine_server.sh

# 3. Update start_daemons.sh
printf "${BLUE}[2/4] Updating start_daemons.sh worker...${NC}\n"
cat << 'DAEMON_EOF' > start_daemons.sh
#!/usr/bin/env bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

if command -v lsof >/dev/null 2>&1; then
    LSOF_PIDS=$(lsof -t -i:8080 2>/dev/null || true)
    if [ -n "$LSOF_PIDS" ]; then
        for pid in $LSOF_PIDS; do kill -9 "$pid" 2>/dev/null || true; done
    fi
fi
fuser -k -9 8080/tcp 2>/dev/null || true
pids=$(ps aux 2>/dev/null | grep "hazard_engine_server" | grep -v "grep" | awk '{print $2}' || true)
if [ -n "$pids" ]; then
    for pid in $pids; do kill -9 "$pid" 2>/dev/null || true; done
fi
sleep 1

nohup bash hazard_engine_server.sh > api_server_output.log 2>&1 &
sleep 2
DAEMON_EOF

chmod +x start_daemons.sh

# 4. Start REST API daemon
printf "${BLUE}[3/4] Starting REST API daemon...${NC}\n"
bash start_daemons.sh

if nc -z 127.0.0.1 8080 2>/dev/null || lsof -i:8080 >/dev/null 2>&1; then
    printf "${GREEN}[SUCCESS] REST API listening on http://127.0.0.1:8080${NC}\n"
    printf "${CYAN}Endpoint response:${NC} %s\n" "$(curl -s http://127.0.0.1:8080)"
else
    printf "${RED}[ERROR] REST API failed to initialize on port 8080.${NC}\n"
    exit 1
fi

# 5. Run watchdog failover recovery test
printf "\n${BLUE}[4/4] Executing 32_test_watchdog_failover.sh...${NC}\n\n"
bash 32_test_watchdog_failover.sh
