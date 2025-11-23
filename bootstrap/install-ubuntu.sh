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
