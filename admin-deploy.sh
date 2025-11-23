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
    echo "Creating sample config: freespeech-admin.conf.sample"
    cat > freespeech-admin.conf.sample <<'EOF'
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
    echo "Edit freespeech-admin.conf.sample and save as freespeech-admin.conf"
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
echo "Install Dir: $INSTALL_DIR"
echo "HTTP Port: $HTTP_PORT"
echo "HTTPS Port: $HTTPS_PORT"
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

# Check if already deployed
if [ "$LOCAL_DEPLOY" = true ] && [ "$OS_TYPE" = "macos" ]; then
    # macOS check
    IS_DEPLOYED=$(remote "launchctl list | grep -q freespeechapp 2>/dev/null && echo yes || echo no")
else
    # Linux check
    IS_DEPLOYED=$(remote "systemctl is-active --quiet freespeechapp 2>/dev/null && echo yes || echo no")
fi

if [ "$IS_DEPLOYED" = "yes" ]; then
    echo "FreeSpeechApp is already deployed. Running update..."
    echo ""
    
    # Update system packages (skip for macOS)
    if [ "$LOCAL_DEPLOY" = true ] && [ "$OS_TYPE" = "macos" ]; then
        echo "Skipping system update on macOS (run 'brew upgrade' manually if needed)"
    else
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
    fi
    
    # Update repository
    echo "Updating repository..."
    remote "cd $INSTALL_DIR && git fetch && git pull"
    
    # Update dependencies
    echo "Updating dependencies..."
    remote "cd $INSTALL_DIR/server && npm install --production"
    
    # Update service with new config
    if [ "$LOCAL_DEPLOY" = true ] && [ "$OS_TYPE" = "macos" ]; then
        echo "Updating service configuration..."
        remote "export REPO_URL='$REPO_URL' INSTALL_DIR='$INSTALL_DIR' HTTP_PORT='$HTTP_PORT' HTTPS_PORT='$HTTPS_PORT' STORAGE_LIMIT='$STORAGE_LIMIT' RAM_LIMIT='$RAM_LIMIT' && bash $(pwd)/bootstrap/install-macos.sh --update-only"
    else
        echo "Updating service configuration..."
        remote "export REPO_URL='$REPO_URL' INSTALL_DIR='$INSTALL_DIR' HTTP_PORT='$HTTP_PORT' HTTPS_PORT='$HTTPS_PORT' STORAGE_LIMIT='$STORAGE_LIMIT' RAM_LIMIT='$RAM_LIMIT' && curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | bash -s -- --update-only"
    fi
    
    # Restart service
    echo "Restarting service..."
    if [ "$LOCAL_DEPLOY" = true ] && [ "$OS_TYPE" = "macos" ]; then
        remote "launchctl unload ~/Library/LaunchAgents/org.freespeechapp.plist 2>/dev/null || true"
        remote "launchctl load ~/Library/LaunchAgents/org.freespeechapp.plist"
    else
        remote "systemctl restart freespeechapp"
    fi
    
    echo ""
    echo "Update complete!"
else
    # Run fresh installation
    echo "Starting fresh deployment..."
    if [ "$LOCAL_DEPLOY" = true ] && [ "$OS_TYPE" = "macos" ]; then
        remote "export REPO_URL='$REPO_URL' INSTALL_DIR='$INSTALL_DIR' HTTP_PORT='$HTTP_PORT' HTTPS_PORT='$HTTPS_PORT' STORAGE_LIMIT='$STORAGE_LIMIT' RAM_LIMIT='$RAM_LIMIT' && bash $(pwd)/bootstrap/install-macos.sh"
    else
        remote "export REPO_URL='$REPO_URL' INSTALL_DIR='$INSTALL_DIR' HTTP_PORT='$HTTP_PORT' HTTPS_PORT='$HTTPS_PORT' STORAGE_LIMIT='$STORAGE_LIMIT' RAM_LIMIT='$RAM_LIMIT' && curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | bash"
    fi
    
    echo ""
    echo "Deployment complete!"
fi
echo ""
echo "To manage the server, SSH in and use:"
echo "  systemctl status freespeechapp"
echo "  systemctl restart freespeechapp"
echo "  journalctl -u freespeechapp -f"
