# FreeSpeechApp Admin Deployment Script

Simple Unix shell script for managing FreeSpeechApp server deployments from an admin machine.

## Features

- ✅ Simple Unix shell (POSIX compatible, no bash/zsh specific features)
- ✅ No special Linux dependencies
- ✅ Configuration file with server credentials
- ✅ Password or SSH key authentication
- ✅ Resource limits (storage and RAM)
- ✅ Server type selection (Node.js or PHP)
- ✅ Status checking
- ✅ Automatic update detection (Linux, Node.js, App)
- ✅ Interactive menu for management
- ✅ Remote deployment and updates

## Requirements

**Admin Machine:**
- Unix/Linux/macOS
- SSH client
- `sshpass` (optional, only if using password authentication)

**Remote Server:**
- SSH access (root or sudo user)
- Supported OS: Ubuntu, Debian, CentOS, RHEL, Fedora

## Quick Start

### 1. Create Configuration File

```bash
cp freespeech-admin.conf.sample freespeech-admin.conf
```

Edit `freespeech-admin.conf`:

```bash
# Server connection
SERVER_HOST="your-server.com"
SERVER_USER="root"
SERVER_PORT="22"
SERVER_PASSWORD=""  # Leave empty for SSH key auth

# Server type
SERVER_TYPE="nodejs"  # or "php" (not yet implemented)

# Resource limits
STORAGE_LIMIT="10G"
RAM_LIMIT="1G"

# App settings
APP_PORT="8443"
INSTALL_DIR="/opt/freespeechapp"
```

### 2. Run the Script

```bash
./admin-deploy.sh
```

Or specify a custom config file:

```bash
./admin-deploy.sh /path/to/custom-config.conf
```

## Authentication Methods

### SSH Key (Recommended)

1. Generate SSH key on admin machine:
   ```bash
   ssh-keygen -t rsa -b 4096
   ```

2. Copy to server:
   ```bash
   ssh-copy-id user@your-server.com
   ```

3. Leave `SERVER_PASSWORD` empty in config

### Password Authentication

1. Install `sshpass` on admin machine:
   ```bash
   # Ubuntu/Debian
   apt install sshpass
   
   # CentOS/RHEL
   yum install sshpass
   
   # macOS
   brew install hudochenkov/sshpass/sshpass
   ```

2. Set `SERVER_PASSWORD` in config file:
   ```bash
   SERVER_PASSWORD="your-password"
   ```

**Note:** SSH key authentication is more secure and recommended.

## Usage

### Automatic Mode

When you run the script, it will:

1. **Check connectivity** to the server
2. **Check server status**:
   - If running: Check for updates and offer to install
   - If not installed: Offer to deploy
   - If stopped: Offer interactive menu

### Interactive Menu

```
==========================================
  FreeSpeechApp Admin Control Panel
==========================================
Server: root@your-server.com:22
Type: nodejs
==========================================

1) Check status
2) Check for updates
3) Install system updates
4) Update Node.js
5) Update app
6) Deploy fresh installation
7) Check resource usage
8) Restart server
9) View logs
0) Exit

Enter choice [0-9]:
```

### Menu Options

**1. Check status** - Shows if server is running and current versions

**2. Check for updates** - Checks for available updates:
- Linux system packages
- Node.js version
- FreeSpeechApp commits

**3. Install system updates** - Updates Linux packages

**4. Update Node.js** - Upgrades Node.js to latest LTS

**5. Update app** - Pulls latest code and restarts service

**6. Deploy fresh installation** - Runs full installation from scratch

**7. Check resource usage** - Shows disk, memory, and app resource usage

**8. Restart server** - Restarts the FreeSpeechApp service

**9. View logs** - Shows last 50 lines of application logs

**0. Exit** - Quit the script

## Configuration Options

### Server Connection

| Option | Description | Default | Required |
|--------|-------------|---------|----------|
| `SERVER_HOST` | Server hostname or IP | - | Yes |
| `SERVER_USER` | SSH username | - | Yes |
| `SERVER_PORT` | SSH port | 22 | No |
| `SERVER_PASSWORD` | SSH password (optional) | - | No |

### Server Type

| Option | Description | Values | Default |
|--------|-------------|--------|---------|
| `SERVER_TYPE` | Application server type | `nodejs`, `php` | `nodejs` |

**Note:** PHP support will be implemented in a future update.

### Resource Limits

| Option | Description | Default |
|--------|-------------|---------|
| `STORAGE_LIMIT` | Disk space limit | `10G` |
| `RAM_LIMIT` | RAM limit for app | `1G` |

**Note:** These are informational for now. Future versions will enforce limits.

### Application Settings

