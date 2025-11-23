#!/bin/bash
# FreeSpeechApp Server Bootstrap Script
# Supports: Ubuntu, Debian, CentOS, Fedora, RHEL

set -e

# Source config file if it exists
if [ -f "/tmp/freespeech-deploy.conf" ]; then
    . /tmp/freespeech-deploy.conf
fi

# Auto-detect update mode based on service status
if systemctl is-active --quiet freespeechapp 2>/dev/null; then
    UPDATE_MODE=true
else
    UPDATE_MODE="${UPDATE_MODE:-false}"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load configuration from file if available
CONFIG_FILE="${CONFIG_FILE:-/tmp/freespeech-deploy.conf}"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}Loading configuration from $CONFIG_FILE${NC}"
    . "$CONFIG_FILE"
fi

# Configuration
REPO_URL="${REPO_URL:-https://github.com/denisps/freespeechapp.git}"
INSTALL_DIR="${INSTALL_DIR:-/opt/freespeechapp}"
HTTP_PORT="${HTTP_PORT:-80}"
HTTPS_PORT="${HTTPS_PORT:-443}"
STORAGE_LIMIT="${STORAGE_LIMIT:-10G}"
RAM_LIMIT="${RAM_LIMIT:-1G}"
SERVICE_NAME="freespeechapp"
NODE_VERSION="23"

echo -e "${GREEN}FreeSpeechApp Server Bootstrap${NC}"
echo "========================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}Cannot detect Linux distribution${NC}"
        exit 1
    fi
    echo -e "${GREEN}Detected: $DISTRO $VERSION${NC}"
}

# Install Node.js based on distribution
install_nodejs() {
    echo -e "${YELLOW}Installing Node.js...${NC}"
    
    # Download and run platform-specific script from GitHub
    PLATFORM_SCRIPT=""
    case $DISTRO in
        ubuntu|debian)
            PLATFORM_SCRIPT="install-ubuntu.sh"
            ;;
        centos|rhel)
            PLATFORM_SCRIPT="install-centos.sh"
            ;;
        fedora)
            PLATFORM_SCRIPT="install-fedora.sh"
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
            exit 1
            ;;
    esac
    
    # Download and source platform-specific installer from GitHub
    echo -e "${YELLOW}Downloading platform installer for $DISTRO...${NC}"
    GITHUB_RAW="https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap"
    TEMP_PLATFORM_SCRIPT="/tmp/$PLATFORM_SCRIPT"
    curl -fsSL "$GITHUB_RAW/$PLATFORM_SCRIPT" -o "$TEMP_PLATFORM_SCRIPT"
    . "$TEMP_PLATFORM_SCRIPT"
    
    echo -e "${GREEN}Node.js $(node --version) installed${NC}"
}

# Clone repository
clone_repository() {
    echo -e "${YELLOW}Cloning repository...${NC}"
    
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Directory exists, updating...${NC}"
        cd "$INSTALL_DIR"
        git pull
    else
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
    
    echo -e "${GREEN}Repository cloned to $INSTALL_DIR${NC}"
}

# Install server dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing server dependencies...${NC}"
    cd "$INSTALL_DIR/server"
    npm install --production
    echo -e "${GREEN}Dependencies installed${NC}"
}

# Generate SSL certificates
generate_certificates() {
    echo -e "${YELLOW}Generating SSL certificates...${NC}"
    
    CERT_DIR="$INSTALL_DIR/server/certs"
    mkdir -p "$CERT_DIR"
    
    # Generate self-signed certificate valid for 100 years
    openssl req -x509 -nodes -days 36500 -newkey rsa:4096 \
        -keyout "$CERT_DIR/server.key" \
        -out "$CERT_DIR/server.crt" \
        -subj "/C=US/ST=State/L=City/O=FreeSpeechApp/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
    
    chmod 600 "$CERT_DIR/server.key"
    chmod 644 "$CERT_DIR/server.crt"
    
    echo -e "${GREEN}SSL certificates generated (valid for 100 years)${NC}"
}

# Create systemd service
create_service() {
    echo -e "${YELLOW}Creating systemd service...${NC}"
    
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=FreeSpeechApp Secure Communication Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/server
Environment=NODE_ENV=production
Environment=HTTP_PORT=$HTTP_PORT
Environment=HTTPS_PORT=$HTTPS_PORT
Environment=STORAGE_LIMIT=$STORAGE_LIMIT
Environment=RAM_LIMIT=$RAM_LIMIT
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    echo -e "${GREEN}Service created: $SERVICE_NAME${NC}"
}

