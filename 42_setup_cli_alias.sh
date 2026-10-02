#!/usr/bin/env bash
# ==============================================================================
# 42_SETUP_CLI_ALIAS.SH
# Installs a global 'urbanguard' terminal command into Termux $PREFIX/bin
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_BIN="/data/data/com.termux/files/usr/bin/urbanguard"

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - GLOBAL CLI HELPER INSTALLER                                       ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Create global CLI wrapper script
printf "${BLUE}[1/2] Installing global 'urbanguard' binary...${NC}\n"

cat << 'CLI_EOF' > "$TARGET_BIN"
#!/usr/bin/env bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

COMMAND="${1:-dashboard}"

case "$COMMAND" in
    dashboard|tui)
        exec bash "$HOME/21_cli_tui_dashboard.sh"
        ;;
    status)
        exec bash "$HOME/master_control.sh" status
        ;;
    start)
        exec bash "$HOME/start_daemons.sh"
        ;;
    logs)
        exec bash "$HOME/20_log_aggregator.sh"
        ;;
    audit)
        exec bash "$HOME/25_final_verification.sh"
        ;;
    maintain)
        exec bash "$HOME/41_routine_maintenance.sh"
        ;;
    backup)
        exec bash "$HOME/28_package_and_encrypt_bundle.sh"
        ;;
    help|--help|-h)
        printf "${BLUE}================================================================================${NC}\n"
        printf "${CYAN}   URBANGUARD RESILIENCE ENGINE - CLI COMMAND SUITE                             ${NC}\n"
        printf "${BLUE}================================================================================${NC}\n"
        printf "  • ${GREEN}urbanguard${NC}            : Launch interactive TUI control dashboard\n"
        printf "  • ${GREEN}urbanguard status${NC}     : Print live microservices operational status\n"
        printf "  • ${GREEN}urbanguard start${NC}      : Launch REST API, watchdog, and sync daemons\n"
        printf "  • ${GREEN}urbanguard logs${NC}       : Stream real-time aggregated system logs\n"
        printf "  • ${GREEN}urbanguard audit${NC}      : Run full diagnostic verification suite\n"
        printf "  • ${GREEN}urbanguard maintain${NC}   : Run SQLite vacuum, log rotation & optimization\n"
        printf "  • ${GREEN}urbanguard backup${NC}     : Trigger instant AES-256 encrypted database backup\n"
        printf "${BLUE}================================================================================${NC}\n"
        ;;
    *)
        printf "${RED}[ERROR] Unknown command: %s${NC}\n" "$COMMAND"
        printf "Run '${CYAN}urbanguard help${NC}' to view available operations.\n"
        exit 1
        ;;
esac
CLI_EOF

chmod +x "$TARGET_BIN"

# 2. Add shell auto-completion or profile hook if missing
if ! grep -q "urbanguard status" "$HOME/.bashrc" 2>/dev/null; then
    echo "alias ug='urbanguard'" >> "$HOME/.bashrc"
    printf "${BLUE}[2/2] Added shortcut alias 'ug' to $HOME/.bashrc.${NC}\n"
fi

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] 'urbanguard' global command successfully installed!                   ${NC}\n"
printf "${CYAN}  • Try running: ${NC}urbanguard status\n"
printf "${CYAN}  • Shortcut:    ${NC}ug\n"
printf "${BLUE}================================================================================${NC}\n"
