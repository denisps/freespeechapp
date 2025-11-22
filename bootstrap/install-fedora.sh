#!/bin/bash
# FreeSpeechApp Bootstrap for Fedora

set -e

echo "FreeSpeechApp Bootstrap for Fedora"
echo "==================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Install prerequisites
dnf install -y curl git openssl

# Run main installation script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/install.sh"
