# FreeSpeechApp

Secure, decentralized communication platform for safe messaging over untrusted networks.

🌐 **Live Demo:** [https://freespeechapp.org/](https://freespeechapp.org/)

## Features

- ✅ **Encrypted HTTPS/TLS** communication
- ✅ **Zero dependencies** - pure Node.js server
- ✅ **HTTP polling** - Cloudflare compatible (no WebSockets)
- ✅ **One-command deployment** - automated setup scripts
- ✅ **Remote management** - admin script for easy updates
- ✅ **Self-signed certificates** - 100-year validity
- ✅ **Systemd integration** - production-ready service
- ✅ **Multi-platform** - Ubuntu, Debian, CentOS, RHEL, Fedora

## Quick Start

### Deploy Server (Remote)

From your local machine, deploy to a remote Linux server:

1. **Create config file:**
   ```bash
   cp freespeech-admin.conf.sample freespeech-admin.conf
   nano freespeech-admin.conf  # Add your server details
   ```

2. **Deploy:**
   ```bash
   ./admin-deploy.sh
   ```

The script will:
- Connect to your server via SSH
- Install Node.js and dependencies
- Clone the repository
- Generate SSL certificates
- Configure systemd service
- Open firewall ports
- Start the server

**Updates:** Run `./admin-deploy.sh` again to update system packages, repository, and restart the service.

### Local Development

Deploy locally for development. See [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) for full details.

```bash
./admin-deploy.sh --local
```

### Direct Server Installation

SSH into your Linux server and run:

```bash
curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | sudo bash
```

Platform-specific installers available for Ubuntu, Debian, CentOS, RHEL, Fedora, and macOS.

See [MANUAL_SETUP.md](MANUAL_SETUP.md) for manual installation instructions.

## Configuration

Edit `freespeech-admin.conf` to customize:

```bash
SERVER_HOST="your-server.com"
SERVER_USER="root"
SERVER_PORT="22"
HTTP_PORT="80"           # Default HTTP port
HTTPS_PORT="443"         # Default HTTPS port
STORAGE_LIMIT="10G"      # Storage limit (future use)
RAM_LIMIT="1G"           # RAM limit (future use)
INSTALL_DIR="/opt/freespeechapp"
REPO_URL="https://github.com/denisps/freespeechapp.git"
```

## Architecture

- **Server** (`/server`) - Node.js HTTPS server with HTTP polling, zero dependencies
- **Client** (`/client`) - Vanilla JavaScript web interface, responsive design
- **Bootstrap** (`/bootstrap`) - Automated deployment scripts for all platforms
- **Admin Script** (`admin-deploy.sh`) - Remote deployment and update tool

## Documentation

### Getting Started
- [Local Development Guide](LOCAL_DEVELOPMENT.md) - Set up for local development
- [Manual Setup Guide](MANUAL_SETUP.md) - Manual installation and configuration
- [Admin Deployment Guide](ADMIN_SCRIPT.md) - Remote server deployment

### Technical Documentation
- [Server Documentation](server/README.md) - Server API and configuration
- [Client Documentation](client/README.md) - Client usage and features
- [Bootstrap Scripts](bootstrap/README.md) - Deployment script details
- [Architecture Overview](ARCHITECTURE_OVERVIEW.md) - System architecture
- [Security Details](SECURITY.md) - Security features and best practices
- [Testing Guide](TESTING.md) - Test suite documentation and usage

## Requirements

**Server:**
- Linux (Ubuntu, Debian, CentOS, RHEL, Fedora)
- Node.js 18+ (auto-installed)
- OpenSSL (auto-installed)

**Client:**
- Modern web browser with Fetch API

**Admin Machine:**
- SSH client
- POSIX shell (bash, sh)

## License

See [LICENSE](LICENSE) file for details.
