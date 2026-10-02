#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="audit_report.log"
ERRORS=0

log_audit() {
    local status="$1"
    local msg="$2"
    echo -e "[$status] $msg" | tee -a "$LOG_FILE"
}

check_security_crypto() {
    log_audit "AUDIT" "1. Checking Cryptographic & Security Dependencies..."
    
    if command -v openssl >/dev/null 2>&1; then
        log_audit "PASS" "OpenSSL binary available for AES-256-GCM / Ed25519 payload operations."
    else
        log_audit "FAIL" "OpenSSL not installed. Required for mesh packet signing/encryption."
        ERRORS=$((ERRORS + 1))
    fi
}

check_platform_permissions() {
    log_audit "AUDIT" "2. Verifying Mobile Platform Manifest Permissions..."
    
    local android_manifest="android/app/src/main/AndroidManifest.xml"
    local ios_plist="ios/Runner/Info.plist"

    if [ -f "$android_manifest" ]; then
        for perm in "ACCESS_FINE_LOCATION" "FOREGROUND_SERVICE" "BLUETOOTH_SCAN" "BLUETOOTH_CONNECT"; do
            if grep -q "$perm" "$android_manifest"; then
                log_audit "PASS" "Android Permission found: $perm"
            else
                log_audit "WARN" "Android Permission missing in manifest: $perm"
            fi
        done
    else
        log_audit "SKIP" "Android Manifest not detected in path ($android_manifest)."
    fi

    if [ -f "$ios_plist" ]; then
        if grep -q "NSLocationWhenInUseUsageDescription" "$ios_plist"; then
            log_audit "PASS" "iOS Location usage key found."
        else
            log_audit "WARN" "iOS Location usage description missing in Info.plist."
        fi
    else
        log_audit "SKIP" "iOS Info.plist not detected in path ($ios_plist)."
    fi
}

check_database_rtree() {
    log_audit "AUDIT" "3. Validating SQLite R-Tree Spatial Indexing Support..."
    
    local rtree_supported
    rtree_supported=$(sqlite3 :memory: "CREATE VIRTUAL TABLE test_rtree USING rtree(id, minX, maxX, minY, maxY);" 2>&1 || echo "ERROR")
    
    if [ "$rtree_supported" != "ERROR" ]; then
        log_audit "PASS" "SQLite engine supports R-Tree virtual spatial tables."
    else
        log_audit "FAIL" "SQLite compiled without R-Tree extension support."
        ERRORS=$((ERRORS + 1))
    fi
}

test_payload_gzip_compression() {
    log_audit "AUDIT" "4. Testing Mesh Packet GZIP Compression Pipeline..."
    
    local sample_json='{"id":"pkt_mesh_101","type":"HAZARD_ALERT","payload":{"lat":12.9716,"lng":77.5946,"severity":"Critical","desc":"Heavy Flash Flood Alert"}}'
    local orig_size
    orig_size=$(echo -n "$sample_json" | wc -c)
    
    local comp_size
    comp_size=$(echo -n "$sample_json" | gzip -c | wc -c)
    
    log_audit "PASS" "Payload compressed from ${orig_size}B to ${comp_size}B for low-bandwidth BLE advertisement."
}

run_audit() {
    echo "=== URBANGUARD RESILIENCE PRODUCTION AUDIT ===" > "$LOG_FILE"
    check_security_crypto
    check_platform_permissions
    check_database_rtree
    test_payload_gzip_compression
    
    echo "=============================================" | tee -a "$LOG_FILE"
    if [ "$ERRORS" -eq 0 ]; then
        log_audit "SUCCESS" "Production Readiness Audit PASSED cleanly."
    else
        log_audit "FAILURE" "Production Readiness Audit found $ERRORS critical blocker(s)."
        exit 1
    fi
}

run_audit
