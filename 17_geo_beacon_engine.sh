#!/usr/bin/env bash
set -euo pipefail

encode_beacon() {
    local lat="$1" lng="$2" sev="$3"
    local scaled_lat scaled_lng hex_lat hex_lng hex_sev
    scaled_lat=$(awk -v l="$lat" 'BEGIN { printf "%d", (l + 90) * 100000 }')
    scaled_lng=$(awk -v l="$lng" 'BEGIN { printf "%d", (l + 180) * 100000 }')
    hex_lat=$(printf "%08X" "$scaled_lat")
    hex_lng=$(printf "%08X" "$scaled_lng")
    hex_sev=$(printf "%02X" "$sev")
    echo "UG${hex_sev}${hex_lat}${hex_lng}"
}

if [[ "${1:-}" == "--test-cycle" ]]; then
    beacon=$(encode_beacon "12.97160" "77.59460" "4")
    echo "[BEACON] Encoded Ultra-Low Bandwidth Beacon Payload: $beacon"
else
    encode_beacon "${2:-12.9716}" "${3:-77.5946}" "${4:-4}"
fi
