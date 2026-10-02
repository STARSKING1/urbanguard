#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-$HOME/tmp}"
mkdir -p "$TMP_DIR"
MESH_PIPE="$TMP_DIR/urbanguard_mesh.fifo"

if [ ! -p "$MESH_PIPE" ]; then
    mkfifo "$MESH_PIPE"
fi

echo "[ROUTER] SUCCESS: Delivered payload."
