#!/usr/bin/env bash
# ==============================================================================
# 29_OFFSITE_BACKUP_SYNC.SH
# Automated SCP/SSH Offsite Sync for Encrypted UrbanGuard Archives
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
printf "${CYAN}   URBANGUARD - OFFSITE ENCRYPTED BACKUP TRANSMITTER (SSH/SCP)                 ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Dependency Check
if ! command -v scp >/dev/null 2>&1; then
    printf "${YELLOW}[DEPENDENCY] Installing OpenSSH in Termux...${NC}\n"
    pkg install openssh -y >/dev/null 2>&1 || true
fi

# 2. Locate Latest Encrypted Backup
LATEST_ARCHIVE=$(ls -t urbanguard_full_backup_*.tar.gz.enc 2>/dev/null | head -n1 || true)

if [ -z "$LATEST_ARCHIVE" ]; then
    printf "${RED}[ERROR] No encrypted backup archives found matching 'urbanguard_full_backup_*.tar.gz.enc'.${NC}\n"
    printf "${YELLOW}Run 'bash 28_package_and_encrypt_bundle.sh' first to create a backup.${NC}\n"
    exit 1
fi

printf "${CYAN}Target Archive:${NC} %s (%s)\n" "$LATEST_ARCHIVE" "$(du -h "$LATEST_ARCHIVE" | cut -f1)"

# 3. Target Remote Host Details
read -rp "Enter Remote SSH Host/IP [e.g., 192.168.1.100]: " REMOTE_HOST
read -rp "Enter Remote SSH Username [Default: root]: " REMOTE_USER
REMOTE_USER="${REMOTE_USER:-root}"
read -rp "Enter Remote SSH Port [Default: 22]: " REMOTE_PORT
REMOTE_PORT="${REMOTE_PORT:-22}"
read -rp "Enter Remote Destination Path [Default: ~/urbanguard_backups/]: " REMOTE_PATH
REMOTE_PATH="${REMOTE_PATH:-~/urbanguard_backups/}"

if [ -z "$REMOTE_HOST" ]; then
    printf "${RED}[ERROR] Remote host IP/domain cannot be empty.${NC}\n"
    exit 1
fi

# 4. SSH Key Pre-check
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    printf "${YELLOW}[NOTICE] No Ed25519 SSH key pair found at $SSH_KEY.${NC}\n"
    read -rp "Generate SSH key pair now for passwordless sync? (y/N): " GEN_KEY
    if [[ "${GEN_KEY,,}" == "y" ]]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -q
        printf "${GREEN}[SUCCESS] Generated Ed25519 SSH key pair.${NC}\n"
        printf "${CYAN}To enable passwordless sync, run:${NC}\n"
        printf "  ssh-copy-id -p %s %s@%s\n\n" "$REMOTE_PORT" "$REMOTE_USER" "$REMOTE_HOST"
    fi
fi

# 5. Remote Directory Prep & SCP Transfer
printf "\n${BLUE}[SYNC] Connecting to %s@%s:%s...${NC}\n" "$REMOTE_USER" "$REMOTE_HOST" "$REMOTE_PORT"

# Ensure remote directory exists
ssh -p "$REMOTE_PORT" -o StrictHostKeyChecking=accept-new "$REMOTE_USER@$REMOTE_HOST" "mkdir -p '$REMOTE_PATH'" 2>/dev/null || true

# Transmit file via SCP
if scp -P "$REMOTE_PORT" -o StrictHostKeyChecking=accept-new "$LATEST_ARCHIVE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"; then
    printf "\n${GREEN}[SUCCESS] Offsite encrypted backup sync complete!${NC}\n"
    printf "${CYAN}Remote Location:${NC} %s@%s:%s%s\n" "$REMOTE_USER" "$REMOTE_HOST" "$REMOTE_PATH" "$LATEST_ARCHIVE"
else
    printf "\n${RED}[ERROR] File transmission failed. Verify SSH credentials and remote host availability.${NC}\n"
    exit 1
fi
