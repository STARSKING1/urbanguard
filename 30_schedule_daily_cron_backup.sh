#!/usr/bin/env bash
# ==============================================================================
# 30_SCHEDULE_DAILY_CRON_BACKUP.SH
# Configures automated daily cron jobs in Termux for non-interactive 
# AES-256 encryption & SSH/SCP offsite synchronization.
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
printf "${CYAN}   URBANGUARD - AUTOMATED DAILY CRON BACKUP CONFIGURATOR                        ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Install cronie daemon package if missing
if ! command -v crontab >/dev/null 2>&1; then
    printf "${YELLOW}[DEPENDENCY] Installing cronie daemon in Termux...${NC}\n"
    pkg install cronie -y >/dev/null 2>&1 || true
fi

# 2. Configure Backup Passphrase for Automated Non-Interactive Encryption
PASS_FILE="$HOME/.urbanguard_backup_pass"

if [ ! -f "$PASS_FILE" ]; then
    printf "${CYAN}Set a permanent passphrase for automated daily encryption:${NC} "
    read -rs AUTO_PASS
    printf "\n"
    if [ -z "$AUTO_PASS" ]; then
        printf "${RED}[ERROR] Passphrase cannot be empty. Aborting setup.${NC}\n"
        exit 1
    fi
    printf "%s" "$AUTO_PASS" > "$PASS_FILE"
    chmod 600 "$PASS_FILE"
    printf "${GREEN}[SUCCESS] Encryption passphrase secured in $PASS_FILE${NC}\n"
fi

# 3. Prompt for Remote Sync Details (Stored in configuration)
CONFIG_FILE="$HOME/.urbanguard_remote_config"

if [ ! -f "$CONFIG_FILE" ]; then
    printf "\n${CYAN}Configure Remote SSH Target for Daily Sync:${NC}\n"
    read -rp "Remote SSH Host/IP [e.g., 192.168.1.107]: " R_HOST
    read -rp "Remote SSH Username [Default: root]: " R_USER
    R_USER="${R_USER:-root}"
    read -rp "Remote SSH Port [Default: 22]: " R_PORT
    R_PORT="${R_PORT:-22}"
    read -rp "Remote Target Path [Default: ~/urbanguard_backups/]: " R_PATH
    R_PATH="${R_PATH:-~/urbanguard_backups/}"

    cat << CONF_EOF > "$CONFIG_FILE"
REMOTE_HOST="$R_HOST"
REMOTE_USER="$R_USER"
REMOTE_PORT="$R_PORT"
REMOTE_PATH="$R_PATH"
CONF_EOF
    chmod 600 "$CONFIG_FILE"
fi

# 4. Create the Non-Interactive Worker Script executed by Crontab
WORKER_SCRIPT="$HOME/urbanguard_cron_worker.sh"

cat << 'WORKER_EOF' > "$WORKER_SCRIPT"
#!/usr/bin/env bash
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

PASS_FILE="$HOME/.urbanguard_backup_pass"
CONFIG_FILE="$HOME/.urbanguard_remote_config"
LOG_FILE="$HOME/urbanguard_cron_backup.log"

TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
ARCHIVE_NAME="urbanguard_full_backup_${TIMESTAMP}.tar.gz.enc"

source "$CONFIG_FILE"
PASSPHRASE=$(cat "$PASS_FILE")

echo "[$(date)] --- STARTING AUTOMATED DAILY BACKUP ---" >> "$LOG_FILE"

# 1. Compress & Encrypt Stack
tar -czf - \
    --exclude='.dart_tool' \
    --exclude='build' \
    --exclude='.git' \
    --exclude='*.tar.gz.enc' \
    --exclude='*.fifo' \
    --exclude='tmp' \
    "$HOME"/*.sh \
    "$HOME"/*.db \
    "$HOME"/*.md \
    "$HOME"/pubspec.yaml \
    "$HOME"/lib \
    "$HOME"/crypto_keys 2>/dev/null | \
openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:"$PASSPHRASE" -out "$HOME/$ARCHIVE_NAME"

echo "[$(date)] Encrypted archive built: $ARCHIVE_NAME" >> "$LOG_FILE"

# 2. SCP Offsite Sync
if [ -n "$REMOTE_HOST" ]; then
    ssh -p "$REMOTE_PORT" -o StrictHostKeyChecking=accept-new "$REMOTE_USER@$REMOTE_HOST" "mkdir -p '$REMOTE_PATH'" 2>/dev/null || true
    if scp -P "$REMOTE_PORT" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$HOME/$ARCHIVE_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" >> "$LOG_FILE" 2>&1; then
        echo "[$(date)] Offsite sync to $REMOTE_HOST SUCCESSFUL." >> "$LOG_FILE"
    else
        echo "[$(date)] WARNING: Offsite SCP sync failed. Check SSH keys." >> "$LOG_FILE"
    fi
fi

# 3. Local Cleanup: Retain only last 3 archives locally to conserve Android storage
ls -t "$HOME"/urbanguard_full_backup_*.tar.gz.enc 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true
echo "[$(date)] --- DAILY BACKUP COMPLETE ---" >> "$LOG_FILE"
WORKER_EOF

chmod +x "$WORKER_SCRIPT"

# 5. Register Entry in Crontab (Runs daily at 02:00 AM)
CRON_SCHEDULE="0 2 * * * bash $WORKER_SCRIPT >> $HOME/urbanguard_cron_backup.log 2>&1"

# Avoid duplicate crontab entries
(crontab -l 2>/dev/null | grep -v "urbanguard_cron_worker.sh"; echo "$CRON_SCHEDULE") | crontab -

# 6. Ensure Crond daemon is active
if ! pgrep crond >/dev/null 2>&1; then
    crond
fi

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] Daily backup crontab job configured successfully!${NC}\n"
printf "${CYAN}  • Schedule:      ${NC}Every day at 02:00 AM\n"
printf "${CYAN}  • Config File:   ${NC}%s\n" "$CONFIG_FILE"
printf "${CYAN}  • Passphrase:    ${NC}%s\n" "$PASS_FILE"
printf "${CYAN}  • Log File:      ${NC}%s\n" "$HOME/urbanguard_cron_backup.log"
printf "${BLUE}================================================================================${NC}\n"
