#!/usr/bin/env bash
set -euo pipefail

BOOT_DIR="$HOME/.termux/boot"
BOOT_SCRIPT="$BOOT_DIR/start_urbanguard_boot.sh"

echo "[SETUP] Creating Termux boot directory at '$BOOT_DIR'..."
mkdir -p "$BOOT_DIR"

cat << 'BOOT_EOF' > "$BOOT_SCRIPT"
#!/usr/bin/env bash
set -euo pipefail

BOOT_LOG="$HOME/urbanguard_boot.log"
echo "[$(date +'%Y-%m-%dT%H:%M:%S')] Android boot event detected." >> "$BOOT_LOG"

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo "[$(date +'%Y-%m-%dT%H:%M:%S')] Termux wake lock acquired." >> "$BOOT_LOG"
fi

cd "$HOME"

if [ -f "06_daemon_manager.sh" ]; then
    bash 06_daemon_manager.sh start >> "$BOOT_LOG" 2>&1
elif [ -f "master_control.sh" ]; then
    bash master_control.sh start-services >> "$BOOT_LOG" 2>&1
fi
BOOT_EOF

chmod +x "$BOOT_SCRIPT"
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
fi
echo "[SUCCESS] Termux boot script created at $BOOT_SCRIPT"
