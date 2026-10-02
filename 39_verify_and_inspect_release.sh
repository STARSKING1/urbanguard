#!/usr/bin/env bash
# ==============================================================================
# 39_VERIFY_AND_INSPECT_RELEASE.SH
# Validates SHA-256 integrity and lists the production tarball file structure
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

RELEASE_TAG="v1.0.0-production"
DIST_ARCHIVE="$HOME/urbanguard_release_$RELEASE_TAG.tar.gz"
MANIFEST_FILE="$HOME/urbanguard_release_$RELEASE_TAG.sha256"

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - RELEASE INTEGRITY VERIFIER & ARCHIVE INSPECTOR                    ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Check file existence
if [ ! -f "$DIST_ARCHIVE" ] || [ ! -f "$MANIFEST_FILE" ]; then
    printf "${RED}[ERROR] Release tarball or checksum manifest not found in $HOME.${NC}\n"
    printf "${RED}Run 'bash 38_generate_production_release.sh' to build the package first.${NC}\n"
    exit 1
fi

# 2. Verify SHA-256 Cryptographic Checksum
printf "${BLUE}[1/2] Verifying cryptographic checksum against manifest...${NC}\n"
sha256sum -c "$MANIFEST_FILE"

# 3. List Archive File Contents
printf "\n${BLUE}[2/2] Extracting archive structure tree...${NC}\n\n"
tar -tzf "$DIST_ARCHIVE"

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[VERIFIED] Production bundle $RELEASE_TAG is authentic and intact!             ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"
