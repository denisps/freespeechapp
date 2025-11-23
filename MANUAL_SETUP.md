# Manual Setup Guide

This guide covers manual installation and configuration of FreeSpeechApp without using automated scripts.

## Prerequisites

Before starting, ensure you have:

- **Node.js 18+** installed
- **Git** installed
- **OpenSSL** installed
- **Root/sudo access** (for Linux) or **Homebrew** (for macOS)

## Manual Installation Steps

### 1. Install Dependencies

#### Ubuntu/Debian

```bash
# Update package list
sudo apt-get update

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt-get install -y nodejs

# Install other dependencies
sudo apt-get install -y git openssl ca-certificates
```

#### CentOS/RHEL

```bash
# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install other dependencies
sudo yum install -y git openssl ca-certificates
```

#### Fedora

```bash
# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# Install other dependencies
sudo dnf install -y git openssl ca-certificates
```

#### macOS

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js and dependencies
brew install node git openssl
```

### 2. Clone Repository

```bash
# Choose installation directory
INSTALL_DIR="/opt/freespeechapp"  # Linux
# or
INSTALL_DIR="$HOME/freespeechapp"  # macOS

# Clone the repository
sudo git clone https://github.com/denisps/freespeechapp.git $INSTALL_DIR
cd $INSTALL_DIR
```

### 3. Install Server Dependencies

```bash
cd $INSTALL_DIR/server
npm install --production
```

### 4. Generate SSL Certificates

```bash
cd $INSTALL_DIR/server
mkdir -p certs

# Generate self-signed certificate (valid for 100 years)
openssl req -x509 -nodes -days 36500 -newkey rsa:4096 \
    -keyout certs/server.key \
    -out certs/server.crt \
    -subj "/C=US/ST=State/L=City/O=FreeSpeechApp/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# Set permissions
chmod 600 certs/server.key
chmod 644 certs/server.crt
```

### 5. Configure Environment (Optional)

Create a `.env` file or set environment variables:

```bash
# Port configuration
export HTTP_PORT=80
export HTTPS_PORT=443

# Certificate path (default: ./certs)
export CERT_PATH=/opt/freespeechapp/server/certs

# Storage and memory limits
export STORAGE_LIMIT=10G
export RAM_LIMIT=1G

# Production mode
export NODE_ENV=production

# Disable HTTPS (use HTTP only)
export USE_HTTPS=false  # Optional
```

### 6. Test the Server

```bash
cd $INSTALL_DIR/server
node server.js
```

The server should start and display:
```
FreeSpeechApp server listening on port 443
Protocol: https
Health check: https://localhost:443/health
```

Test the health endpoint:
```bash
curl -k https://localhost:443/health
```

### 7. Set Up System Service

#### Linux (systemd)

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/freespeechapp.service
```

Add the following content:

```ini
[Unit]
Description=FreeSpeechApp Secure Communication Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/freespeechapp/server
Environment=NODE_ENV=production
Environment=HTTP_PORT=80
Environment=HTTPS_PORT=443
Environment=STORAGE_LIMIT=10G
Environment=RAM_LIMIT=1G
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=freespeechapp

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable freespeechapp
sudo systemctl start freespeechapp
sudo systemctl status freespeechapp
```

#### macOS (LaunchAgent)

Create a LaunchAgent plist:

```bash
nano ~/Library/LaunchAgents/org.freespeechapp.plist
```

Add the following content (adjust paths as needed):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.freespeechapp</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/node</string>
        <string>/Users/YOUR_USERNAME/freespeechapp/server/server.js</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/YOUR_USERNAME/freespeechapp/server</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>NODE_ENV</key>
        <string>production</string>
        <key>HTTP_PORT</key>
        <string>8080</string>
        <key>HTTPS_PORT</key>
        <string>8443</string>
        <key>STORAGE_LIMIT</key>
        <string>10G</string>
        <key>RAM_LIMIT</key>
        <string>1G</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/Library/Logs/freespeechapp.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/Library/Logs/freespeechapp.error.log</string>