# Configure firewall
configure_firewall() {
    echo -e "${YELLOW}Configuring firewall...${NC}"
    platform_configure_firewall "$HTTP_PORT" "$HTTPS_PORT"
    echo -e "${GREEN}Firewall rules added for ports $HTTP_PORT and $HTTPS_PORT${NC}"
}

# Update system packages
update_system() {
    echo -e "${YELLOW}Updating system packages...${NC}"
    platform_update_system
    echo -e "${GREEN}System packages updated${NC}"
}

# Update repository
update_repository() {
    echo -e "${YELLOW}Updating repository...${NC}"
    
    if [ -d "$INSTALL_DIR" ]; then
        cd "$INSTALL_DIR"
        git fetch
        git pull
        echo -e "${GREEN}Repository updated${NC}"
    else
        echo -e "${YELLOW}Repository not found, cloning...${NC}"
        clone_repository
    fi
}

# Update dependencies
update_dependencies() {
    echo -e "${YELLOW}Updating dependencies...${NC}"
    cd "$INSTALL_DIR/server"
    npm install --production
    echo -e "${GREEN}Dependencies updated${NC}"
}

# Restart service
restart_service() {
    echo -e "${YELLOW}Restarting service...${NC}"
    platform_restart_service "$SERVICE_NAME"
    sleep 2
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}Service restarted successfully${NC}"
    else
        echo -e "${RED}Failed to restart service${NC}"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi
}

# Start service
start_service() {
    echo -e "${YELLOW}Starting service...${NC}"
    systemctl start "$SERVICE_NAME"
    sleep 2
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}Service started successfully${NC}"
    else
        echo -e "${RED}Failed to start service${NC}"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi
}

# Main installation flow
main() {
    detect_distro
    
    if [ "$UPDATE_MODE" = true ]; then
        # Update mode: load platform functions first, then update
        echo -e "${YELLOW}Running update...${NC}"
        echo ""
        
        # Load platform-specific functions
        PLATFORM_SCRIPT=""
        case $DISTRO in
            ubuntu|debian)
                PLATFORM_SCRIPT="install-ubuntu.sh"
                ;;
            centos|rhel)
                PLATFORM_SCRIPT="install-centos.sh"
                ;;
            fedora)
                PLATFORM_SCRIPT="install-fedora.sh"
                ;;
        esac
        
        if [ -n "$PLATFORM_SCRIPT" ]; then
            if [ -f "$INSTALL_DIR/bootstrap/$PLATFORM_SCRIPT" ]; then
                . "$INSTALL_DIR/bootstrap/$PLATFORM_SCRIPT"
            else
                # Download from GitHub if not available locally
                GITHUB_RAW="https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap"
                TEMP_PLATFORM_SCRIPT="/tmp/$PLATFORM_SCRIPT"
                curl -fsSL "$GITHUB_RAW/$PLATFORM_SCRIPT" -o "$TEMP_PLATFORM_SCRIPT"
                . "$TEMP_PLATFORM_SCRIPT"
            fi
        fi
        
        update_system
        update_repository
        update_dependencies
        create_service
        restart_service
        
        echo ""
        echo -e "${GREEN}======================================${NC}"
        echo -e "${GREEN}Update completed successfully!${NC}"
        echo -e "${GREEN}======================================${NC}"
        echo ""
    else
        # Full installation
        install_nodejs
        clone_repository
        install_dependencies
        generate_certificates
        create_service
        configure_firewall
        start_service
        
        echo ""
        echo -e "${GREEN}======================================${NC}"
        echo -e "${GREEN}Installation completed successfully!${NC}"
        echo -e "${GREEN}======================================${NC}"
        echo ""
        echo "Service: $SERVICE_NAME"
        echo "Status: systemctl status $SERVICE_NAME"
        echo "Logs: journalctl -u $SERVICE_NAME -f"
        echo "HTTP Server: http://localhost:$HTTP_PORT"
        echo "HTTPS Server: https://localhost:$HTTPS_PORT"
        echo ""
        echo "Certificate location: $INSTALL_DIR/server/certs/"
        echo ""
    fi
}

main
