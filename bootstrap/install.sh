#!/bin/bash
# FreeSpeechApp Server Bootstrap Script
# Supports: Ubuntu, Debian, CentOS, Fedora, RHEL

set -e

# Check for update-only flag
UPDATE_ONLY=false
if [ "$1" = "--update-only" ]; then
    UPDATE_ONLY=true
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
NODE_VERSION="18"

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
    
    # Download and execute platform-specific installer from GitHub
    echo -e "${YELLOW}Downloading platform installer for $DISTRO...${NC}"
    GITHUB_RAW="https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap"
    curl -fsSL "$GITHUB_RAW/$PLATFORM_SCRIPT" | bash
    
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
    
    case $DISTRO in
        ubuntu|debian)
            if command -v ufw &> /dev/null; then
                ufw allow $HTTP_PORT/tcp
                ufw allow $HTTPS_PORT/tcp
                echo -e "${GREEN}UFW rules added for ports $HTTP_PORT and $HTTPS_PORT${NC}"
            fi
            ;;
        centos|rhel|fedora)
            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --add-port=$HTTP_PORT/tcp
                firewall-cmd --permanent --add-port=$HTTPS_PORT/tcp
                firewall-cmd --reload
                echo -e "${GREEN}Firewall rules added for ports $HTTP_PORT and $HTTPS_PORT${NC}"
            fi
            ;;
    esac
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
    if [ "$UPDATE_ONLY" = true ]; then
        # Only update service configuration
        echo -e "${YELLOW}Updating service configuration only...${NC}"
        detect_distro
        create_service
        echo -e "${GREEN}Service configuration updated${NC}"
    else
        # Full installation
        detect_distro
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
