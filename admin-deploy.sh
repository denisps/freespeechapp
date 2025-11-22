#!/bin/sh
# FreeSpeechApp Admin Deployment Script
# Simple remote server management tool

VERSION="1.0.0"
CONFIG_FILE="${1:-./freespeech-admin.conf}"

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo ""
    echo "Creating sample config: freespeech-admin.conf.sample"
    cat > freespeech-admin.conf.sample <<'EOF'
# FreeSpeechApp Admin Configuration
SERVER_HOST="your-server.com"
SERVER_USER="root"
SERVER_PORT="22"
SERVER_PASSWORD=""  # Optional - leave empty for SSH key
SERVER_TYPE="nodejs"  # nodejs or php
STORAGE_LIMIT="10G"
RAM_LIMIT="1G"
APP_PORT="8443"
INSTALL_DIR="/opt/freespeechapp"
REPO_URL="https://github.com/denisps/freespeechapp.git"
EOF
    echo "Edit freespeech-admin.conf.sample and save as freespeech-admin.conf"
    exit 1
fi

# Source config
. "$CONFIG_FILE"

# Validate required fields
if [ -z "$SERVER_HOST" ] || [ -z "$SERVER_USER" ]; then
    echo "Error: SERVER_HOST and SERVER_USER required in config"
    exit 1
fi

# Set defaults
SERVER_PORT="${SERVER_PORT:-22}"
SERVER_TYPE="${SERVER_TYPE:-nodejs}"
INSTALL_DIR="${INSTALL_DIR:-/opt/freespeechapp}"

# Build SSH command
if [ -n "$SERVER_PASSWORD" ] && command -v sshpass >/dev/null 2>&1; then
    SSH_CMD="sshpass -p '$SERVER_PASSWORD' ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
else
    SSH_CMD="ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
fi

# Execute remote command
remote() {
    eval "$SSH_CMD" "$1"
}

# Main menu
show_menu() {
    echo ""
    echo "FreeSpeechApp Admin - $SERVER_HOST"
    echo "======================================"
    echo "1) Check status"
    echo "2) Deploy/Install"
    echo "3) Update app"
    echo "4) Restart service"
    echo "5) View logs"
    echo "6) Check updates available"
    echo "0) Exit"
    echo ""
    printf "Choice: "
    read -r choice
    
    case $choice in
        1) 
            remote "systemctl status freespeechapp 2>/dev/null || echo 'Not installed'"
            remote "node --version 2>/dev/null || echo 'Node.js not installed'"
            ;;
        2)
            if [ "$SERVER_TYPE" = "nodejs" ]; then
                echo "Deploying Node.js server..."
                remote "export REPO_URL='$REPO_URL' && curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | bash"
            else
                echo "PHP not yet implemented"
            fi
            ;;
        3)
            echo "Updating app..."
            remote "cd $INSTALL_DIR && git pull && systemctl restart freespeechapp"
            ;;
        4)
            echo "Restarting service..."
            remote "systemctl restart freespeechapp"
            ;;
        5)
            remote "journalctl -u freespeechapp -n 50 --no-pager"
            ;;
        6)
            echo "Checking updates..."
            remote "cd $INSTALL_DIR 2>/dev/null && git fetch && git status -uno" || echo "Not installed"
            ;;
        0) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
}

# Check connectivity
echo "Connecting to $SERVER_HOST..."
if ! remote "echo 'Connected'" | grep -q "Connected"; then
    echo "Error: Cannot connect to server"
    exit 1
fi

echo "Connected successfully"

# Check if installed
if remote "systemctl is-active freespeechapp >/dev/null 2>&1"; then
    echo "Status: Running"
    
    # Check for updates
    if remote "cd $INSTALL_DIR 2>/dev/null && git fetch >/dev/null 2>&1 && [ \$(git rev-list HEAD..origin/main --count) -gt 0 ]"; then
        echo "Updates available!"
        printf "Update now? (y/N) "
        read -r answer
        [ "$answer" = "y" ] && remote "cd $INSTALL_DIR && git pull && systemctl restart freespeechapp" && echo "Updated"
    else
        echo "Up to date"
    fi
elif remote "[ -d $INSTALL_DIR ]"; then
    echo "Status: Stopped"
    printf "Start service? (y/N) "
    read -r answer
    [ "$answer" = "y" ] && remote "systemctl start freespeechapp"
else
    echo "Status: Not installed"
    printf "Install now? (y/N) "
    read -r answer
    if [ "$answer" = "y" ]; then
        remote "export REPO_URL='$REPO_URL' && curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | bash"
    fi
fi

# Interactive menu loop
while true; do
    show_menu
done
