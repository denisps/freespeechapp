#!/bin/sh
# FreeSpeechApp Admin Deployment Script
# Simple remote server deployment tool

VERSION="1.0.0"

# Check for local deployment flag
if [ "$1" = "--local" ] || [ "$1" = "-l" ]; then
    LOCAL_DEPLOY=true
    CONFIG_FILE="${2:-./freespeech-admin.conf}"
else
    LOCAL_DEPLOY=false
    CONFIG_FILE="${1:-./freespeech-admin.conf}"
fi

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo ""
    echo "Creating config file: $CONFIG_FILE"
    cat > "$CONFIG_FILE" <<'EOF'
# FreeSpeechApp Admin Configuration
SERVER_HOST="your-server.com"  # Use "localhost" for local deployment
SERVER_USER="root"
SERVER_PORT="22"
SERVER_PASSWORD=""  # Optional - leave empty for SSH key
SERVER_TYPE="nodejs"  # nodejs or php
STORAGE_LIMIT="10G"
RAM_LIMIT="1G"
HTTP_PORT="80"
HTTPS_PORT="443"
INSTALL_DIR="/opt/freespeechapp"
REPO_URL="https://github.com/denisps/freespeechapp.git"
EOF
    echo "Created $CONFIG_FILE - please edit with your server details"
    echo ""
    echo "For local deployment, use: ./admin-deploy.sh --local"
    exit 1
fi

# Source config
. "$CONFIG_FILE"

# Handle local deployment
if [ "$LOCAL_DEPLOY" = true ]; then
    echo "Local deployment mode"
    SERVER_HOST="localhost"
    
    # Check OS for local deployment
    if [ "$(uname)" = "Darwin" ]; then
        echo "Detected macOS"
        OS_TYPE="macos"
    elif [ "$(uname)" = "Linux" ]; then
        echo "Detected Linux"
        OS_TYPE="linux"
    else
        echo "Error: Unsupported OS for local deployment"
        exit 1
    fi
fi

# Validate required fields for remote deployment
if [ "$LOCAL_DEPLOY" = false ]; then
    if [ -z "$SERVER_HOST" ] || [ -z "$SERVER_USER" ]; then
        echo "Error: SERVER_HOST and SERVER_USER required in config"
        exit 1
    fi
fi

# Build SSH command or local command
if [ "$LOCAL_DEPLOY" = true ]; then
    # Local deployment - run commands directly
    remote() {
        eval "$1"
    }
    
    # Copy config is not needed for local
    copy_config() {
        echo "Using local configuration..."
    }
else
    # Remote deployment via SSH
    # Build SSH command
    if [ -n "$SERVER_PASSWORD" ] && command -v sshpass >/dev/null 2>&1; then
        SSH_CMD="sshpass -p '$SERVER_PASSWORD' ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
        SCP_CMD="sshpass -p '$SERVER_PASSWORD' scp -P $SERVER_PORT"
    else
        SSH_CMD="ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
        SCP_CMD="scp -P $SERVER_PORT"
    fi
    
    # Execute remote command
    remote() {
        $SSH_CMD "$1"
    }
    
    # Copy config file
    copy_config() {
        echo "Copying configuration to server..."
        CONFIG_REMOTE="/tmp/freespeech-deploy.conf"
        $SCP_CMD "$CONFIG_FILE" "$SERVER_USER@$SERVER_HOST:$CONFIG_REMOTE"
    }
fi

# Main deployment
echo "FreeSpeechApp Deployment"
echo "========================"
if [ "$LOCAL_DEPLOY" = true ]; then
    echo "Mode: Local"
    echo "OS: $OS_TYPE"
else
    echo "Mode: Remote"
fi
echo "Server: $SERVER_HOST"
echo "Config: $CONFIG_FILE"
echo ""

# Check connectivity (skip for local)
if [ "$LOCAL_DEPLOY" = false ]; then
    echo "Connecting to $SERVER_HOST..."
    if ! remote "echo 'Connected'"; then
        echo "Error: Cannot connect to server"
        echo "Make sure SSH keys are set up or use: ssh-copy-id -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
        exit 1
    fi
    echo "Connected successfully"
    echo ""
fi

# Copy config file
copy_config

# Run installation/update
# The install script will source the config file and handle updates automatically
if [ "$LOCAL_DEPLOY" = true ] && [ "$OS_TYPE" = "macos" ]; then
    remote "$(pwd)/bootstrap/install-macos.sh 2>/dev/null || curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-macos.sh | bash"
else
    remote "curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | bash"
fi

echo ""
echo "Deployment complete!"
echo ""
echo "To manage the server, SSH in and use:"
echo "  systemctl status freespeechapp"
echo "  systemctl restart freespeechapp"
echo "  journalctl -u freespeechapp -f"
