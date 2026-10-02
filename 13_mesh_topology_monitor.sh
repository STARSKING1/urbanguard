#!/usr/bin/env bash
set -euo pipefail
MESH_PIPE="/tmp/urbanguard_mesh.fifo"
if [ ! -p "$MESH_PIPE" ]; then mkfifo "$MESH_PIPE"; fi
echo "[MESH_MONITOR] Mesh Network Traffic Inspector Initialized on $MESH_PIPE"
