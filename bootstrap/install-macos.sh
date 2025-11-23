#!/bin/bash
# FreeSpeechApp Bootstrap for macOS

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
INSTALL_DIR="${INSTALL_DIR:-$HOME/freespeechapp}"
HTTP_PORT="${HTTP_PORT:-8080}"
HTTPS_PORT="${HTTPS_PORT:-8443}"
STORAGE_LIMIT="${STORAGE_LIMIT:-10G}"
RAM_LIMIT="${RAM_LIMIT:-1G}"
SERVICE_NAME="org.freespeechapp"
NODE_VERSION="23"

echo -e "${GREEN}FreeSpeechApp Bootstrap for macOS${NC}"
echo "=========================================="

# Install Node.js and dependencies
install_nodejs() {
    echo -e "${YELLOW}Checking Node.js installation...${NC}"
    
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}Node.js not found. Installing via Homebrew...${NC}"
        
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo -e "${RED}Homebrew not found. Please install Homebrew first:${NC}"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
        
        brew install node
        echo -e "${GREEN}Node.js $(node --version) installed${NC}"
    else
        echo -e "${GREEN}Node.js $(node --version) already installed${NC}"
    fi
    
    # Ensure git is installed
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Installing git...${NC}"
        brew install git
    fi
    
    # Ensure openssl is installed
    if ! command -v openssl &> /dev/null; then
        echo -e "${YELLOW}Installing openssl...${NC}"
        brew install openssl
    fi
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

# Create LaunchAgent service
create_service() {
    echo -e "${YELLOW}Creating LaunchAgent service...${NC}"
    
    mkdir -p ~/Library/LaunchAgents
    
    cat > ~/Library/LaunchAgents/${SERVICE_NAME}.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${SERVICE_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/node</string>
        <string>$INSTALL_DIR/server/server.js</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR/server</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>NODE_ENV</key>
        <string>production</string>
        <key>HTTP_PORT</key>
        <string>$HTTP_PORT</string>
        <key>HTTPS_PORT</key>
        <string>$HTTPS_PORT</string>
        <key>STORAGE_LIMIT</key>
        <string>$STORAGE_LIMIT</string>
        <key>RAM_LIMIT</key>
        <string>$RAM_LIMIT</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/freespeechapp.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/freespeechapp.error.log</string>
</dict>
</plist>
EOF
    
    echo -e "${GREEN}LaunchAgent service created${NC}"
}

# Start service
start_service() {
    echo -e "${YELLOW}Starting service...${NC}"
    
    # Unload if already loaded
    launchctl unload ~/Library/LaunchAgents/${SERVICE_NAME}.plist 2>/dev/null || true
    
    # Load the service
    launchctl load ~/Library/LaunchAgents/${SERVICE_NAME}.plist
    sleep 2
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo -e "${GREEN}Service started successfully${NC}"
    else
        echo -e "${RED}Failed to start service${NC}"
        echo "Check logs: tail -f ~/Library/Logs/freespeechapp.error.log"
        exit 1
    fi
}

# Main installation flow
main() {
    if [ "$UPDATE_ONLY" = true ]; then
        # Only update service configuration
        echo -e "${YELLOW}Updating service configuration only...${NC}"
        create_service
        echo -e "${GREEN}Service configuration updated${NC}"
    else
        # Full installation
        install_nodejs
        clone_repository
        install_dependencies
        generate_certificates
        create_service
        start_service
        
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Installation completed successfully!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "Service: $SERVICE_NAME"
        echo "Status: launchctl list | grep freespeechapp"
        echo "Logs: tail -f ~/Library/Logs/freespeechapp.log"
        echo "Errors: tail -f ~/Library/Logs/freespeechapp.error.log"
        echo "HTTP Server: http://localhost:$HTTP_PORT"
        echo "HTTPS Server: https://localhost:$HTTPS_PORT"
        echo ""
        echo "Certificate location: $INSTALL_DIR/server/certs/"
        echo ""
        echo "To stop: launchctl unload ~/Library/LaunchAgents/${SERVICE_NAME}.plist"
        echo "To start: launchctl load ~/Library/LaunchAgents/${SERVICE_NAME}.plist"
        echo ""
    fi
}

main
