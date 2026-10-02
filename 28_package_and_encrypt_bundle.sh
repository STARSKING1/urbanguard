#!/usr/bin/env bash
# ==============================================================================
# 28_PACKAGE_AND_ENCRYPT_BUNDLE.SH
# Packages UrbanGuard backend daemons, SQLite DBs, crypto keys, & Flutter stack
# into an AES-256-CBC PBKDF2 encrypted tarball archive.
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
ARCHIVE_NAME="urbanguard_full_backup_${TIMESTAMP}.tar.gz.enc"

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - ENCRYPTED FULL SYSTEM ARCHIVE BUILDER                           ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Ensure OpenSSL is installed in Termux
if ! command -v openssl >/dev/null 2>&1; then
    printf "${YELLOW}[DEPENDENCY] Installing OpenSSL for AES-256 encryption...${NC}\n"
    pkg install openssl -y >/dev/null 2>&1 || true
fi

# 2. Prompt for encryption passphrase
printf "${CYAN}Enter encryption passphrase for archive:${NC} "
read -rs PASSPHRASE
printf "\n"
printf "${CYAN}Confirm passphrase:${NC} "
read -rs PASSPHRASE_CONFIRM
printf "\n"

if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
    printf "${RED}[ERROR] Passphrases do not match. Aborting backup creation.${NC}\n"
    exit 1
fi

if [ -z "$PASSPHRASE" ]; then
    printf "${RED}[ERROR] Passphrase cannot be empty. Aborting.${NC}\n"
    exit 1
fi

printf "\n${BLUE}[PACKAGING] Archiving and encrypting stack components...${NC}\n"

# 3. Create compressed stream and pipe directly into OpenSSL AES-256-CBC
# Excludes heavy build caches (.dart_tool, build, node_modules, temp pipes)
tar -czf - \
    --exclude='.dart_tool' \
    --exclude='build' \
    --exclude='.git' \
    --exclude='*.tar.gz.enc' \
    --exclude='*.fifo' \
    --exclude='tmp' \
    *.sh \
    *.db \
    *.md \
    *.log \
    pubspec.yaml \
    lib \
    crypto_keys 2>/dev/null | \
openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:"$PASSPHRASE" -out "$ARCHIVE_NAME"

printf "${GREEN}[SUCCESS] Archive successfully constructed and encrypted!${NC}\n"
printf "${CYAN}  • Output File: ${NC}%s\n" "$ARCHIVE_NAME"
printf "${CYAN}  • File Size:   ${NC}%s\n" "$(du -h "$ARCHIVE_NAME" | cut -f1)"

printf "\n${BLUE}================================================================================${NC}\n"
printf "${GREEN}DECRYPTION & EXTRACTION COMMAND:${NC}\n"
printf "  openssl enc -d -aes-256-cbc -pbkdf2 -in %s | tar -xzf -\n" "$ARCHIVE_NAME"
printf "${BLUE}================================================================================${NC}\n"
