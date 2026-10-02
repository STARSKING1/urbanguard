#!/usr/bin/env bash
# ==============================================================================
# 43_PUSH_TO_GITHUB.SH
# Prepares .gitignore, initializes Git repo, and pushes UrbanGuard to GitHub
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
printf "${CYAN}   URBANGUARD - GITHUB REPOSITORY PUBLISHER                                      ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

# 1. Install Git and GitHub CLI if missing
printf "${BLUE}[1/4] Checking Git installation...${NC}\n"
if ! command -v git >/dev/null 2>&1; then
    printf "${YELLOW}[SETUP] Installing git in Termux...${NC}\n"
    pkg install git -y >/dev/null 2>&1 || true
fi

if ! command -v gh >/dev/null 2>&1; then
    printf "${YELLOW}[SETUP] Installing gh (GitHub CLI) in Termux...${NC}\n"
    pkg install gh -y >/dev/null 2>&1 || true
fi

# 2. Generate production .gitignore
printf "${BLUE}[2/4] Generating production .gitignore...${NC}\n"
cat << 'GITIGNORE_EOF' > .gitignore
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
.pub-cache/

# Keys & Sensitive Credentials
*.pem
*.key
GITIGNORE_EOF

# 3. Initialize Git repository and commit local assets
printf "${BLUE}[3/4] Initializing repository and committing core source...${NC}\n"
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

git add .
git commit -m "feat: release UrbanGuard v1.0.0-production resilience engine" || true

# 4. Display push instructions
printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] Local Git repository initialized and production snapshot committed!    ${NC}\n"
printf "${CYAN}Run ONE of the options below to push to GitHub:                                 ${NC}\n\n"
printf "  ${YELLOW}Option A: Using GitHub CLI (Automated Create & Push)${NC}\n"
printf "    1. gh auth login\n"
printf "    2. gh repo create UrbanGuard --public --source=. --remote=origin --push\n\n"
printf "  ${YELLOW}Option B: Using an Existing Remote URL${NC}\n"
printf "    1. git remote add origin https://github.com/YOUR_USERNAME/UrbanGuard.git\n"
printf "    2. git push -u origin main\n"
printf "${BLUE}================================================================================${NC}\n"
