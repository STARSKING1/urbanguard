#!/usr/bin/env bash
# ==============================================================================
# 40_DEPLOY_FRESH_NODE.SH
# Automated single-step installer for deploying UrbanGuard on a new target node
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

RELEASE_TAG="v1.0.0-production"
DIST_ARCHIVE="$HOME/urbanguard_release_$RELEASE_TAG.tar.gz"
MANIFEST_FILE="$HOME/urbanguard_release_$RELEASE_TAG.sha256"

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - AUTOMATED NODE DEPLOYMENT & INSTALLER                            ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Pre-flight verification of the bundle
if [ ! -f "$DIST_ARCHIVE" ]; then
    printf "${RED}[ERROR] Release archive missing at %s${NC}\n" "$DIST_ARCHIVE"
    exit 1
fi

printf "${BLUE}[1/4] Verifying archive checksum...${NC}\n"
sha256sum -c "$MANIFEST_FILE"

# 2. Extract bin and core components to active home environment
printf "${BLUE}[2/4] Deploying scripts and database assets to $HOME...${NC}\n"
tar -xzf "$DIST_ARCHIVE" -C "$HOME"

# Move binaries to top-level home directory for direct execution
cp -rf "$HOME/urbanguard_release_$RELEASE_TAG/bin/"* "$HOME/"
chmod +x "$HOME"/*.sh

# 3. Initialize SQLite Schema if missing
printf "${BLUE}[3/4] Validating SQLite spatial database...${NC}\n"
if [ -f "$HOME/urbanguard_release_$RELEASE_TAG/db_schema/hazards_schema.sql" ] && command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 "$HOME/hazards.db" < "$HOME/urbanguard_release_$RELEASE_TAG/db_schema/hazards_schema.sql" 2>/dev/null || true
fi

# Clean temporary release folder post-deployment
rm -rf "$HOME/urbanguard_release_$RELEASE_TAG"

# 4. Initialize Production Daemons
printf "${BLUE}[4/4] Launching background services...${NC}\n"
bash "$HOME/start_daemons.sh"

sleep 2

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] UrbanGuard node deployment complete and background daemons active!    ${NC}\n"
printf "${CYAN}  • REST API:  ${NC}http://127.0.0.1:8080\n"
printf "${CYAN}  • Dashboard: ${NC}bash 21_cli_tui_dashboard.sh\n"
printf "${CYAN}  • Audit:     ${NC}bash 25_final_verification.sh\n"
printf "${BLUE}================================================================================${NC}\n"
