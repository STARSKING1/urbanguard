#!/usr/bin/env bash
set -euo pipefail

PASSED=0
FAILED=0
LOG_FILE="test_report.log"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    local msg="[$(date +'%Y-%m-%dT%H:%M:%S')] $1"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [ "$expected" == "$actual" ]; then
        log "${GREEN}[PASS]${NC} $test_name"
        PASSED=$((PASSED + 1))
    else
        log "${RED}[FAIL]${NC} $test_name (Expected: '$expected', Got: '$actual')"
        FAILED=$((FAILED + 1))
    fi
}

safe_count() {
    local input="$1"
    local pattern="$2"
    echo "$input" | grep -o "$pattern" 2>/dev/null | wc -l | tr -d ' '
}

run_suite() {
    echo "=== URBANGUARD RESILIENCE AUTOMATED E2E SUITE ===" > "$LOG_FILE"
    log "Starting validation sequence..."

    # Reset test databases to guarantee clean test isolation
    rm -f sync_queue.db hazards.db

    bash hazard_engine_server.sh > /dev/null 2>&1 || true
    bash member_sync_worker.sh --init > /dev/null 2>&1 || true

    log "Running Test 1: Spatial Hazard Query Filtering..."
    local hazard_res
    hazard_res=$(bash hazard_engine_server.sh 2>/dev/null || echo "[]")
    local count
    count=$(safe_count "$hazard_res" '"id":')

    if [ "$count" -ge 1 ]; then
        log "${GREEN}[PASS]${NC} Spatial query returned $count hazard alerts within boundary."
        PASSED=$((PASSED + 1))
    else
        log "${RED}[FAIL]${NC} Spatial query returned zero hazard alerts."
        FAILED=$((FAILED + 1))
    fi

    log "Running Test 2: Offline Member Mutation Queue..."
    bash member_sync_worker.sh --add-pro "usr_test_99" > /dev/null 2>&1 || true
    bash member_sync_worker.sh --update-role "usr_test_99" "Admin" > /dev/null 2>&1 || true

    local queued_count
    queued_count=$(sqlite3 sync_queue.db "SELECT COUNT(*) FROM pending_mutations;" 2>/dev/null || echo "0")
    assert_equals "2" "$queued_count" "Offline mutations successfully added to SQLite queue"

    log "Running Test 3: GPS Telemetry Stream Verification..."
    local gps_output
    gps_output=$(bash gps_telemetry_emulator.sh 2>/dev/null | head -n 5 || echo "")
    local has_type
    has_type=$(safe_count "$gps_output" '"type":"GPS_UPDATE"')

    if [ "$has_type" -ge 1 ]; then
        log "${GREEN}[PASS]${NC} GPS Telemetry stream outputs valid JSON telemetry frame."
        PASSED=$((PASSED + 1))
    else
        log "${RED}[FAIL]${NC} GPS Telemetry stream failed to output valid JSON frame."
        FAILED=$((FAILED + 1))
    fi

    log "Running Test 4: Hybrid Router Dispatch..."
    local router_output
    router_output=$(bash hybrid_connectivity_router.sh --dispatch 2>&1 || echo "")
    local is_delivered
    is_delivered=$(safe_count "$router_output" "SUCCESS")

    if [ "$is_delivered" -ge 1 ]; then
        log "${GREEN}[PASS]${NC} Hybrid router successfully dispatched payload."
        PASSED=$((PASSED + 1))
    else
        log "${RED}[FAIL]${NC} Hybrid router failed payload delivery."
        FAILED=$((FAILED + 1))
    fi

    log "================================================="
    log "SUMMARY: $PASSED Passed | $FAILED Failed"
    log "================================================="

    if [ "$FAILED" -ne 0 ]; then
        exit 1
    fi
}

run_suite
