# FreeSpeechApp

WebApp for safe communication over untrusted internet. It is a cornerstone for decentralized web3 apps.

## Overview

FreeSpeechApp is a secure, decentralized communication platform designed for safe messaging over untrusted networks. It uses WebSocket Secure (WSS) protocol over HTTPS to ensure encrypted communication.

## Architecture

The application consists of three main components:

### 1. Server (`/server`)
- Node.js application with WebSocket support
- HTTPS/WSS secure communication
- Broadcast and direct messaging capabilities
- Health monitoring endpoint
- See [server/README.md](server/README.md) for details

### 2. Client (`/client`)
- Modern web-based interface
- Real-time communication
- Connection status monitoring
- Support for broadcast and direct messages
- Responsive design
- See [client/README.md](client/README.md) for details

### 3. Bootstrap Scripts (`/bootstrap`)
- Automated server deployment
- Support for Ubuntu, Debian, CentOS, RHEL, Fedora
- Automatic Node.js installation
- Self-signed certificate generation (100-year validity)
- Systemd service configuration
- Firewall setup
- See [bootstrap/README.md](bootstrap/README.md) for details

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

### Manual Setup

1. **Install dependencies:**
   ```bash
   cd server
   npm install
   ```

2. **Generate certificates:**
   ```bash
   cd bootstrap
   ./generate-certs.sh
   ```

3. **Start server:**
   ```bash
   cd server
   npm start
   ```

4. **Open client:**
   Open `client/index.html` in a web browser and connect to `wss://localhost:8443`

## Features

- ✅ End-to-end encrypted communication (WSS/HTTPS)
- ✅ Real-time messaging via WebSockets
- ✅ Broadcast and direct messaging
- ✅ Self-signed certificates (100-year validity)
- ✅ Automatic server deployment scripts
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

## Requirements

### Server
- Linux (Ubuntu, Debian, CentOS, RHEL, Fedora)
- Node.js 14+ (automatically installed by bootstrap)
- OpenSSL (for certificate generation)

### Client
- Modern web browser with WebSocket support
- JavaScript enabled

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
