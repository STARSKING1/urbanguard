#!/usr/bin/env bash
# ==============================================================================
# 21_CLI_TUI_DASHBOARD.SH
# Interactive Terminal Control Dashboard for UrbanGuard Resilience Engine
# ==============================================================================
set -euo pipefail

DB_FILE="hazards.db"
TMP_DIR="${TMPDIR:-$HOME/tmp}"
MESH_PIPE="$TMP_DIR/urbanguard_mesh.fifo"

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear_screen() {
    clear || printf "\033c"
}

draw_header() {
    clear_screen
    echo -e "${BLUE}${BOLD}================================================================================${NC}"
    echo -e "${CYAN}${BOLD}     URBANGUARD RESILIENCE ENGINE - INTERACTIVE CONTROL DASHBOARD${NC}"
    echo -e "${BLUE}${BOLD}================================================================================${NC}"
    
    # Real-time process status badges
    local api_status sync_status
    if nc -z 127.0.0.1 8080 2>/dev/null; then
        api_status="${GREEN}ONLINE (:8080)${NC}"
    else
        api_status="${RED}OFFLINE${NC}"
    fi

    if pgrep -f "member_sync_worker.sh" >/dev/null 2>&1; then
        sync_status="${GREEN}ACTIVE${NC}"
    else
        sync_status="${YELLOW}IDLE${NC}"
    fi

    echo -e " Node Status: ${GREEN}OPERATIONAL${NC} | REST API: $api_status | Sync Worker: $sync_status"
    echo -e "${BLUE}================================================================================${NC}"
    echo
}

query_hazards_menu() {
    draw_header
    echo -e "${BOLD}[1] SPATIAL HAZARD QUERY${NC}"
    echo "--------------------------------------------------------------------------------"
    read -rp "Enter Center Latitude [Default 12.9716]: " lat
    lat="${lat:-12.9716}"
    read -rp "Enter Center Longitude [Default 77.5946]: " lng
    lng="${lng:-77.5946}"
    read -rp "Enter Radial Search Distance (km) [Default 10]: " radius
    radius="${radius:-10}"

    echo
    echo -e "${CYAN}Executing spatial bounding-box query...${NC}"
    echo "--------------------------------------------------------------------------------"
    if [ -f "02_hazard_engine.sh" ]; then
        bash 02_hazard_engine.sh --query "$lat" "$lng" "$radius" 2>/dev/null || \
        sqlite3 "$DB_FILE" "SELECT id, title, category, severity, latitude, longitude FROM hazards;" 2>/dev/null || echo "No records found."
    else
        sqlite3 "$DB_FILE" "SELECT id, title, category, severity, latitude, longitude FROM hazards;" 2>/dev/null || echo "No records found."
    fi
    echo "--------------------------------------------------------------------------------"
    read -rp "Press Enter to return to main menu..."
}

dispatch_beacon_menu() {
    draw_header
    echo -e "${BOLD}[2] DISPATCH ULTRA-LOW BANDWIDTH BLE BEACON${NC}"
    echo "--------------------------------------------------------------------------------"
    read -rp "Enter Hazard Latitude [Default 12.9716]: " lat
    lat="${lat:-12.9716}"
    read -rp "Enter Hazard Longitude [Default 77.5946]: " lng
    lng="${lng:-77.5946}"
    read -rp "Select Severity (1:Low, 2:Med, 3:High, 4:Critical) [Default 4]: " sev
    sev="${sev:-4}"

    if [ -f "17_geo_beacon_engine.sh" ]; then
        echo
        echo -e "${CYAN}Generated Compact BLE Payload:${NC}"
        beacon_hex=$(bash 17_geo_beacon_engine.sh --encode "$lat" "$lng" "$sev")
        echo -e "${GREEN}${BOLD}$beacon_hex${NC} (${#beacon_hex} bytes)"
    else
        echo -e "${RED}Beacon engine script (17_geo_beacon_engine.sh) not found.${NC}"
    fi
    echo "--------------------------------------------------------------------------------"
    read -rp "Press Enter to return to main menu..."
}

send_mesh_packet_menu() {
    draw_header
    echo -e "${BOLD}[3] BROADCAST P2P MESH PACKET${NC}"
    echo "--------------------------------------------------------------------------------"
    read -rp "Enter Payload Title [Default: Flash Flood Alert]: " title
    title="${title:-Flash Flood Alert}"

    local packet_json
    packet_json=$(cat <<JSON_EOF
{"user_id":"node_termux","type":"HAZARD_ALERT","title":"$title","timestamp":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"}
JSON_EOF
)

    mkdir -p "$TMP_DIR"
    if [ ! -p "$MESH_PIPE" ]; then mkfifo "$MESH_PIPE"; fi

    echo "$packet_json" > "$MESH_PIPE" &
    echo -e "${GREEN}[SUCCESS] Broadcasted packet to mesh pipe ($MESH_PIPE):${NC}"
    echo "$packet_json"
    echo "--------------------------------------------------------------------------------"
    read -rp "Press Enter to return to main menu..."
}

run_diagnostics_menu() {
    draw_header
    echo -e "${BOLD}[4] RUN SYSTEM HEALTH DIAGNOSTICS & DB VACUUM${NC}"
    echo "--------------------------------------------------------------------------------"
    if [ -f "14_self_healing_watchdog.sh" ]; then
        bash 14_self_healing_watchdog.sh --run-once
    else
        echo -e "${CYAN}Vacuuming SQLite databases...${NC}"
        for db in hazards.db sync_queue.db zero_trust.db; do
            if [ -f "$db" ]; then
                sqlite3 "$db" "PRAGMA integrity_check; VACUUM;" 2>/dev/null && echo " - $db: Integrity OK"
            fi
        done
    fi
    echo "--------------------------------------------------------------------------------"
    read -rp "Press Enter to return to main menu..."
}

main_loop() {
    while true; do
        draw_header
        echo -e "${BOLD}Select an Operational Command:${NC}"
        echo "  1) Query Spatial Hazard Alerts"
        echo "  2) Encode & Dispatch Geo-Spatial SOS Beacon"
        echo "  3) Broadcast P2P Mesh Packet"
        echo "  4) Run System Diagnostics & Database Vacuum"
        echo "  5) Tail Live Aggregated Logs"
        echo "  6) Restart All Background Daemons"
        echo "  0) Exit Dashboard"
        echo
        read -rp "Option [0-6]: " choice

        case "$choice" in
            1) query_hazards_menu ;;
            2) dispatch_beacon_menu ;;
            3) send_mesh_packet_menu ;;
            4) run_diagnostics_menu ;;
            5)
                if [ -f "20_log_aggregator.sh" ]; then
                    bash 20_log_aggregator.sh
                else
                    tail -n 20 *.log 2>/dev/null || echo "No log files found."
                    read -rp "Press Enter to return..."
                fi
                ;;
            6)
                if [ -f "start_daemons.sh" ]; then
                    bash start_daemons.sh
                elif [ -f "master_control.sh" ]; then
                    bash master_control.sh start-services
                fi
                sleep 2
                ;;
            0)
                clear_screen
                echo "Exited UrbanGuard Control Dashboard."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                ;;
        esac
    done
}

main_loop