</dict>
</plist>
```

Load the service:

```bash
launchctl load ~/Library/LaunchAgents/org.freespeechapp.plist
```

### 8. Configure Firewall

#### Ubuntu/Debian (UFW)

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

#### CentOS/RHEL/Fedora (firewalld)

```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

#### macOS

macOS firewall typically allows outbound connections. For incoming:

```bash
# Open System Preferences → Security & Privacy → Firewall
# Add Node.js to allowed applications
```

## Service Management

### Linux (systemd)

```bash
# Check status
sudo systemctl status freespeechapp

# Start service
sudo systemctl start freespeechapp

# Stop service
sudo systemctl stop freespeechapp

# Restart service
sudo systemctl restart freespeechapp

# Enable on boot
sudo systemctl enable freespeechapp

# Disable on boot
sudo systemctl disable freespeechapp

# View logs
sudo journalctl -u freespeechapp -f
sudo journalctl -u freespeechapp -n 100 --no-pager
```

### macOS (LaunchAgent)

```bash
# Check if running
launchctl list | grep freespeechapp

# Load (start) service
launchctl load ~/Library/LaunchAgents/org.freespeechapp.plist

# Unload (stop) service
launchctl unload ~/Library/LaunchAgents/org.freespeechapp.plist

# View logs
tail -f ~/Library/Logs/freespeechapp.log
tail -f ~/Library/Logs/freespeechapp.error.log
```

## Updating the Application

### Update Repository

```bash
cd $INSTALL_DIR
sudo git pull
```

### Update Dependencies

```bash
cd $INSTALL_DIR/server
npm install --production
```

### Restart Service

**Linux:**
```bash
sudo systemctl restart freespeechapp
```

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/org.freespeechapp.plist
launchctl load ~/Library/LaunchAgents/org.freespeechapp.plist
```

## Uninstallation

### Linux

```bash
# Stop and disable service
sudo systemctl stop freespeechapp
sudo systemctl disable freespeechapp

# Remove service file
sudo rm /etc/systemd/system/freespeechapp.service
sudo systemctl daemon-reload

# Remove application
sudo rm -rf /opt/freespeechapp

# Remove firewall rules (optional)
sudo ufw delete allow 80/tcp
sudo ufw delete allow 443/tcp
```

### macOS

```bash
# Unload service
launchctl unload ~/Library/LaunchAgents/org.freespeechapp.plist

# Remove plist
rm ~/Library/LaunchAgents/org.freespeechapp.plist

# Remove application
rm -rf ~/freespeechapp

# Remove logs
rm ~/Library/Logs/freespeechapp*.log
```

## Troubleshooting

### Permission Denied on Ports 80/443 (Linux)

Ports below 1024 require root privileges. Either:

1. Run as root (already configured in systemd service)
2. Use alternative ports:
   ```bash
   export HTTP_PORT=8080
   export HTTPS_PORT=8443
   ```

### Node Command Not Found

Make sure Node.js is in your PATH:

```bash
which node
# Should return: /usr/bin/node or /usr/local/bin/node

# Add to PATH if needed
export PATH=$PATH:/usr/local/bin
```

### Certificate Errors

Regenerate certificates:

```bash
cd $INSTALL_DIR/server/certs
rm server.key server.crt

openssl req -x509 -nodes -days 36500 -newkey rsa:4096 \
    -keyout server.key \
    -out server.crt \
    -subj "/C=US/ST=State/L=City/O=FreeSpeechApp/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

chmod 600 server.key
chmod 644 server.crt
```

### Service Won't Start

Check logs for errors:

**Linux:**
```bash
sudo journalctl -u freespeechapp -n 50
```

**macOS:**
```bash
tail -50 ~/Library/Logs/freespeechapp.error.log
```

Common issues:
- Port already in use
- Certificate file not found
- Node.js not installed or not in PATH
- Incorrect file permissions

## Next Steps

- See [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) for development workflow
- See [ADMIN_SCRIPT.md](ADMIN_SCRIPT.md) for automated remote deployment
- See [server/README.md](server/README.md) for server API documentation
- See [SECURITY.md](SECURITY.md) for security best practices
