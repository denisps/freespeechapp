# FreeSpeechApp

WebApp for safe communication over untrusted internet. It is a cornerstone for decentralized web3 apps.

## Overview

FreeSpeechApp is a secure, decentralized communication platform designed for safe messaging over untrusted networks. It uses WebSocket Secure (WSS) protocol over HTTPS to ensure encrypted communication.

## Architecture

The application consists of four main components:

### 1. Server (`/server`)
- Node.js application with HTTP polling (no WebSockets)
- HTTPS secure communication
- Zero external dependencies
- Broadcast and direct messaging capabilities
- Health monitoring endpoint
- Cloudflare compatible
- See [server/README.md](server/README.md) for details

### 2. Client (`/client`)
- Modern web-based interface
- HTTP polling for real-time communication
- Connection status monitoring
- Support for broadcast and direct messages
- Responsive design
- Zero external dependencies
- See [client/README.md](client/README.md) for details

### 3. Bootstrap Scripts (`/bootstrap`)
- Automated server deployment
- Support for Ubuntu, Debian, CentOS, RHEL, Fedora
- Automatic Node.js installation
- Self-signed certificate generation (100-year validity)
- Systemd service configuration
- Firewall setup
- See [bootstrap/README.md](bootstrap/README.md) for details

### 4. Admin Deployment Script (`admin-deploy.sh`)
- Remote server management from admin machine
- Configuration file with server credentials
- Status checking and update detection
- Interactive menu for common tasks
- Simple Unix shell (POSIX compatible)
- See [ADMIN_SCRIPT.md](ADMIN_SCRIPT.md) for details

## Quick Start

### Server Deployment

Deploy on any supported Linux distribution with a single command:

**Ubuntu/Debian:**
```bash
curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-ubuntu.sh | sudo bash
```

**CentOS/RHEL:**
```bash
curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-centos.sh | sudo bash
```

**Fedora:**
```bash
curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-fedora.sh | sudo bash
```

### Admin Deployment (Remote Management)

Manage remote servers from your admin machine:

1. **Create configuration:**
   ```bash
   cp freespeech-admin.conf.sample freespeech-admin.conf
   nano freespeech-admin.conf  # Edit with your server details
   ```

2. **Run admin script:**
   ```bash
   ./admin-deploy.sh
   ```

The script will check server status, detect updates, and provide an interactive menu for management.

See [ADMIN_SCRIPT.md](ADMIN_SCRIPT.md) for detailed documentation.

### Manual Setup

1. **No dependencies to install!**
   ```bash
   cd server
   # No npm install needed - zero dependencies!
   ```

2. **Generate certificates:**
   ```bash
   cd bootstrap
   ./generate-certs.sh
   ```

3. **Start server:**
   ```bash
   cd server
   node server.js
   ```

4. **Open client:**
   Open `client/index.html` in a web browser and connect to `https://localhost:8443`

## Features

- ✅ Encrypted communication (HTTPS/TLS)
- ✅ Real-time messaging via HTTP polling
- ✅ Zero external dependencies
- ✅ Cloudflare compatible (free plan)
- ✅ Broadcast and direct messaging
- ✅ Self-signed certificates (100-year validity)
- ✅ Automatic server deployment scripts
- ✅ Remote admin management script
- ✅ Systemd service integration
- ✅ Multi-distribution support
- ✅ Modern, responsive web interface
- ✅ Connection health monitoring

## Security

- All communication is encrypted using TLS/SSL
- Self-signed certificates valid for 100 years (non-expiring for practical purposes)
- Secure WebSocket (WSS) protocol
- Can be deployed with custom certificates from trusted CAs

## Use Cases

- Decentralized Web3 applications
- Private team communication
- Secure messaging over untrusted networks
- Real-time collaboration tools
- Emergency communication systems

## Documentation

- [Server Documentation](server/README.md)
- [Client Documentation](client/README.md)
- [Bootstrap Scripts Guide](bootstrap/README.md)
- [Admin Deployment Script](ADMIN_SCRIPT.md)
- [Architecture Overview](ARCHITECTURE_OVERVIEW.md)
- [Review Guide](REVIEW_GUIDE.md)
- [Security Summary](SECURITY.md)

## Requirements

### Server
- Linux (Ubuntu, Debian, CentOS, RHEL, Fedora)
- Node.js 14+ (automatically installed by bootstrap)
- OpenSSL (for certificate generation)

### Client
- Modern web browser with Fetch API support
- JavaScript enabled

### Admin Machine (for remote management)
- Unix/Linux/macOS
- SSH client
- `sshpass` (optional, for password authentication)

## Service Management

After installation, manage the service with systemd:

```bash
# Check status
sudo systemctl status freespeechapp

# Start/Stop/Restart
sudo systemctl start freespeechapp
sudo systemctl stop freespeechapp
sudo systemctl restart freespeechapp

# View logs
sudo journalctl -u freespeechapp -f
```

## Configuration

### Server Port
Default: 8443 (configurable via `PORT` environment variable)

### Certificate Path
Default: `server/certs/` (configurable via `CERT_PATH` environment variable)

## Development

### Running in Development Mode

```bash
cd server
npm run dev
```

### Project Structure

```
freespeechapp/
├── server/              # Node.js server application
│   ├── server.js        # Main server code
│   ├── package.json     # Dependencies
│   └── README.md        # Server documentation
├── client/              # Web client application
│   ├── index.html       # Main HTML file
│   ├── app.js           # Client JavaScript
│   ├── style.css        # Styling
│   └── README.md        # Client documentation
└── bootstrap/           # Deployment scripts
    ├── install.sh       # Main installer
    ├── install-ubuntu.sh
    ├── install-centos.sh
    ├── install-fedora.sh
    ├── generate-certs.sh
    ├── uninstall.sh
    └── README.md        # Bootstrap documentation
```

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## Support

For issues, questions, or contributions, please use the GitHub issue tracker.
