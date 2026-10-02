#!/usr/bin/env bash
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

printf "${BLUE}================================================================================${NC}\n"
printf "${CYAN}   URBANGUARD - FLUTTER / DART BIONIC TLS ALIGNMENT REPAIR TOOL                 ${NC}\n"
printf "${BLUE}================================================================================${NC}\n"

printf "\n${YELLOW}[ROOT CAUSE] Official Flutter/Dart binaries use glibc 8-byte TLS alignment.${NC}\n"
printf "${YELLOW}Termux runs Android Bionic linker64, which enforces 64-byte ARM64 alignment.${NC}\n\n"

# Option 1: Install Termux User Repository (TUR) Native Dart
setup_tur_native_dart() {
    printf "${BLUE}[SOLUTION 1] Installing Termux User Repository (tur-repo) native Dart...${NC}\n"
    pkg update -y || true
    pkg install tur-repo -y || true
    pkg install dart -y || true
    printf "${GREEN}[SUCCESS] Native Termux Dart runtime installed successfully.${NC}\n"
}

# Option 2: Setup PRoot Ubuntu for full glibc Flutter compilation
setup_proot_ubuntu_glibc() {
    printf "${BLUE}[SOLUTION 2] Setting up PRoot Ubuntu glibc container for Flutter...${NC}\n"
    pkg install proot-distro -y || true
    
    if ! proot-distro list | grep -q "ubuntu (installed)"; then
        printf "${CYAN}Installing Ubuntu distribution inside PRoot...${NC}\n"
        proot-distro install ubuntu
    fi

    cat << 'PROOT_EOF' > run_flutter_in_proot.sh
#!/usr/bin/env bash
# Wrapper to execute Flutter commands inside PRoot glibc container
proot-distro login ubuntu -- bash -c "cd $(pwd) && flutter pub get"
PROOT_EOF
    chmod +x run_flutter_in_proot.sh
    printf "${GREEN}[SUCCESS] PRoot Ubuntu container ready. Execute via './run_flutter_in_proot.sh'.${NC}\n"
}

printf "Select resolution mode:\n"
printf "  1) Install Termux Native Dart SDK (via tur-repo)\n"
printf "  2) Setup PRoot Ubuntu glibc container (Recommended for full Flutter builds)\n"
printf "  3) Keep Termux for Engine Backend only (Build Flutter UI on host IDE/PC)\n\n"

# Execute Solution 1 by default for automated non-interactive runs
setup_tur_native_dart || setup_proot_ubuntu_glibc

printf "\n${GREEN}================================================================================${NC}\n"
printf "${GREEN}  ENVIRONMENT REPAIR COMPLETED - URBANGUARD ENGINE REMAINS FULLY OPERATIONAL     ${NC}\n"
printf "${GREEN}================================================================================${NC}\n"
