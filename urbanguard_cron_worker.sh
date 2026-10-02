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
