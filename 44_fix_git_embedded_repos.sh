#!/usr/bin/env bash
# ==============================================================================
# 44_FIX_GIT_EMBEDDED_REPOS.SH
# Cleans Git index, excludes toolchains/embedded repos, and normalizes line endings
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - GIT EMBEDDED REPO & IGNORE CLEANUP                              ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Configure line ending handling
printf "${BLUE}[1/4] Setting Git line ending configuration...${NC}\n"
git config core.autocrlf input

# 2. Reset staged files to clear bad indexing
printf "${BLUE}[2/4] Unstaging current Git index...${NC}\n"
git reset

# 3. Update .gitignore with toolchain & embedded repo rules
printf "${BLUE}[3/4] Updating .gitignore to exclude embedded repos & toolchains...${NC}\n"
cat << 'GITIGNORE_EOF' > .gitignore
# Embedded Git Repositories & External Toolchains
flutter/
llama.cpp/
.cargo/
.rustup/
.cache/
.pub-cache/

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

# Flutter / Dart Build Artifacts
.dart_tool/
.idea/
.vscode/
build/
.packages
.pub/

# Keys & Sensitive Credentials
*.pem
*.key
GITIGNORE_EOF

# 4. Remove cached untracked embedded repos from index if present
git rm --cached -r flutter llama.cpp .cargo 2>/dev/null || true

# 5. Re-stage clean UrbanGuard assets and commit
printf "${BLUE}[4/4] Staging clean project assets and committing...${NC}\n"
git add .
git commit -m "feat: clean production build for UrbanGuard v1.0.0-production" || true

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] Git index cleaned! Embedded repos and toolchains excluded.            ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"
