#!/bin/bash
# Test suite for bootstrap scripts
# Tests installation scripts functionality and configuration

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
BOOTSTRAP_DIR="$SCRIPT_DIR/bootstrap"
TEST_DIR="/tmp/freespeech-bootstrap-test-$$"

# Setup test environment
setup() {
    mkdir -p "$TEST_DIR"
}

# Cleanup test environment
cleanup() {
    rm -rf "$TEST_DIR"
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
        echo "  In: $(echo "$haystack" | head -c 100)..."
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

assert_file_executable() {
    local filepath="$1"
    local message="$2"
    
    if [ -x "$filepath" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File not executable: $filepath"
        ((FAILED++))
        return 1
    fi
}

# Test 1: Check bootstrap scripts exist
test_bootstrap_scripts_exist() {
    echo ""
    echo "Test 1: Bootstrap scripts existence"
    echo "===================================="
    
    assert_file_exists "$BOOTSTRAP_DIR/install.sh" "install.sh should exist"
    assert_file_exists "$BOOTSTRAP_DIR/install-ubuntu.sh" "install-ubuntu.sh should exist"
    assert_file_exists "$BOOTSTRAP_DIR/install-centos.sh" "install-centos.sh should exist"
    assert_file_exists "$BOOTSTRAP_DIR/install-fedora.sh" "install-fedora.sh should exist"
    assert_file_exists "$BOOTSTRAP_DIR/install-macos.sh" "install-macos.sh should exist"
    assert_file_exists "$BOOTSTRAP_DIR/generate-certs.sh" "generate-certs.sh should exist"
    assert_file_exists "$BOOTSTRAP_DIR/uninstall.sh" "uninstall.sh should exist"
}

# Test 2: Check scripts are executable
test_bootstrap_scripts_executable() {
    echo ""
    echo "Test 2: Bootstrap scripts are executable"
    echo "========================================="
    
    assert_file_executable "$BOOTSTRAP_DIR/install.sh" "install.sh should be executable"
    assert_file_executable "$BOOTSTRAP_DIR/install-ubuntu.sh" "install-ubuntu.sh should be executable"
    assert_file_executable "$BOOTSTRAP_DIR/install-centos.sh" "install-centos.sh should be executable"
    assert_file_executable "$BOOTSTRAP_DIR/install-fedora.sh" "install-fedora.sh should be executable"
    assert_file_executable "$BOOTSTRAP_DIR/install-macos.sh" "install-macos.sh should be executable"
    assert_file_executable "$BOOTSTRAP_DIR/generate-certs.sh" "generate-certs.sh should be executable"
    assert_file_executable "$BOOTSTRAP_DIR/uninstall.sh" "uninstall.sh should be executable"
}

# Test 3: Check install.sh has required functions
test_install_sh_structure() {
    echo ""
    echo "Test 3: install.sh structure"
    echo "============================"
    
    content=$(cat "$BOOTSTRAP_DIR/install.sh")
    
    assert_contains "$content" "detect_distro" "Should have detect_distro function"
    assert_contains "$content" "install_nodejs" "Should have install_nodejs function"
    assert_contains "$content" "clone_repository" "Should have clone_repository function"
    assert_contains "$content" "install_dependencies" "Should have install_dependencies function"
    assert_contains "$content" "generate_certificates" "Should have generate_certificates function"
    assert_contains "$content" "create_service" "Should have create_service function"
    assert_contains "$content" "configure_firewall" "Should have configure_firewall function"
    assert_contains "$content" "start_service" "Should have start_service function"
}

# Test 4: Check install.sh configuration variables
test_install_sh_config() {
    echo ""
    echo "Test 4: install.sh configuration"
    echo "================================="
    
    content=$(cat "$BOOTSTRAP_DIR/install.sh")
    
    assert_contains "$content" "REPO_URL=" "Should have REPO_URL variable"
    assert_contains "$content" "INSTALL_DIR=" "Should have INSTALL_DIR variable"
    assert_contains "$content" "HTTP_PORT=" "Should have HTTP_PORT variable"
    assert_contains "$content" "HTTPS_PORT=" "Should have HTTPS_PORT variable"
    assert_contains "$content" "SERVICE_NAME=" "Should have SERVICE_NAME variable"
    assert_contains "$content" "NODE_VERSION=" "Should have NODE_VERSION variable"
}

# Test 5: Check update mode functionality
test_install_sh_update_mode() {
    echo ""
    echo "Test 5: install.sh update mode"
    echo "==============================="
    
    content=$(cat "$BOOTSTRAP_DIR/install.sh")
    
    assert_contains "$content" "UPDATE_MODE" "Should support UPDATE_MODE"
    assert_contains "$content" "update_system\|update_repository" "Should have update functions"
    assert_contains "$content" "systemctl is-active" "Should check service status"
}

# Test 6: Check platform-specific scripts have required functions
test_platform_scripts_structure() {
    echo ""
    echo "Test 6: Platform-specific scripts structure"
    echo "============================================"
    
    # Check Ubuntu script
    ubuntu_content=$(cat "$BOOTSTRAP_DIR/install-ubuntu.sh")
    assert_contains "$ubuntu_content" "platform_update_system" "Ubuntu: Should have platform_update_system"
    assert_contains "$ubuntu_content" "platform_configure_firewall" "Ubuntu: Should have platform_configure_firewall"
    assert_contains "$ubuntu_content" "platform_restart_service" "Ubuntu: Should have platform_restart_service"
    assert_contains "$ubuntu_content" "apt-get" "Ubuntu: Should use apt-get"
    
    # Check CentOS script
    centos_content=$(cat "$BOOTSTRAP_DIR/install-centos.sh")
    assert_contains "$centos_content" "platform_update_system" "CentOS: Should have platform_update_system"
    assert_contains "$centos_content" "platform_configure_firewall" "CentOS: Should have platform_configure_firewall"
    assert_contains "$centos_content" "platform_restart_service" "CentOS: Should have platform_restart_service"
    assert_contains "$centos_content" "yum\|dnf" "CentOS: Should use yum or dnf"
    
    # Check Fedora script
    fedora_content=$(cat "$BOOTSTRAP_DIR/install-fedora.sh")
    assert_contains "$fedora_content" "platform_update_system" "Fedora: Should have platform_update_system"
    assert_contains "$fedora_content" "platform_configure_firewall" "Fedora: Should have platform_configure_firewall"
    assert_contains "$fedora_content" "platform_restart_service" "Fedora: Should have platform_restart_service"
}

# Test 7: Check generate-certs.sh functionality
test_generate_certs_structure() {
    echo ""
    echo "Test 7: generate-certs.sh structure"
    echo "===================================="
    
    content=$(cat "$BOOTSTRAP_DIR/generate-certs.sh")
    
    assert_contains "$content" "openssl" "Should use openssl command"
    assert_contains "$content" "server.key" "Should generate server.key"
    assert_contains "$content" "server.crt" "Should generate server.crt"
    assert_contains "$content" "chmod" "Should set proper permissions"
    assert_contains "$content" "days" "Should set certificate validity period"
}

# Test 8: Check certificate generation with 100-year validity
test_certificate_validity() {
    echo ""
    echo "Test 8: Certificate validity period"
    echo "===================================="
    
    install_content=$(cat "$BOOTSTRAP_DIR/install.sh")
    gencert_content=$(cat "$BOOTSTRAP_DIR/generate-certs.sh")
    
    # Check for 100-year validity (36500 days)
    assert_contains "$install_content" "36500" "install.sh: Should use 36500 days for certificates"
    assert_contains "$gencert_content" "36500" "generate-certs.sh: Should use 36500 days for certificates"
}

# Test 9: Check systemd service configuration
test_systemd_service() {
    echo ""
    echo "Test 9: Systemd service configuration"
    echo "======================================"
    
    content=$(cat "$BOOTSTRAP_DIR/install.sh")
    
    assert_contains "$content" "systemd" "Should mention systemd"
    assert_contains "$content" "systemctl" "Should use systemctl commands"
    assert_contains "$content" "SERVICE_NAME" "Should create service using SERVICE_NAME variable"
    assert_contains "$content" "ExecStart" "Should define ExecStart directive"
    assert_contains "$content" "Restart=always" "Should have restart policy"
}

# Test 10: Check error handling
test_error_handling() {
    echo ""
    echo "Test 10: Error handling"
    echo "======================="
    
    install_content=$(cat "$BOOTSTRAP_DIR/install.sh")
    
    assert_contains "$install_content" "set -e" "Should exit on error (set -e)"
    assert_contains "$install_content" "EUID.*0\|running as root" "Should check for root user"
    assert_contains "$install_content" "os-release\|detect.*distro" "Should detect distribution"
}

# Test 11: Check Node.js installation
test_nodejs_installation() {
    echo ""
    echo "Test 11: Node.js installation"
    echo "=============================="
    
    install_content=$(cat "$BOOTSTRAP_DIR/install.sh")
    ubuntu_content=$(cat "$BOOTSTRAP_DIR/install-ubuntu.sh")
    
    assert_contains "$install_content" "install_nodejs" "install.sh: Should have Node.js installation"
    assert_contains "$ubuntu_content" "nodesource\|nodejs" "Ubuntu: Should install Node.js"
    assert_contains "$ubuntu_content" "NODE_VERSION" "Ubuntu: Should use NODE_VERSION variable"
}

# Test 12: Check firewall configuration
test_firewall_configuration() {
    echo ""
    echo "Test 12: Firewall configuration"
    echo "================================"
    
    ubuntu_content=$(cat "$BOOTSTRAP_DIR/install-ubuntu.sh")
    centos_content=$(cat "$BOOTSTRAP_DIR/install-centos.sh")
    
    assert_contains "$ubuntu_content" "ufw" "Ubuntu: Should configure UFW firewall"
    assert_contains "$centos_content" "firewall-cmd\|iptables" "CentOS: Should configure firewall"
}

# Test 13: Check repository cloning
test_repository_cloning() {
    echo ""
    echo "Test 13: Repository cloning"
    echo "==========================="
    
    content=$(cat "$BOOTSTRAP_DIR/install.sh")
    
    assert_contains "$content" "git clone" "Should clone git repository"
    assert_contains "$content" "git pull" "Should update existing repository"
    assert_contains "$content" "github.com/denisps/freespeechapp" "Should reference correct repository"
}

# Test 14: Check uninstall script
test_uninstall_script() {
    echo ""
    echo "Test 14: Uninstall script"
    echo "========================="
    
    content=$(cat "$BOOTSTRAP_DIR/uninstall.sh")
    
    assert_contains "$content" "systemctl stop\|service.*stop" "Should stop the service"
    assert_contains "$content" "systemctl disable\|service.*disable" "Should disable the service"
    assert_contains "$content" "rm.*service" "Should remove service file"
}

# Test 15: Check config file loading
test_config_file_loading() {
    echo ""
    echo "Test 15: Config file loading"
    echo "============================"
    
    content=$(cat "$BOOTSTRAP_DIR/install.sh")
    
    assert_contains "$content" "freespeech-deploy.conf" "Should reference config file"
    assert_contains "$content" "\." "Should source config file"
}

# Main test execution
main() {
    echo ""
    echo "FreeSpeechApp Bootstrap Scripts Tests"
    echo "======================================"
    echo ""
    
    setup
    
    test_bootstrap_scripts_exist
    test_bootstrap_scripts_executable
    test_install_sh_structure
    test_install_sh_config
    test_install_sh_update_mode
    test_platform_scripts_structure
    test_generate_certs_structure
    test_certificate_validity
    test_systemd_service
    test_error_handling
    test_nodejs_installation
    test_firewall_configuration
    test_repository_cloning
    test_uninstall_script
    test_config_file_loading
    
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
