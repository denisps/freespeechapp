#!/bin/sh
# FreeSpeechApp Admin Deployment Script
# Simple Unix shell script with no special Linux dependencies
# Manages remote server deployment and updates

# Script version
VERSION="1.0.0"

# Default config file location
CONFIG_FILE="${1:-./freespeech-admin.conf}"

# Colors for output (using simple escape codes)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Load configuration file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Config file not found: $CONFIG_FILE"
        create_sample_config
        exit 1
    fi
    
    print_info "Loading config from: $CONFIG_FILE"
    
    # Source the config file
    . "$CONFIG_FILE"
    
    # Validate required fields
    if [ -z "$SERVER_HOST" ]; then
        print_error "SERVER_HOST not set in config file"
        exit 1
    fi
    
    if [ -z "$SERVER_USER" ]; then
        print_error "SERVER_USER not set in config file"
        exit 1
    fi
    
    # Set defaults
    SERVER_PORT="${SERVER_PORT:-22}"
    SERVER_TYPE="${SERVER_TYPE:-nodejs}"
    STORAGE_LIMIT="${STORAGE_LIMIT:-10G}"
    RAM_LIMIT="${RAM_LIMIT:-1G}"
    APP_PORT="${APP_PORT:-8443}"
    INSTALL_DIR="${INSTALL_DIR:-/opt/freespeechapp}"
    REPO_URL="${REPO_URL:-https://github.com/denisps/freespeechapp.git}"
    
    print_success "Config loaded successfully"
}

# Create sample config file
create_sample_config() {
    cat > "freespeech-admin.conf.sample" <<'EOF'
# FreeSpeechApp Admin Configuration
# Copy this to freespeech-admin.conf and edit values

# Server connection details
SERVER_HOST="your-server.com"
SERVER_USER="root"
SERVER_PORT="22"
SERVER_PASSWORD=""  # Optional - leave empty to use SSH key

# Server type: nodejs or php
SERVER_TYPE="nodejs"

# Resource limits
STORAGE_LIMIT="10G"  # Disk space limit
RAM_LIMIT="1G"       # RAM limit for the application

# Application settings
APP_PORT="8443"
INSTALL_DIR="/opt/freespeechapp"
REPO_URL="https://github.com/denisps/freespeechapp.git"
EOF
    
    print_info "Sample config created: freespeech-admin.conf.sample"
    print_info "Copy it to freespeech-admin.conf and edit the values"
}

# Build SSH command
build_ssh_cmd() {
    SSH_CMD="ssh -p $SERVER_PORT"
    
    # Add password option if provided (using sshpass if available)
    if [ -n "$SERVER_PASSWORD" ]; then
        if command -v sshpass >/dev/null 2>&1; then
            SSH_CMD="sshpass -p '$SERVER_PASSWORD' $SSH_CMD"
        else
            print_warning "sshpass not found. Password authentication requires sshpass."
            print_warning "Install: apt install sshpass (Ubuntu/Debian) or yum install sshpass (CentOS/RHEL)"
            print_warning "Or use SSH key authentication instead (recommended)"
        fi
    fi
    
    SSH_CMD="$SSH_CMD $SERVER_USER@$SERVER_HOST"
}

# Execute remote command
remote_exec() {
    eval "$SSH_CMD" "$1" 2>&1
}

# Check server connectivity
check_connectivity() {
    print_info "Checking connectivity to $SERVER_HOST..."
    
    if remote_exec "echo 'Connected'" | grep -q "Connected"; then
        print_success "Connected to server"
        return 0
    else
        print_error "Failed to connect to server"
        return 1
    fi
}

# Check if server is running
check_server_status() {
    print_info "Checking server status..."
    
    if [ "$SERVER_TYPE" = "nodejs" ]; then
        STATUS=$(remote_exec "systemctl is-active freespeechapp 2>/dev/null || echo 'not-installed'")
        
        case "$STATUS" in
            active)
                print_success "Server is running"
                return 0
                ;;
            inactive|failed)
                print_warning "Server is installed but not running"
                return 1
                ;;
            not-installed)
                print_warning "Server is not installed"
                return 2
                ;;
        esac
    elif [ "$SERVER_TYPE" = "php" ]; then
        print_warning "PHP server type not yet implemented"
        return 3
    fi
}

