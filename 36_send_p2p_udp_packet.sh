#!/usr/bin/env bash
# ==============================================================================
# 36_SEND_P2P_UDP_PACKET.SH
# Transmits a synthetic P2P mesh hazard packet to UDP port 9090
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
printf "${CYAN}   URBANGUARD - P2P UDP MESH PACKET TRANSMITTER                                  ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

PORT=9090
TARGET_IP="127.0.0.1"
BROADCAST_IP="255.255.255.255"

# 1. Construct JSON Mesh Payload
TIMESTAMP=$(date +%s)
PAYLOAD=$(cat <<PAYLOAD_EOF
{"type":"MESH_HAZARD_BROADCAST","sender":"NODE_ALPHA","hazard_id":"h2","title":"Seismic Tremor Alert","category":"Earthquake","latitude":12.9800,"longitude":77.6000,"severity":"CRITICAL","timestamp":$TIMESTAMP}
PAYLOAD_EOF
)

printf "${BLUE}[1/2] Constructing UDP Packet Payload...${NC}\n"
printf "${CYAN}Payload:${NC} %s\n\n" "$PAYLOAD"

# 2. Transmit UDP Packet
printf "${BLUE}[2/2] Transmitting UDP packet to port %d...${NC}\n" "$PORT"

if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import socket

target_ip = "'"$TARGET_IP"'"
broadcast_ip = "'"$BROADCAST_IP"'"
port = '"$PORT"'
message = """'"$PAYLOAD"'""".encode("utf-8")

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

try:
    sock.sendto(message, (target_ip, port))
    sock.sendto(message, (broadcast_ip, port))
    print("\033[0;32m[SUCCESS] Dispatched UDP packet to " + target_ip + ":" + str(port) + " & " + broadcast_ip + ":" + str(port) + "\033[0m")
except Exception as e:
    print("\033[0;31m[ERROR] Failed to send UDP packet: " + str(e) + "\033[0m")
finally:
    sock.close()
'
elif command -v nc >/dev/null 2>&1; then
    echo -n "$PAYLOAD" | nc -u -w 1 "$TARGET_IP" "$PORT" || true
    printf "${GREEN}[SUCCESS] Dispatched UDP packet via netcat to %s:%d${NC}\n" "$TARGET_IP" "$PORT"
else
    printf "${RED}[ERROR] Neither python3 nor nc available for UDP packet transmission.${NC}\n"
    exit 1
fi

printf "\n${BLUE}================================================================================${NC}\n"
