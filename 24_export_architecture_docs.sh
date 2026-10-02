#!/usr/bin/env bash
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

printf "${BLUE}[ARCHITECTURE] Exporting architecture specifications to ARCHITECTURE.md...${NC}\n"

cat << 'DOC_EOF' > ARCHITECTURE.md
# UrbanGuard Resilience Engine - System Architecture & Data Flow

```text
+---------------------------------------------------------------------------------------------------+
|                                  URBANGUARD RESILIENCE ENGINE                                     |
|                                SYSTEM ARCHITECTURE & DATA FLOW                                    |
+---------------------------------------------------------------------------------------------------+

 +-------------------------------------------------------------------------------------------------+
 |                                LAYER 1: FLUTTER USER INTERFACE                                  |
 |                                                                                                 |
 |   +------------------------------+                     +-----------------------------------+    |
 |   |   HazardMapScreen (UI)       |                     |  NativeMeshBridge (Dart Interface)|    |
 |   | - Render OpenStreetMap Tiles |                     | - broadcastHazardAlert()          |    |
 |   | - Interactive Circle/Markers |                     | - isLocalServerActive()           |    |
 |   +--------------+---------------+                     +-----------------+-----------------+    |
 |                  | (Reactive Polling)                                    |                      |
 |                  v                                                       |                      |
 |   +--------------+---------------+                                       | (MethodChannel)      |
 |   |      HazardViewModel         |                                       | "com.urbanguard.     |
 |   |  (Provider State Manager)    |                                       |  resilience/mesh"    |
 |   +--------------+---------------+                                       |                      |
 +------------------|-------------------------------------------------------|----------------------+
                    | HTTP REST (:8080)                                     |
                    | GET /api/hazards?lat=&lng=&radius=                    v
 +------------------|-------------------------------------------------------|----------------------+
 |                  |                 LAYER 2: ANDROID NATIVE               |                      |
 |                  |                                                       v                      |
 |                  |                             +-------------------------+------------------+   |
 |                  |                             |      NativeMeshBridge.kt (Kotlin)          |   |
 |                  |                             | - Handles Platform Method Calls            |   |
 |                  |                             | - Dispatches UDP 255.255.255.255:9090     |   |
 |                  |                             +-------------------------+------------------+   |
 +------------------|-------------------------------------------------------|----------------------+
                    |                                                       |
                    | Localhost Loopback                                    | UDP Sockets / FIFO Pipe
                    v                                                       v
 +-------------------------------------------------------------------------------------------------+
 |                               LAYER 3: TERMUX BASH DAEMON ENGINE                                |
 |                                                                                                 |
 |   +------------------------------+                     +-----------------------------------+    |
 |   |   hazard_engine_server.sh    |                     |   05_hybrid_connectivity_router   |    |
 |   | - HTTP REST API Server       |                     | - UDP Listener (:9090)            |    |
 |   | - Spatial Range Query Engine |                     | - FIFO Pipe: urbanguard_mesh.fifo |    |
 |   +--------------+---------------+                     +-----------------+-----------------+    |
 |                  |                                                       |                      |
 |                  |                                                       v                      |
 |                  |                                     +-----------------+-----------------+    |
 |                  |                                     |    10_pqc_mesh_crypto.sh (Ed25519) |    |
 |                  |                                     | - Sign outgoing JSON payloads     |    |
 |                  |                                     | - Verify incoming signature key   |    |
 |                  |                                     +-----------------+-----------------+    |
 |                  |                                                       |                      |
 |                  |                                                       v                      |
 |   +--------------+---------------+                     +-----------------+-----------------+    |
 |   |   member_sync_worker.sh      |                     | 16_zero_trust_attestation.sh      |    |
 |   | - Process mutation queue     |                     | - Anti-Replay Nonce Validation    |    |
 |   | - Re-try failed P2P sync     |                     | - Peer Challenge-Response Check   |    |
 |   +--------------+---------------+                     +-----------------+-----------------+    |
 |                                                                          |                      |
 |   +----------------------------------------------------------------------+-----------------+    |
 |   |                         14_self_healing_watchdog.sh (Daemon)                           |    |
 |   | - Monitor HTTP :8080 socket & background worker processes                              |    |
 |   | - Run PRAGMA integrity_check & VACUUM optimization loop on SQLite databases            |    |
 |   +----------------------------------------------------------------------------------------+    |
 +------------------|-------------------------------------------------------|----------------------+
                    |                                                       |
                    v                                                       v
 +-------------------------------------------------------------------------------------------------+
 |                                LAYER 4: DATA & KEY PERSISTENCE                                  |
 |                                                                                                 |
 |   +------------------------------+  +-------------------------------+  +--------------------+   |
 |   | hazards.db (SQLite)          |  | sync_queue.db (SQLite)        |  | zero_trust.db      |   |
 |   | - Spatial R-Tree Virtual Tbl |  | - Pending mutations queue     |  | - Processed nonces |   |
 |   | - Radial distance calculations| | - Action retry counter        |  | - Peer trust scores|   |
 |   +------------------------------+  +-------------------------------+  +--------------------+   |
 |                                                                                                 |
 |   +-----------------------------------------------------------------------------------------+   |
 |   | crypto_keys/ Directory                                                                  |   |
 |   | - node_private.pem (Ed25519 / X25519 Private Key)                                       |   |
 |   | - node_public.pem  (Ed25519 / X25519 Public Identity Key)                               |   |
 |   +-----------------------------------------------------------------------------------------+   |
 +-------------------------------------------------------------------------------------------------+
Data Flow Execution Sequences
​Path A: Outbound P2P Hazard Alert Broadcast (Flutter -> Mesh Network)
​User Action: Field responder triggers emergency broadcast in Flutter UI.
​Platform Call: NativeMeshBridge.broadcastHazardAlert() invokes MethodChannel string "broadcastMeshPacket".
​Native UDP Broadcast: NativeMeshBridge.kt receives payload and transmits a UDP datagram to subnet broadcast address 255.255.255.255:9090.
​Daemon Processing: 05_hybrid_router.sh captures socket stream and pipes data to $TMPDIR/urbanguard_mesh.fifo.
​Signing & Anti-Replay: 10_pqc_mesh_crypto.sh signs the payload with the node's Ed25519 key while 16_zero_trust_attestation.sh generates and registers a 128-bit anti-replay nonce in zero_trust.db.
​Persistence: The signed hazard record is written to hazards.db and queued in sync_queue.db.
​Path B: Local Spatial Map Rendering (Termux SQLite -> Flutter UI)
​Polling Event: HazardViewModel fires every 3 seconds requesting surrounding hazards within a defined kilometer radius.
​HTTP Request: HazardApiService executes GET http://127.0.0.1:8080/api/hazards?lat=12.9716&lng=77.5946&radius=25.
​Spatial Query: hazard_engine_server.sh receives request, executes bounding-box filter using SQLite R-Tree virtual index (hazards.db), and returns a formatted JSON array.
​UI Render: HazardViewModel updates ViewState.success and FlutterMap redraws markers and impact radius circles on screen.
DOC_EOF
​printf "{GREEN}[SUCCESS] System architecture saved to 'ARCHITECTURE.md'.{NC}\n"