# Get current versions
get_versions() {
    print_info "Checking current versions..."
    
    # OS version
    OS_VERSION=$(remote_exec "cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"'")
    print_info "OS: $OS_VERSION"
    
    # Node.js version
    if [ "$SERVER_TYPE" = "nodejs" ]; then
        NODE_VERSION=$(remote_exec "node --version 2>/dev/null || echo 'not installed'")
        print_info "Node.js: $NODE_VERSION"
    fi
    
    # App version (check last commit)
    if remote_exec "[ -d $INSTALL_DIR/.git ]" >/dev/null 2>&1; then
        APP_VERSION=$(remote_exec "cd $INSTALL_DIR && git log -1 --format='%h %s' 2>/dev/null")
        print_info "App version: $APP_VERSION"
    else
        print_info "App: not installed"
    fi
}

# Check for system updates
check_system_updates() {
    print_info "Checking for system updates..."
    
    # Detect package manager
    if remote_exec "command -v apt-get >/dev/null 2>&1" >/dev/null; then
        UPDATES=$(remote_exec "apt-get update >/dev/null 2>&1 && apt-get -s upgrade 2>/dev/null | grep -c '^Inst'")
        if [ "$UPDATES" -gt 0 ]; then
            print_warning "$UPDATES system packages can be updated"
            return 0
        fi
    elif remote_exec "command -v yum >/dev/null 2>&1" >/dev/null; then
        UPDATES=$(remote_exec "yum check-update 2>/dev/null | grep -v '^$' | grep -v 'Last metadata' | wc -l")
        if [ "$UPDATES" -gt 0 ]; then
            print_warning "$UPDATES system packages can be updated"
            return 0
        fi
    fi
    
    print_success "System is up to date"
    return 1
}

# Check for Node.js updates
check_nodejs_updates() {
    if [ "$SERVER_TYPE" != "nodejs" ]; then
        return 1
    fi
    
    print_info "Checking Node.js version..."
    
    CURRENT=$(remote_exec "node --version 2>/dev/null | cut -d. -f1 | tr -d 'v'")
    if [ -z "$CURRENT" ]; then
        print_warning "Node.js not installed"
        return 0
    fi
    
    # Latest LTS is v18 or v20 - we'll use 18 for stability
    LATEST="18"
    
    if [ "$CURRENT" -lt "$LATEST" ]; then
        print_warning "Node.js $CURRENT installed, v$LATEST available"
        return 0
    fi
    
    print_success "Node.js is current (v$CURRENT)"
    return 1
}

# Check for app updates
check_app_updates() {
    print_info "Checking for app updates..."
    
    if ! remote_exec "[ -d $INSTALL_DIR/.git ]" >/dev/null 2>&1; then
        print_warning "App not installed"
        return 0
    fi
    
    # Fetch updates
    remote_exec "cd $INSTALL_DIR && git fetch origin >/dev/null 2>&1"
    
    # Check if behind
    BEHIND=$(remote_exec "cd $INSTALL_DIR && git rev-list HEAD..origin/main --count 2>/dev/null")
    
    if [ -z "$BEHIND" ]; then
        BEHIND=0
    fi
    
    if [ "$BEHIND" -gt 0 ]; then
        print_warning "App is $BEHIND commits behind"
        return 0
    fi
    
    print_success "App is up to date"
    return 1
}

# Check resource usage
check_resources() {
    print_info "Checking resource usage..."
    
    # Check disk space
    DISK_USAGE=$(remote_exec "df $INSTALL_DIR 2>/dev/null | tail -1 | awk '{print \$5}' | tr -d '%'")
    if [ -n "$DISK_USAGE" ]; then
        print_info "Disk usage: ${DISK_USAGE}%"
        if [ "$DISK_USAGE" -gt 80 ]; then
            print_warning "Disk usage is high (${DISK_USAGE}%)"
        fi
    fi
    
    # Check memory
    MEM_USAGE=$(remote_exec "free | grep Mem | awk '{printf \"%.0f\", \$3/\$2 * 100}'")
    if [ -n "$MEM_USAGE" ]; then
        print_info "Memory usage: ${MEM_USAGE}%"
        if [ "$MEM_USAGE" -gt 80 ]; then
            print_warning "Memory usage is high (${MEM_USAGE}%)"
        fi
    fi
    
    # Check if app process is using too much memory
    if [ "$SERVER_TYPE" = "nodejs" ]; then
        APP_MEM=$(remote_exec "ps aux | grep 'node.*server.js' | grep -v grep | awk '{print \$6}' | head -1")
        if [ -n "$APP_MEM" ]; then
            APP_MEM_MB=$((APP_MEM / 1024))
            print_info "App memory: ${APP_MEM_MB}MB"
        fi
    fi
}

# Install system updates
install_system_updates() {
    print_info "Installing system updates..."
    
    if remote_exec "command -v apt-get >/dev/null 2>&1" >/dev/null; then
        remote_exec "apt-get update && apt-get upgrade -y"
    elif remote_exec "command -v yum >/dev/null 2>&1" >/dev/null; then
        remote_exec "yum update -y"
    fi
    
    print_success "System updates installed"
}

# Update Node.js
update_nodejs() {
    print_info "Updating Node.js..."
    
    if remote_exec "command -v apt-get >/dev/null 2>&1" >/dev/null; then
        remote_exec "curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs"
    elif remote_exec "command -v yum >/dev/null 2>&1" >/dev/null; then
        remote_exec "curl -fsSL https://rpm.nodesource.com/setup_18.x | bash - && yum install -y nodejs"
    fi
    
    print_success "Node.js updated"
}

# Update app
update_app() {
    print_info "Updating app..."
    
    # Pull latest changes
    remote_exec "cd $INSTALL_DIR && git pull origin main"
    
    # Restart service
    if [ "$SERVER_TYPE" = "nodejs" ]; then
        remote_exec "systemctl restart freespeechapp"
    fi
    
    print_success "App updated and restarted"
}

# Deploy fresh installation
deploy_fresh() {
    print_info "Deploying fresh installation..."
    
    if [ "$SERVER_TYPE" = "nodejs" ]; then
        # Download and run install script
        print_info "Running installation script..."
        remote_exec "export REPO_URL='$REPO_URL' && curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | bash"
        
        print_success "Fresh installation completed"
    elif [ "$SERVER_TYPE" = "php" ]; then
        print_error "PHP server type not yet implemented"
        return 1
    fi
}

# Interactive menu
show_menu() {
    echo ""
    echo "=========================================="
    echo "  FreeSpeechApp Admin Control Panel"
    echo "=========================================="
    echo "Server: $SERVER_USER@$SERVER_HOST:$SERVER_PORT"
    echo "Type: $SERVER_TYPE"
    echo "=========================================="
    echo ""
    echo "1) Check status"
    echo "2) Check for updates"
    echo "3) Install system updates"
    echo "4) Update Node.js"
    echo "5) Update app"
    echo "6) Deploy fresh installation"
    echo "7) Check resource usage"
    echo "8) Restart server"
    echo "9) View logs"
    echo "0) Exit"
    echo ""
    printf "Enter choice [0-9]: "
    read -r choice
    
    case $choice in
        1) check_server_status; get_versions ;;
        2) check_system_updates; check_nodejs_updates; check_app_updates ;;
        3) install_system_updates ;;
        4) update_nodejs ;;
        5) update_app ;;
        6) deploy_fresh ;;
        7) check_resources ;;
        8) remote_exec "systemctl restart freespeechapp"; print_success "Server restarted" ;;
        9) remote_exec "journalctl -u freespeechapp -n 50 --no-pager" ;;
        0) exit 0 ;;
        *) print_error "Invalid choice" ;;
    esac
}

