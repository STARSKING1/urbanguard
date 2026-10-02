#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}  URBANGUARD RESILIENCE ENGINE - ADVANCED MODULE RUNNER   ${NC}"
echo -e "${BLUE}==========================================================${NC}"

# 1. Execute Zero-Trust Anti-Replay Invalidation
bash 16_zero_trust_attestation.sh --test-replay

# 2. Execute Geo-Beacon Compression Test
bash 17_geo_beacon_engine.sh --test-cycle

# 3. Execute Chaos Stress Test
bash 18_chaos_stress_tester.sh --full-suite

# 4. Re-run Production Launcher
bash 11_production_launcher.sh

echo -e "${GREEN}==========================================================${NC}"
echo -e "${GREEN}  ALL ADVANCED MODULES & STRESS SUITES PASSED CLEANLY     ${NC}"
echo -e "${GREEN}==========================================================${NC}"
