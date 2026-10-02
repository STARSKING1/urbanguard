#!/usr/bin/env bash
# ==============================================================================
# 45_IGNORE_TERMUX_SYSTEM_FILES.SH
# Excludes Termux system directories (.local, dotfiles) and datasets from Git
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - EXCLUDING TERMUX SYSTEM & ENVIRONMENT FILES                       ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Update .gitignore with comprehensive Termux system ignores
printf "${BLUE}[1/3] Updating .gitignore with Termux system rules...${NC}\n"
cat << 'GITIGNORE_EOF' > .gitignore
# Termux & Python System Files
.local/
.config/
.cache/
.termux/
.ssh/
.python_history
.bash_history
*.csv

# Embedded Git Repositories & Toolchains
flutter/
llama.cpp/
.cargo/
.rustup/
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

# 2. Unstage system directories and untracked files from Git index
printf "${BLUE}[2/3] Removing .local and system files from Git tracking...${NC}\n"
git rm -r --cached .local .python_history *.csv 2>/dev/null || true

# 3. Commit clean UrbanGuard codebase
printf "${BLUE}[3/3] Committing clean UrbanGuard production codebase...${NC}\n"
git add .gitignore
git add .
git commit -m "chore: exclude termux system dotfiles and clean release tree" || true

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] Termux system files purged from Git tracking!                         ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"
