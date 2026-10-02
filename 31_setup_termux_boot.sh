#!/usr/bin/env bash
# ==============================================================================
# 31_SETUP_TERMUX_BOOT.SH
# Configures Termux:Boot auto-start hooks for UrbanGuard daemons & crond
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - TERMUX:BOOT AUTO-START CONFIGURATOR                             ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Ensure ~/.termux/boot directory exists
BOOT_DIR="$HOME/.termux/boot"
mkdir -p "$BOOT_DIR"

BOOT_SCRIPT="$BOOT_DIR/00_start_urbanguard.sh"

printf "${BLUE}[SETUP] Generating boot initialization script at $BOOT_SCRIPT...${NC}\n"

# 2. Write the boot script executed automatically by Android on system boot
cat << 'BOOT_EOF' > "$BOOT_SCRIPT"
#!/usr/bin/env bash
# Termux:Boot Initialization Script for UrbanGuard Engine
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

LOG_FILE="$HOME/urbanguard_boot.log"

echo "==================================================" >> "$LOG_FILE"
echo "[BOOT] System reboot detected at $(date)" >> "$LOG_FILE"

# 1. Acquire Wake Lock to prevent Android CPU sleeping
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo "[BOOT] Termux wake lock acquired." >> "$LOG_FILE"
fi

# 2. Launch Cron Daemon for automated daily backups
if ! pgrep crond >/dev/null 2>&1; then
    crond
    echo "[BOOT] Cron daemon (crond) launched." >> "$LOG_FILE"
else
    echo "[BOOT] Cron daemon already active." >> "$LOG_FILE"
fi

# 3. Launch UrbanGuard Background Production Daemons
if [ -f "$HOME/start_daemons.sh" ]; then
    bash "$HOME/start_daemons.sh" >> "$LOG_FILE" 2>&1
    echo "[BOOT] UrbanGuard start_daemons.sh executed." >> "$LOG_FILE"
elif [ -f "$HOME/master_control.sh" ]; then
    bash "$HOME/master_control.sh" start-services >> "$LOG_FILE" 2>&1
    echo "[BOOT] UrbanGuard master_control.sh start-services executed." >> "$LOG_FILE"
fi

echo "[BOOT] Initialization finished at $(date)" >> "$LOG_FILE"
echo "==================================================" >> "$LOG_FILE"
BOOT_EOF

chmod +x "$BOOT_SCRIPT"

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] Termux:Boot script generated at: $BOOT_SCRIPT${NC}\n"
printf "${CYAN}  • Boot Log File: ${NC}$HOME/urbanguard_boot.log\n"
printf "${CYAN}  • Wake Lock:    ${NC}Enabled (prevents Android CPU sleep)\n"
printf "${CYAN}  • Auto Services:${NC} crond + UrbanGuard Daemons\n"
printf "${BLUE}================================================================================${NC}\n"

printf "\n${YELLOW}[REQUIRED ANDROID SETTINGS]${NC}\n"
printf "1. Ensure the 'Termux:Boot' add-on app is installed on Android.\n"
printf "2. Open the 'Termux:Boot' app ONCE manually from your app drawer to register the boot receiver.\n"
printf "3. Disable Battery Optimization for both Termux and Termux:Boot in Android Settings.\n"
