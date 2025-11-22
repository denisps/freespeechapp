#!/bin/bash
# Uninstall FreeSpeechApp

set -e

SERVICE_NAME="freespeechapp"
INSTALL_DIR="/opt/freespeechapp"

echo "FreeSpeechApp Uninstaller"
echo "========================="
echo ""
echo "This will remove:"
echo "  - Service: $SERVICE_NAME"
echo "  - Installation directory: $INSTALL_DIR"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Stop and disable service
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    echo "Stopping service..."
    systemctl stop "$SERVICE_NAME"
fi

if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
    echo "Disabling service..."
    systemctl disable "$SERVICE_NAME"
fi

# Remove service file
if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
    echo "Removing service file..."
    rm "/etc/systemd/system/${SERVICE_NAME}.service"
    systemctl daemon-reload
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
fi

echo ""
echo "Uninstallation completed!"
