#!/bin/bash
# FreeSpeechApp Bootstrap for Ubuntu/Debian

set -e

NODE_VERSION="23"

echo "FreeSpeechApp Bootstrap for Ubuntu/Debian"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Update package list
apt-get update

# Install prerequisites
apt-get install -y curl git openssl ca-certificates gnupg

# Install Node.js from NodeSource
if ! command -v node &> /dev/null; then
    echo "Installing Node.js ${NODE_VERSION}..."
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt-get install -y nodejs
    echo "Node.js $(node --version) installed"
else
    echo "Node.js $(node --version) already installed"
fi

# Platform-specific functions for install.sh to call
platform_update_system() {
    apt-get update && apt-get upgrade -y
}

platform_configure_firewall() {
    local HTTP_PORT="${1:-80}"
    local HTTPS_PORT="${2:-443}"
    
    if command -v ufw &> /dev/null; then
        ufw allow $HTTP_PORT/tcp
        ufw allow $HTTPS_PORT/tcp
        echo "UFW rules added for ports $HTTP_PORT and $HTTPS_PORT"
    fi
}

platform_restart_service() {
    local SERVICE_NAME="${1:-freespeechapp}"
    systemctl restart "$SERVICE_NAME"
}
