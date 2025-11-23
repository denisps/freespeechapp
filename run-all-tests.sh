#!/bin/bash
# Master test runner for all FreeSpeechApp tests
# Runs server, admin-deploy, and bootstrap script tests

# Don't exit on error for individual test failures
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOTAL_PASSED=0
TOTAL_FAILED=0
SUITE_COUNT=0
FAILED_SUITES=""

echo ""
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}FreeSpeechApp Master Test Suite${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Test 1: Server Tests
echo -e "${YELLOW}Running Server Tests...${NC}"
echo ""

cd "$SCRIPT_DIR/server"

# Start server in background
USE_HTTPS=false HTTP_PORT=8080 node server.js > /tmp/test-server.log 2>&1 &
SERVER_PID=$!
sleep 3

# Run tests
if USE_HTTPS=false PORT=8080 npm test; then
    echo ""
    echo -e "${GREEN}✓ Server tests passed${NC}"
    ((TOTAL_PASSED++))
else
    echo ""
    echo -e "${RED}✗ Server tests failed${NC}"
    ((TOTAL_FAILED++))
    FAILED_SUITES="$FAILED_SUITES\n- Server tests"
fi

# Stop server
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true

((SUITE_COUNT++))

echo ""
echo -e "${BLUE}--------------------------------${NC}"
echo ""

# Test 2: Admin Deploy Tests
echo -e "${YELLOW}Running Admin Deploy Tests...${NC}"
echo ""

cd "$SCRIPT_DIR"

if ./test-admin-deploy.sh; then
    echo ""
    echo -e "${GREEN}✓ Admin deploy tests passed${NC}"
    ((TOTAL_PASSED++))
else
    echo ""
    echo -e "${RED}✗ Admin deploy tests failed${NC}"
    ((TOTAL_FAILED++))
    FAILED_SUITES="$FAILED_SUITES\n- Admin deploy tests"
fi

((SUITE_COUNT++))

echo ""
echo -e "${BLUE}--------------------------------${NC}"
echo ""

# Test 3: Bootstrap Tests
echo -e "${YELLOW}Running Bootstrap Tests...${NC}"
echo ""

if ./test-bootstrap.sh; then
    echo ""
    echo -e "${GREEN}✓ Bootstrap tests passed${NC}"
    ((TOTAL_PASSED++))
else
    echo ""
    echo -e "${RED}✗ Bootstrap tests failed${NC}"
    ((TOTAL_FAILED++))
    FAILED_SUITES="$FAILED_SUITES\n- Bootstrap tests"
fi

((SUITE_COUNT++))

echo ""
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Final Test Results${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""
echo "Test Suites: $SUITE_COUNT"
echo -e "${GREEN}Passed Suites: $TOTAL_PASSED${NC}"
echo -e "${RED}Failed Suites: $TOTAL_FAILED${NC}"
echo ""

if [ $TOTAL_FAILED -gt 0 ]; then
    echo -e "${RED}Failed test suites:${NC}"
    echo -e "$FAILED_SUITES"
    echo ""
    exit 1
else
    echo -e "${GREEN}All test suites passed! ✓${NC}"
    echo ""
    exit 0
fi
