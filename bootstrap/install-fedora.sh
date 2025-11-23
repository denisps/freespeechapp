#!/bin/bash
# FreeSpeechApp Bootstrap for Fedora

set -e

NODE_VERSION="23"

echo "FreeSpeechApp Bootstrap for Fedora"
echo "==================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Install prerequisites
dnf install -y curl git openssl ca-certificates

# Install Node.js from NodeSource
if ! command -v node &> /dev/null; then
    echo "Installing Node.js ${NODE_VERSION}..."
    curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
    dnf install -y nodejs
    echo "Node.js $(node --version) installed"
else
    echo "Node.js $(node --version) already installed"
fi

# Platform-specific functions for install.sh to call
platform_update_system() {
    dnf upgrade -y
}

platform_configure_firewall() {
    local HTTP_PORT="${1:-80}"
    local HTTPS_PORT="${2:-443}"
    
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$HTTP_PORT/tcp
        firewall-cmd --permanent --add-port=$HTTPS_PORT/tcp
        firewall-cmd --reload
        echo "Firewall rules added for ports $HTTP_PORT and $HTTPS_PORT"
    fi
}

platform_restart_service() {
    local SERVICE_NAME="${1:-freespeechapp}"
    systemctl restart "$SERVICE_NAME"
}
