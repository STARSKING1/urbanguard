#!/usr/bin/env bash
# ==============================================================================
# 46_CLEAN_GIT_STAGING.SH
# Restricts Git repository staging to UrbanGuard resilience engine components only
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
printf "${CYAN}   URBANGUARD - SELECTIVE GIT REPOSITORY STAGING & PROTECTION                   ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Reset staging area completely
printf "${BLUE}[1/4] Unstaging current Git index...${NC}\n"
git reset

# 2. Write strict .gitignore to protect secrets and ignore non-UrbanGuard files
printf "${BLUE}[2/4] Updating .gitignore with strict security rules...${NC}\n"
cat << 'GITIGNORE_EOF' > .gitignore
# Ignore all dotfiles and secrets (CRITICAL: prevents credential leaks)
.*
!.gitignore

# Ignore unrelated personal scripts and data
*.py
*.c
*.cpp
*.txt
*.gif
*.xlsx
*.csv
*.json
*.sarif
a.out
myprogram
alla
landing-page/
downloads/
storage/
android/
ios/
models/
personal_ai/
q-shield-ecdat/
urbanguard/
__pycache__/

# SQLite Databases & Dynamic State
*.db
*.db-journal
*.db-wal
*.db-shm

# Logs & Temporary Files
*.log
*.tmp
*.fifo
api_server_output.log
watchdog_activity.log
sync_worker_activity.log
production_launch.log

# Backups & Compressed Releases
*.tar.gz
*.sha256
*.enc
backups/
urbanguard_release_*/

# External Toolchains & Caches
flutter/
llama.cpp/
.cargo/
.rustup/
.pub-cache/
.local/
.config/
.cache/
.termux/
GITIGNORE_EOF

# 3. Stage ONLY UrbanGuard files explicitly
printf "${BLUE}[3/4] Staging UrbanGuard core engine components...${NC}\n"
git add .gitignore
git add ARCHITECTURE.md pubspec.yaml lib/
git add [0-9][0-9]_*.sh 2>/dev/null || true
git add hazard_engine_server.sh master_control.sh member_sync_worker.sh start_daemons.sh start_hybrid.sh urbanguard_cron_worker.sh gps_telemetry_emulator.sh production_audit.sh run_e2e_tests.sh manage.sh hybrid_connectivity_router.sh 2>/dev/null || true

# 4. Set branch name to main and commit clean release
printf "${BLUE}[4/4] Creating clean production commit on branch 'main'...${NC}\n"
git branch -M main
git commit -m "feat: release UrbanGuard v1.0.0-production resilience engine" || true

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] UrbanGuard repository is clean, protected, and staged!                 ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"
