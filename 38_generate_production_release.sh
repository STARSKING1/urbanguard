#!/usr/bin/env bash
# ==============================================================================
# 38_GENERATE_PRODUCTION_RELEASE.SH
# Packages UrbanGuard release bundle with SHA-256 cryptographic verification
# ==============================================================================
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - PRODUCTION RELEASE BUNDLE BUILDER                                ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

RELEASE_TAG="v1.0.0-production"
BUILD_DIR="$HOME/urbanguard_release_$RELEASE_TAG"
DIST_ARCHIVE="$HOME/urbanguard_release_$RELEASE_TAG.tar.gz"
MANIFEST_FILE="$HOME/urbanguard_release_$RELEASE_TAG.sha256"

# 1. Prepare clean build directory
printf "${BLUE}[1/4] Preparing release directory workspace...${NC}\n"
rm -rf "$BUILD_DIR" "$DIST_ARCHIVE" "$MANIFEST_FILE"
mkdir -p "$BUILD_DIR"/{bin,config,lib,db_schema,docs}

# 2. Copy production assets
printf "${BLUE}[2/4] Stage 1 production assets...${NC}\n"
cp -f "$HOME"/*.sh "$BUILD_DIR/bin/" 2>/dev/null || true
cp -f "$HOME"/pubspec.yaml "$BUILD_DIR/config/" 2>/dev/null || true
cp -rf "$HOME"/lib/* "$BUILD_DIR/lib/" 2>/dev/null || true
cp -f "$HOME"/ARCHITECTURE.md "$BUILD_DIR/docs/" 2>/dev/null || true

# Export database schema for deployment initialization
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$HOME/hazards.db" ]; then
    sqlite3 "$HOME/hazards.db" ".schema" > "$BUILD_DIR/db_schema/hazards_schema.sql" 2>/dev/null || true
fi

# 3. Create compressed release tarball
printf "${BLUE}[3/4] Creating compressed distribution archive...${NC}\n"
tar -czf "$DIST_ARCHIVE" -C "$HOME" "urbanguard_release_$RELEASE_TAG"

# 4. Generate SHA-256 Integrity Manifest
printf "${BLUE}[4/4] Generating SHA-256 cryptographic manifest...${NC}\n"
sha256sum "$DIST_ARCHIVE" > "$MANIFEST_FILE"

# Clean up staging folder
rm -rf "$BUILD_DIR"

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}[SUCCESS] UrbanGuard $RELEASE_TAG distribution built successfully!           ${NC}\n"
printf "${CYAN}  • Archive:  ${NC}%s (%s)\n" "$DIST_ARCHIVE" "$(du -h "$DIST_ARCHIVE" | cut -f1)"
printf "${CYAN}  • Manifest: ${NC}%s\n" "$MANIFEST_FILE"
printf "${CYAN}  • SHA-256:  ${NC}%s\n" "$(cut -d' ' -f1 "$MANIFEST_FILE")"
printf "${BLUE}================================================================================${NC}\n"
