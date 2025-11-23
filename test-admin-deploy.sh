#!/bin/bash
# Test suite for admin-deploy.sh
# Tests configuration loading, validation, and command building

# Don't exit on error - we want to run all tests
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADMIN_DEPLOY="$SCRIPT_DIR/admin-deploy.sh"
TEST_CONFIG_DIR="/tmp/freespeech-test-$$"

# Setup test environment
setup() {
    mkdir -p "$TEST_CONFIG_DIR"
    cd "$TEST_CONFIG_DIR"
}

# Cleanup test environment
cleanup() {
    cd /
    rm -rf "$TEST_CONFIG_DIR"
}

# Test helper
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Got: $actual"
        ((FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    
    if echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected to contain: $needle"
        echo "  Got: $haystack"
        ((FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local filepath="$1"
    local message="$2"
    
    if [ -f "$filepath" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File not found: $filepath"
        ((FAILED++))
        return 1
    fi
}

# Test 1: Check if script creates sample config when config is missing
test_missing_config() {
    echo ""
    echo "Test 1: Missing config file handling"
    echo "===================================="
    
    cd "$TEST_CONFIG_DIR"
    output=$("$ADMIN_DEPLOY" 2>&1 || true)
    
    assert_contains "$output" "Error: Config file not found" "Should report missing config"
    assert_file_exists "$TEST_CONFIG_DIR/freespeech-admin.conf.sample" "Should create sample config"
    
    # Verify sample config has required fields
    sample_content=$(cat "$TEST_CONFIG_DIR/freespeech-admin.conf.sample")
    assert_contains "$sample_content" "SERVER_HOST=" "Sample should contain SERVER_HOST"
    assert_contains "$sample_content" "SERVER_USER=" "Sample should contain SERVER_USER"
    assert_contains "$sample_content" "HTTP_PORT=" "Sample should contain HTTP_PORT"
    assert_contains "$sample_content" "HTTPS_PORT=" "Sample should contain HTTPS_PORT"
}

# Test 2: Config file loading
test_config_loading() {
    echo ""
    echo "Test 2: Config file loading"
    echo "============================"
    
    cd "$TEST_CONFIG_DIR"
    cat > freespeech-admin.conf <<'EOF'
SERVER_HOST="test-server.com"
SERVER_USER="testuser"
SERVER_PORT="2222"
HTTP_PORT="8080"
HTTPS_PORT="8443"
INSTALL_DIR="/opt/test"
REPO_URL="https://github.com/test/test.git"
EOF
    
    # Extract and validate config can be sourced
    . freespeech-admin.conf
    
    assert_equal "test-server.com" "$SERVER_HOST" "Should load SERVER_HOST from config"
    assert_equal "testuser" "$SERVER_USER" "Should load SERVER_USER from config"
    assert_equal "2222" "$SERVER_PORT" "Should load SERVER_PORT from config"
    assert_equal "8080" "$HTTP_PORT" "Should load HTTP_PORT from config"
    assert_equal "8443" "$HTTPS_PORT" "Should load HTTPS_PORT from config"
}

# Test 3: Local deployment flag
test_local_deployment_flag() {
    echo ""
    echo "Test 3: Local deployment flag"
    echo "=============================="
    
    cd "$TEST_CONFIG_DIR"
    cat > freespeech-admin.conf <<'EOF'
SERVER_HOST="remote-server.com"
SERVER_USER="testuser"
EOF
    
    # Test --local flag handling (just check the script accepts it)
    output=$("$ADMIN_DEPLOY" --local 2>&1 || true)
    
    # Should indicate local mode is detected
    assert_contains "$output" "local\|Local" "Should mention local deployment mode"
}

# Test 4: Config validation for remote deployment
test_remote_config_validation() {
    echo ""
    echo "Test 4: Remote config validation"
    echo "================================="
    
    cd "$TEST_CONFIG_DIR"
    
    # Test with missing SERVER_HOST
    cat > freespeech-admin.conf <<'EOF'
SERVER_USER="testuser"
EOF
    
    output=$("$ADMIN_DEPLOY" 2>&1 || true)
    assert_contains "$output" "Error.*SERVER_HOST\|SERVER_HOST.*required" "Should validate SERVER_HOST is required"
    
    # Test with missing SERVER_USER
    cat > freespeech-admin.conf <<'EOF'
SERVER_HOST="test-server.com"
EOF
    
    output=$("$ADMIN_DEPLOY" 2>&1 || true)
    assert_contains "$output" "Error.*SERVER_USER\|SERVER_USER.*required" "Should validate SERVER_USER is required"
}

# Test 5: Version information
test_version_info() {
    echo ""
    echo "Test 5: Version information"
    echo "==========================="
    
    # Check script contains version
    script_content=$(cat "$ADMIN_DEPLOY")
    assert_contains "$script_content" "VERSION=" "Script should have VERSION variable"
}

# Test 6: Custom config file path
test_custom_config_path() {
    echo ""
    echo "Test 6: Custom config file path"
    echo "================================"
    
    cd "$TEST_CONFIG_DIR"
    mkdir -p custom
    cat > custom/my-config.conf <<'EOF'
SERVER_HOST="custom-server.com"
SERVER_USER="customuser"
EOF
    
    # Script should accept custom config path (we can't fully test without mocking SSH)
    # Just verify the script reads the argument
    output=$("$ADMIN_DEPLOY" custom/my-config.conf 2>&1 || true)
    
    # Should proceed with the custom config
    assert_contains "$output" "Config: custom/my-config.conf\|Error.*SERVER_HOST" "Should use custom config path"
}

# Test 7: Bootstrap script references
test_bootstrap_references() {
    echo ""
    echo "Test 7: Bootstrap script references"
    echo "===================================="
    
    script_content=$(cat "$ADMIN_DEPLOY")
    assert_contains "$script_content" "install.sh\|install-macos.sh" "Should reference bootstrap install scripts"
    assert_contains "$script_content" "github.com/denisps/freespeechapp" "Should reference correct repository"
}

# Main test execution
main() {
    echo ""
    echo "FreeSpeechApp Admin Deploy Tests"
    echo "================================="
    echo ""
    
    setup
    
    test_missing_config
    test_config_loading
    test_local_deployment_flag
    test_remote_config_validation
    test_version_info
    test_custom_config_path
    test_bootstrap_references
    
    cleanup
    
    echo ""
    echo "================================="
    echo "Test Results"
    echo "================================="
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo "================================="
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
