# FreeSpeechApp Admin Deployment Script

Simple shell script for managing remote FreeSpeechApp servers. Delegates all installation and update logic to the existing bootstrap scripts.

## Features

- ✅ Simple Unix shell (~100 lines)
- ✅ Configuration file with server credentials
- ✅ SSH key or password authentication
- ✅ Status checking
- ✅ One-command deployment
- ✅ Update checking and installation
- ✅ Service management
- ✅ Log viewing

## Quick Start

1. **Create config:**
   ```bash
   cp freespeech-admin.conf.sample freespeech-admin.conf
   nano freespeech-admin.conf
   ```

2. **Run:**
   ```bash
   ./admin-deploy.sh
   ```

## Configuration

Edit `freespeech-admin.conf`:

```bash
SERVER_HOST="your-server.com"
SERVER_USER="root"
SERVER_PORT="22"
SERVER_PASSWORD=""  # Leave empty for SSH key
SERVER_TYPE="nodejs"
STORAGE_LIMIT="10G"
RAM_LIMIT="1G"
APP_PORT="8443"
INSTALL_DIR="/opt/freespeechapp"
REPO_URL="https://github.com/denisps/freespeechapp.git"
```

## Menu Options

```
1) Check status       - Show service status and versions
2) Deploy/Install     - Run bootstrap install script
3) Update app         - Git pull and restart
4) Restart service    - Restart systemd service
5) View logs          - Show last 50 log lines
6) Check updates      - Check for new commits
0) Exit
```

## Authentication

**SSH Key (Recommended):**
```bash
ssh-copy-id user@server.com
# Leave SERVER_PASSWORD empty
```

**Password:**
```bash
# Install sshpass: apt install sshpass
# Set SERVER_PASSWORD="yourpassword"
```

## Examples

**Fresh Install:**
```bash
./admin-deploy.sh
# Choose option 2 to deploy
```

**Check and Update:**
```bash
./admin-deploy.sh
# Automatically checks for updates
# Prompts to update if available
```

**View Logs:**
```bash
./admin-deploy.sh
# Choose option 5
```

## Notes

- Script delegates to bootstrap/install.sh for actual installation
- Updates use git pull + systemctl restart
- All complex logic lives in bootstrap scripts
- PHP support placeholder (nodejs only for now)
