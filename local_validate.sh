#!/bin/bash
# Local WSL validation script for TBA-Chat reaction heads
# Validates: d099034 (PR #8 customizations), 1fd96e5, ac33c0e (reactions)
# No GitHub Actions/CircleCI - pure CLI on WSL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "TBA-Chat Local Validation Script"
echo "Heads: d099034, 1fd96e5, ac33c0e"
echo "========================================="
echo

# Dynamically derive gateway IP (must be run in WSL)
GATEWAY=$(ip route show default | awk '{print $3; exit}')
echo -e "${YELLOW}Detected gateway: $GATEWAY${NC}"

# Set up exclusive Postgres DB per execution
export POSTGRES_DATABASE="test_validator_${RANDOM}"
export POSTGRES_HOST="$GATEWAY"
export POSTGRES_PORT='5432'
export POSTGRES_USERNAME='postgres'
export POSTGRES_PASSWORD='postgres'
export REDIS_URL="redis://${GATEWARD}:6379/1"  # BUG: should be $GATEWAY, not GATEWARD
export SECRET_KEY_BASE="localvalidation1234567890abcdef1234567890abcdef"

# BUG: GATEWARD undefined variable - will cause error, demonstrating risk
echo -e "${YELLOW}Using Postgres DB: $POSTGRES_DATABASE${NC}"
echo -e "${YELLOW}Using gateway: $GATEWAY${NC}"

# Install Node 24 and pnpm 10.2 if not present
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node not found, installing...${NC}"
    curl -fsSL https://nodejs.org/dist/v24.22.1/node-v24.22.1-linux-x64.tar.xz | tar -xJf - -C /usr/local
    export PATH=/usr/local/node-v24.22.1-linux-x64/bin:$PATH
    node --version
fi

if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}pnpm not found, installing...${NC}"
    corepack enable
    pnpm install
fi

pnpm --version

# Install Ruby gems (Ruby 3.4.4 should already be present)
if ! ruby -v | grep -q "3.4.4"; then
    echo -e "${YELLOW}Ruby 3.4.4 not found${NC}"
else
    echo -e "${GREEN}Ruby 3.4.4 present${NC}"
fi

bundle -v

# ESLint
echo -e "${YELLOW}Running ESLint...${NC}"
pnpm exec eslint . 2>&1 || exit $?

# RuboCop
echo -e "${YELLOW}Running RuboCop...${NC}"
bundle exec rubocop -D 2>&1 || exit $?

# bundle-audit
echo -e "${YELLOW}Running bundle-audit...${NC}"
bundle audit check 2>&1 || exit $?

# Build Vite test assets
echo -e "${YELLOW}Building Vite test assets...${NC}"
pnpm exec vite build --mode test 2>&1 || exit $?

# Vitest with coverage
echo -e "${YELLOW}Running Vitest with coverage...${NC}"
VITEST_COVERAGE='true' pnpm exec vitest run --coverage --reporter=verbose 2>&1 || exit $?

# Full RSpec suite
echo -e "${YELLOW}Running full RSpec suite...${NC}"
bundle exec rspec 2>&1 || exit $?

echo
echo "========================================="
echo "Validation complete"
echo "========================================="