| Option | Description | Default |
|--------|-------------|---------|
| `APP_PORT` | Application port | `8443` |
| `INSTALL_DIR` | Installation directory | `/opt/freespeechapp` |
| `REPO_URL` | Git repository URL | `https://github.com/denisps/freespeechapp.git` |

## Examples

### Example 1: First-time Deployment

```bash
# 1. Create config
cp freespeech-admin.conf.sample freespeech-admin.conf

# 2. Edit config
nano freespeech-admin.conf

# 3. Run script
./admin-deploy.sh

# Output:
# [INFO] Loading config from: ./freespeech-admin.conf
# [SUCCESS] Config loaded successfully
# [INFO] Checking connectivity to your-server.com...
# [SUCCESS] Connected to server
# [INFO] Checking server status...
# [WARNING] Server is not installed
# Server is not installed. Deploy now? (y/N) y
# [INFO] Deploying fresh installation...
# [SUCCESS] Fresh installation completed
```

### Example 2: Checking for Updates

```bash
./admin-deploy.sh

# Output:
# [SUCCESS] Connected to server
# [SUCCESS] Server is running
# [INFO] Checking for updates...
# [WARNING] 15 system packages can be updated
# [SUCCESS] Node.js is current (v18)
# [WARNING] App is 3 commits behind
#
# Updates available:
#   - System packages
#   - FreeSpeechApp
#
# Would you like to enter interactive menu? (y/N)
```

### Example 3: Using Custom Config

```bash
# Production server
./admin-deploy.sh /etc/freespeech/prod-server.conf

# Staging server
./admin-deploy.sh /etc/freespeech/staging-server.conf

# Local test server
./admin-deploy.sh ./local-test.conf
```

## Workflow Examples

### Daily Maintenance Check

```bash
#!/bin/sh
# daily-check.sh

./admin-deploy.sh prod-server.conf << EOF
2
0
EOF
```

This will:
1. Check for updates
2. Exit

You can schedule this with cron:

```bash
# Check daily at 6 AM
0 6 * * * /path/to/daily-check.sh
```

### Automated Update

```bash
#!/bin/sh
# auto-update.sh

./admin-deploy.sh prod-server.conf << EOF
2
5
0
EOF
```

This will:
1. Check for updates
2. Update the app
3. Exit

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to server

**Solutions:**
- Check `SERVER_HOST`, `SERVER_USER`, `SERVER_PORT`
- Verify SSH key is added to server: `ssh-copy-id user@host`
- Test manual SSH: `ssh -p 22 user@host`
- Check firewall allows SSH port

### Password Authentication Not Working

**Problem:** Password prompt appears or authentication fails

**Solutions:**
- Install `sshpass`: See authentication section above
- Use SSH key authentication instead (recommended)
- Verify password is correct in config file

### Permission Denied

**Problem:** Commands fail with permission denied

**Solutions:**
- Use `root` user or user with sudo access
- Verify user has permission to access `/opt/freespeechapp`
- Check if systemd service requires root

### Server Shows as Not Installed

**Problem:** Server shows as not installed but it is

**Solutions:**
- Check if installed in different directory (update `INSTALL_DIR`)
- Verify service name is `freespeechapp`
- Manually check: `ssh user@host systemctl status freespeechapp`

## Security Considerations

1. **SSH Keys:** Use SSH key authentication instead of passwords
2. **Config File:** Keep config file secure with proper permissions:
   ```bash
   chmod 600 freespeech-admin.conf
   ```
3. **Password in Config:** Avoid storing passwords in plain text
4. **Root Access:** Consider using a non-root user with sudo access
5. **Network:** Run from trusted networks only

## Future Enhancements

Planned features for future versions:

- [ ] PHP server support
- [ ] Enforce resource limits (storage/RAM)
- [ ] Multi-server management (one config, multiple servers)
- [ ] Backup and restore functionality
- [ ] SSL certificate renewal automation
- [ ] Email/Slack notifications for updates
- [ ] Dry-run mode (preview changes without applying)
- [ ] Rollback capability
- [ ] Health check monitoring
- [ ] Performance metrics collection

## Notes

### Server Types

**Node.js (Current)**
- Fully supported
- Zero dependencies
- HTTP polling architecture
- Cloudflare compatible

**PHP (Future)**
- Not yet implemented
- Will be added in future update
- Config ready for when implemented

### POSIX Compatibility

This script is written in POSIX-compliant shell script:
- Uses `/bin/sh` (not bash-specific)
- No bashisms (arrays, etc.)
- Works on any Unix-like system
- Minimal dependencies

### Testing

Test the script safely:

```bash
# Use a test server first
cp freespeech-admin.conf.sample test-server.conf
# Edit with test server details
./admin-deploy.sh test-server.conf
```

## License

Same as FreeSpeechApp main project.
