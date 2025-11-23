# Local Development Guide

This guide covers setting up FreeSpeechApp for local development on your machine.

## Quick Local Setup

### Option 1: Automated Local Deployment

Use the admin deploy script with the `--local` flag:

```bash
./admin-deploy.sh --local
```

This will:
- Detect your OS (macOS or Linux)
- Install Node.js and dependencies (if needed)
- Clone the repository
- Generate SSL certificates
- Set up a background service
- Start the server

### Option 2: Platform-Specific Installers

**macOS:**
```bash
bash bootstrap/install-macos.sh
```

**Linux:**
```bash
sudo bash bootstrap/install.sh
```

### Option 3: Simple Manual Setup

For quick development without installation:

```bash
cd server
node server.js
```

Then open `client/index.html` in your browser.

## Local Configuration

When deploying locally, the script uses development-friendly defaults:

- **macOS:**
  - Install directory: `~/freespeechapp`
  - HTTP Port: 8080
  - HTTPS Port: 8443
  - Service: LaunchAgent (user-level)
  - No sudo required

- **Linux:**
  - Install directory: `/opt/freespeechapp`
  - HTTP Port: 80
  - HTTPS Port: 443
  - Service: systemd
  - Requires sudo

## Service Management

### macOS

```bash
# Check status
launchctl list | grep freespeechapp

# View logs
tail -f ~/Library/Logs/freespeechapp.log
tail -f ~/Library/Logs/freespeechapp.error.log

# Stop service
launchctl unload ~/Library/LaunchAgents/org.freespeechapp.plist

# Start service
launchctl load ~/Library/LaunchAgents/org.freespeechapp.plist

# Restart (stop and start)
launchctl unload ~/Library/LaunchAgents/org.freespeechapp.plist
launchctl load ~/Library/LaunchAgents/org.freespeechapp.plist
```

### Linux

```bash
# Check status
sudo systemctl status freespeechapp

# View logs
sudo journalctl -u freespeechapp -f

# Stop service
sudo systemctl stop freespeechapp

# Start service
sudo systemctl start freespeechapp

# Restart service
sudo systemctl restart freespeechapp
```

## Development Workflow

### 1. Make Code Changes

Edit files in your local repository:
- Server code: `server/server.js`
- Client code: `client/app.js`, `client/index.html`, `client/style.css`

### 2. Test Changes

**Without Service (Manual):**
```bash
cd server
node server.js
```

**With Service (Automatic):**
```bash
# macOS
launchctl unload ~/Library/LaunchAgents/org.freespeechapp.plist
launchctl load ~/Library/LaunchAgents/org.freespeechapp.plist

# Linux
sudo systemctl restart freespeechapp
```

### 3. Update Local Installation

To update your local installation after pulling changes:

```bash
./admin-deploy.sh --local
```

This will update the repository, dependencies, and restart the service.

## Environment Variables

You can customize the server behavior with environment variables:

```bash
# Set custom ports
export HTTP_PORT=3000
export HTTPS_PORT=3443

# Disable HTTPS (use HTTP only)
export USE_HTTPS=false

# Custom certificate path
export CERT_PATH=/path/to/certs

# Start server
node server.js
```

## Certificate Management

Self-signed certificates are automatically generated during installation.

**Location:**
- macOS: `~/freespeechapp/server/certs/`
- Linux: `/opt/freespeechapp/server/certs/`

**Regenerate certificates:**
```bash
cd bootstrap
./generate-certs.sh
```

## Accessing the Application

After starting the server:

- **HTTP:** `http://localhost:8080` (macOS) or `http://localhost:80` (Linux)
- **HTTPS:** `https://localhost:8443` (macOS) or `https://localhost:443` (Linux)

For the client, open:
- `client/index.html` directly in your browser, or
- Serve via the server at the root path `/`

## Troubleshooting

### Port Already in Use

If you get "port already in use" errors:

```bash
# Find process using the port
lsof -i :8443  # macOS/Linux
netstat -ano | findstr :8443  # Windows

# Kill the process
kill -9 <PID>
```

Or use different ports:
```bash
export HTTP_PORT=8000
export HTTPS_PORT=8001
node server.js
```

### Certificate Warnings

Browsers will show warnings for self-signed certificates. This is normal for development. Click "Advanced" → "Proceed to localhost" to continue.

### Service Won't Start (macOS)

Check the error log:
```bash
tail -f ~/Library/Logs/freespeechapp.error.log
```

Common issues:
- Node.js not in path: Make sure `/usr/local/bin/node` exists or update the plist
- Port permission: Use ports above 1024 (default 8080/8443)

### Service Won't Start (Linux)

Check the service status:
```bash
sudo systemctl status freespeechapp
sudo journalctl -u freespeechapp -n 50
```

Common issues:
- Permission denied on ports 80/443: Run with sudo or use ports above 1024
- Node.js not found: Ensure Node.js is installed and in PATH

## Uninstalling

### macOS

```bash
# Stop and remove service
launchctl unload ~/Library/LaunchAgents/org.freespeechapp.plist
rm ~/Library/LaunchAgents/org.freespeechapp.plist

# Remove installation
rm -rf ~/freespeechapp

# Remove logs
rm ~/Library/Logs/freespeechapp*.log
```

### Linux

```bash
# Use the uninstall script
cd bootstrap
sudo ./uninstall.sh
```

Or manually:
```bash
sudo systemctl stop freespeechapp
sudo systemctl disable freespeechapp
sudo rm /etc/systemd/system/freespeechapp.service
sudo systemctl daemon-reload
sudo rm -rf /opt/freespeechapp
```

## Next Steps

- See [MANUAL_SETUP.md](MANUAL_SETUP.md) for manual installation steps
- See [ADMIN_SCRIPT.md](ADMIN_SCRIPT.md) for remote deployment
- See [server/README.md](server/README.md) for server API documentation
- See [client/README.md](client/README.md) for client usage
