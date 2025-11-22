#!/bin/bash
# FreeSpeechApp Server Bootstrap Script
# Supports: Ubuntu, Debian, CentOS, Fedora, RHEL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="${REPO_URL:-https://github.com/denisps/freespeechapp.git}"
INSTALL_DIR="/opt/freespeechapp"
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
    
    case $DISTRO in
        ubuntu|debian)
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
            apt-get install -y nodejs git
            ;;
        centos|rhel|fedora)
            curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
            if [ "$DISTRO" = "fedora" ]; then
                dnf install -y nodejs git
            else
                yum install -y nodejs git
            fi
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
            exit 1
            ;;
    esac
    
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
Environment=PORT=8443
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
                ufw allow 8443/tcp
                echo -e "${GREEN}UFW rule added for port 8443${NC}"
            fi
            ;;
        centos|rhel|fedora)
            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --add-port=8443/tcp
                firewall-cmd --reload
                echo -e "${GREEN}Firewall rule added for port 8443${NC}"
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
    echo "Server: wss://localhost:8443"
    echo ""
    echo "Certificate location: $INSTALL_DIR/server/certs/"
    echo ""
}

main
