#!/bin/bash
# FreeSpeechApp Bootstrap for Fedora

set -e

NODE_VERSION="18"

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
