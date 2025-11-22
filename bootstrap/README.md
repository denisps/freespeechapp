# FreeSpeechApp Bootstrap Scripts

Server bootstrap scripts for quickly deploying FreeSpeechApp on various Linux distributions.

## Supported Distributions

- Ubuntu (all versions)
- Debian (all versions)
- CentOS (7, 8, Stream)
- RHEL (7, 8, 9)
- Fedora (all versions)

## What the Scripts Do

The bootstrap scripts automate the entire server setup process:

1. **Install Node.js** - Installs the latest LTS version (Node.js 18)
2. **Clone Repository** - Downloads the FreeSpeechApp code from GitHub
3. **Install Dependencies** - Installs required Node.js packages
4. **Generate SSL Certificates** - Creates a self-signed certificate valid for 100 years (non-expiring)
5. **Create systemd Service** - Sets up FreeSpeechApp as a system service
6. **Configure Firewall** - Opens port 8443 for HTTPS/WSS connections
7. **Start Service** - Starts the server automatically

## Quick Start

### Ubuntu/Debian

```bash
curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-ubuntu.sh | sudo bash
```

Or download and run:

```bash
wget https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-ubuntu.sh
chmod +x install-ubuntu.sh
sudo ./install-ubuntu.sh
```

### CentOS/RHEL

```bash
curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-centos.sh | sudo bash
```

Or download and run:

```bash
wget https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-centos.sh
chmod +x install-centos.sh
sudo ./install-centos.sh
```

### Fedora

```bash
curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-fedora.sh | sudo bash
```

Or download and run:

```bash
wget https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install-fedora.sh
chmod +x install-fedora.sh
sudo ./install-fedora.sh
```

### Generic Installation (Auto-detect)

```bash
curl -fsSL https://raw.githubusercontent.com/denisps/freespeechapp/main/bootstrap/install.sh | sudo bash
```

## Manual Installation

If you prefer to run the scripts manually:

1. Clone the repository:
   ```bash
   git clone https://github.com/denisps/freespeechapp.git
   cd freespeechapp/bootstrap
   ```

2. Make scripts executable:
   ```bash
   chmod +x *.sh
   ```

3. Run the appropriate script for your distribution:
   ```bash
   sudo ./install-ubuntu.sh    # For Ubuntu/Debian
   sudo ./install-centos.sh    # For CentOS/RHEL
   sudo ./install-fedora.sh    # For Fedora
   sudo ./install.sh           # Generic (auto-detect)
   ```

## Post-Installation

After installation, the server will be running as a systemd service.

### Service Management

```bash
# Check service status
sudo systemctl status freespeechapp

# Start service
sudo systemctl start freespeechapp

# Stop service
sudo systemctl stop freespeechapp

# Restart service
sudo systemctl restart freespeechapp

# View logs
sudo journalctl -u freespeechapp -f
```

### Server Access

- Server URL: `wss://your-server-ip:8443`
- Health check: `https://your-server-ip:8443/health`
- Certificate location: `/opt/freespeechapp/server/certs/`

### Connecting Clients

1. Open the client application (`client/index.html`)
2. Enter the server URL: `wss://your-server-ip:8443`
3. Click "Connect"

Note: You may need to accept the self-signed certificate in your browser first by visiting `https://your-server-ip:8443/health`

## SSL Certificates

### About the Certificates

The installation script automatically generates a self-signed SSL certificate valid for **100 years** (36,500 days), making it practically non-expiring.

### Certificate Details

- **Location**: `/opt/freespeechapp/server/certs/`
- **Files**: `server.crt` (certificate), `server.key` (private key)
- **Validity**: 100 years from generation date
- **Type**: RSA 4096-bit

### Regenerating Certificates

If you need to regenerate the certificates (e.g., to change the hostname):

```bash
sudo /opt/freespeechapp/bootstrap/generate-certs.sh
```

Or regenerate with a custom installation path:

```bash
sudo /path/to/generate-certs.sh /custom/install/path
```

The script will:
- Backup existing certificates
- Generate new certificates
- Restart the service automatically

### Using Custom Certificates

To use your own certificates (e.g., from Let's Encrypt):

1. Copy your certificate and key to `/opt/freespeechapp/server/certs/`
2. Ensure they are named `server.crt` and `server.key`
3. Set proper permissions:
   ```bash
   sudo chmod 600 /opt/freespeechapp/server/certs/server.key
   sudo chmod 644 /opt/freespeechapp/server/certs/server.crt
   ```
4. Restart the service:
   ```bash
   sudo systemctl restart freespeechapp
   ```

## Uninstallation

To completely remove FreeSpeechApp:

```bash
sudo /opt/freespeechapp/bootstrap/uninstall.sh
```

This will:
- Stop and disable the service
- Remove the service file
- Delete the installation directory

## Configuration

### Changing the Port

Edit the service file:

```bash
sudo systemctl edit freespeechapp
```

Add:

```ini
[Service]
Environment=PORT=8443
```

Then restart:

```bash
sudo systemctl restart freespeechapp
```

### Custom Certificate Path

Edit the service file to add:

```ini
[Service]
Environment=CERT_PATH=/path/to/certs
```

## Troubleshooting

### Service won't start

Check logs:
```bash
sudo journalctl -u freespeechapp -n 50
```

Common issues:
- Certificates missing or invalid
- Port already in use
- Node.js not installed properly

### Cannot connect from client

1. Check if service is running:
   ```bash
   sudo systemctl status freespeechapp
   ```

2. Check firewall:
   ```bash
   sudo ufw status                    # Ubuntu/Debian
   sudo firewall-cmd --list-all       # CentOS/RHEL/Fedora
   ```

3. Verify port is listening:
   ```bash
   sudo netstat -tlnp | grep 8443
   ```

### Certificate errors

Regenerate certificates:
```bash
sudo /opt/freespeechapp/bootstrap/generate-certs.sh
```

## Security Considerations

- The self-signed certificate will show a warning in browsers. For production, consider using Let's Encrypt or another CA.
- The server runs as root by default. Consider creating a dedicated user for better security.
- Configure your firewall to only allow connections from trusted IPs if needed.
- Regularly update Node.js and dependencies for security patches.

## Script Files

- `install.sh` - Main installation script (distribution-agnostic)
- `install-ubuntu.sh` - Ubuntu/Debian specific bootstrap
- `install-centos.sh` - CentOS/RHEL specific bootstrap
- `install-fedora.sh` - Fedora specific bootstrap
- `generate-certs.sh` - Certificate generation utility
- `uninstall.sh` - Uninstallation script