# Main function
main() {
    echo ""
    echo "FreeSpeechApp Admin Script v${VERSION}"
    echo "========================================"
    echo ""
    
    # Load configuration
    load_config
    
    # Build SSH command
    build_ssh_cmd
    
    # Check connectivity
    if ! check_connectivity; then
        exit 1
    fi
    
    # Check initial status
    check_server_status
    STATUS_CODE=$?
    
    if [ $STATUS_CODE -eq 0 ]; then
        # Server is running - check for updates
        print_info "Server is running. Checking for updates..."
        
        SYSTEM_UPDATES=0
        NODE_UPDATES=0
        APP_UPDATES=0
        
        check_system_updates && SYSTEM_UPDATES=1
        check_nodejs_updates && NODE_UPDATES=1
        check_app_updates && APP_UPDATES=1
        
        if [ $SYSTEM_UPDATES -eq 1 ] || [ $NODE_UPDATES -eq 1 ] || [ $APP_UPDATES -eq 1 ]; then
            echo ""
            echo "Updates available:"
            [ $SYSTEM_UPDATES -eq 1 ] && echo "  - System packages"
            [ $NODE_UPDATES -eq 1 ] && echo "  - Node.js"
            [ $APP_UPDATES -eq 1 ] && echo "  - FreeSpeechApp"
            echo ""
            
            printf "Would you like to enter interactive menu? (y/N) "
            read -r answer
            
            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                while true; do
                    show_menu
                done
            fi
        else
            print_success "Everything is up to date!"
            
            printf "Enter interactive menu anyway? (y/N) "
            read -r answer
            
            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                while true; do
                    show_menu
                done
            fi
        fi
    elif [ $STATUS_CODE -eq 2 ]; then
        # Server not installed
        printf "Server is not installed. Deploy now? (y/N) "
        read -r answer
        
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            deploy_fresh
        else
            print_info "You can deploy later from the interactive menu"
            while true; do
                show_menu
            done
        fi
    else
        # Server installed but not running
        printf "Server is not running. Enter interactive menu? (y/N) "
        read -r answer
        
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            while true; do
                show_menu
            done
        fi
    fi
}

# Run main function
main
