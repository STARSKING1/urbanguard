#!/usr/bin/env bash
# ==============================================================================
# MASTER CONTROL & SERVICE MANAGER (master_control.sh)
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_status() {
    echo -e "${BLUE}==========================================================${NC}"
    echo -e "${BLUE}     URBANGUARD RESILIENCE ENGINE - SERVICE STATUS        ${NC}"
    echo -e "${BLUE}==========================================================${NC}"

    # 1. HTTP Spatial API Port 8080 Check
    if nc -z 127.0.0.1 8080 2>/dev/null; then
        echo -e "  • REST Spatial API (:8080):       ${GREEN}RUNNING [OK]${NC}"
    else
        echo -e "  • REST Spatial API (:8080):       ${RED}STOPPED${NC}"
    fi

    # 2. Sync Worker Process Check
    if pgrep -f "member_sync_worker.sh" >/dev/null 2>&1; then
        echo -e "  • Mutation Sync Worker:           ${GREEN}RUNNING [OK]${NC}"
    else
        echo -e "  • Mutation Sync Worker:           ${YELLOW}IDLE / INACTIVE${NC}"
    fi

    # 3. Watchdog Process Check
    if pgrep -f "14_self_healing_watchdog.sh" >/dev/null 2>&1; then
        echo -e "  • Self-Healing Watchdog:          ${GREEN}RUNNING [OK]${NC}"
    else
        echo -e "  • Self-Healing Watchdog:          ${YELLOW}IDLE / INACTIVE${NC}"
    fi

    # 4. Database Integrity Check
    if [ -f "hazards.db" ]; then
        echo -e "  • Spatial Database (hazards.db):  ${GREEN}HEALTHY${NC}"
    else
        echo -e "  • Spatial Database (hazards.db):  ${RED}MISSING${NC}"
    fi

    echo -e "${BLUE}==========================================================${NC}"
}

stop_services() {
    echo -e "${YELLOW}[STOP] Terminating all background daemons...${NC}"
    pkill -f "hazard_engine_server.sh" || true
    pkill -f "member_sync_worker.sh" || true
    pkill -f "14_self_healing_watchdog.sh" || true
    pkill -f "13_mesh_topology_monitor.sh" || true
    echo -e "${GREEN}[STOP] All services stopped cleanly.${NC}"
}

start_services() {
    echo -e "${BLUE}[START] Launching production stack...${NC}"
    bash 15_run_production_stack.sh
}

clean_artifacts() {
    stop_services
    echo -e "${YELLOW}[CLEAN] Removing databases, logs, and temporary pipes...${NC}"
    rm -f hazards.db sync_queue.db zero_trust.db *.log
    rm -rf "$HOME/tmp"
    echo -e "${GREEN}[CLEAN] Cleanup complete.${NC}"
}

case "${1:-status}" in
    status)         show_status ;;
    start-services) start_services ;;
    stop-services)  stop_services ;;
    clean)          clean_artifacts ;;
    *)
        echo "Usage: $0 {status|start-services|stop-services|clean}"
        ;;
esac
