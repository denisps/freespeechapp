#!/bin/sh
# FreeSpeechApp Admin Deployment Script
# Simple remote server deployment tool

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
HTTP_PORT="80"
HTTPS_PORT="443"
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
INSTALL_DIR="${INSTALL_DIR:-/opt/freespeechapp}"
REPO_URL="${REPO_URL:-https://github.com/denisps/freespeechapp.git}"

# Set remaining defaults
SERVER_TYPE="${SERVER_TYPE:-nodejs}"
STORAGE_LIMIT="${STORAGE_LIMIT:-10G}"
RAM_LIMIT="${RAM_LIMIT:-1G}"
HTTP_PORT="${HTTP_PORT:-80}"
HTTPS_PORT="${HTTPS_PORT:-443}"

# Build SSH command
if [ -n "$SERVER_PASSWORD" ] && command -v sshpass >/dev/null 2>&1; then
    SSH_CMD="sshpass -p '$SERVER_PASSWORD' ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
else
    SSH_CMD="ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
fi

# Execute remote command
remote() {
    $SSH_CMD "$1"
}

# Main deployment
echo "FreeSpeechApp Deployment"
echo "========================"
echo "Server: $SERVER_HOST"
echo "Install Dir: $INSTALL_DIR"
echo "HTTP Port: $HTTP_PORT"
echo "HTTPS Port: $HTTPS_PORT"
echo ""

# Check connectivity
echo "Connecting to $SERVER_HOST..."
if ! remote "echo 'Connected'"; then
    echo "Error: Cannot connect to server"
    echo "Make sure SSH keys are set up or use: ssh-copy-id -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
    exit 1
fi

echo "Connected successfully"
echo ""

# Copy config file to remote server
echo "Copying configuration to server..."
CONFIG_REMOTE="/tmp/freespeech-deploy.conf"
scp -P "$SERVER_PORT" "$CONFIG_FILE" "$SERVER_USER@$SERVER_HOST:$CONFIG_REMOTE"

# Check if already deployed
if remote "systemctl is-active --quiet freespeechapp 2>/dev/null"; then
    echo "FreeSpeechApp is already deployed. Running update..."
    echo ""
    
    # Update system packages
    echo "Updating system packages..."
    remote "
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get upgrade -y
        elif command -v dnf >/dev/null 2>&1; then
            dnf upgrade -y
        elif command -v yum >/dev/null 2>&1; then
            yum update -y
        fi
    "
    
    # Update repository
    echo "Updating repository..."
    remote "cd $INSTALL_DIR && git fetch && git pull"
    
    # Update dependencies
    echo "Updating dependencies..."
    remote "cd $INSTALL_DIR/server && npm install --production"
    
    # Update systemd service with new config
    echo "Updating service configuration..."
    remote "export REPO_URL='$REPO_URL' INSTALL_DIR='$INSTALL_DIR' HTTP_PORT='$HTTP_PORT' HTTPS_PORT='$HTTPS_PORT' STORAGE_LIMIT='$STORAGE_LIMIT' RAM_LIMIT='$RAM_LIMIT' && curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | bash -s -- --update-only"
    
    # Restart service
    echo "Restarting service..."
    remote "systemctl restart freespeechapp"
    
    echo ""
    echo "Update complete!"
else
    # Run fresh installation
    echo "Starting fresh deployment from GitHub..."
    remote "export REPO_URL='$REPO_URL' INSTALL_DIR='$INSTALL_DIR' HTTP_PORT='$HTTP_PORT' HTTPS_PORT='$HTTPS_PORT' STORAGE_LIMIT='$STORAGE_LIMIT' RAM_LIMIT='$RAM_LIMIT' && curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | bash"
    
    echo ""
    echo "Deployment complete!"
fi
echo ""
echo "To manage the server, SSH in and use:"
echo "  systemctl status freespeechapp"
echo "  systemctl restart freespeechapp"
echo "  journalctl -u freespeechapp -f"
