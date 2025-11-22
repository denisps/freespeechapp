# FreeSpeechApp Architecture

## System Overview

FreeSpeechApp is a secure, decentralized communication platform built for safe messaging over untrusted networks.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         FreeSpeechApp                            │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐                                    ┌──────────────┐
│   Client A   │                                    │   Client B   │
│  (Browser)   │                                    │  (Browser)   │
│              │                                    │              │
│  index.html  │                                    │  index.html  │
│   app.js     │                                    │   app.js     │
│  style.css   │                                    │  style.css   │
└──────┬───────┘                                    └───────┬──────┘
       │                                                    │
       │ WSS (Secure WebSocket)                           │
       │ TLS/SSL Encrypted                                │
       │                                                    │
       └────────────────┬──────────────┬───────────────────┘
                        │              │
                        ▼              ▼
                 ┌──────────────────────────┐
                 │   FreeSpeechApp Server   │
                 │    (Node.js + HTTPS)     │
                 │                          │
                 │  ┌────────────────────┐  │
                 │  │  WebSocket Server  │  │
                 │  │   (ws library)     │  │
                 │  └────────────────────┘  │
                 │                          │
                 │  ┌────────────────────┐  │
                 │  │   HTTPS Server     │  │
                 │  │   (Node.js https)  │  │
                 │  └────────────────────┘  │
                 │                          │
                 │  ┌────────────────────┐  │
                 │  │  SSL Certificates  │  │
                 │  │  (server.crt/key)  │  │
                 │  └────────────────────┘  │
                 │                          │
                 │  Port: 8443             │
                 └──────────────────────────┘
                           ▲
                           │
                           │ Deployed by
                           │
                 ┌──────────────────────────┐
                 │   Bootstrap Scripts      │
                 │                          │
                 │  • install.sh            │
                 │  • install-ubuntu.sh     │
                 │  • install-centos.sh     │
                 │  • install-fedora.sh     │
                 │  • generate-certs.sh     │
                 │  • uninstall.sh          │
                 │                          │
                 │  Creates systemd service │
                 └──────────────────────────┘
```

## Component Details

### 1. Client (Browser-Based)

**Technology Stack:**
- HTML5
- Vanilla JavaScript (no framework dependencies)
- CSS3

**Features:**
- WebSocket client implementation
- Real-time message display
- Connection status monitoring
- Broadcast and direct messaging UI

**Files:**
- `client/index.html` - Main application UI
- `client/app.js` - WebSocket client logic
- `client/style.css` - Responsive styling

### 2. Server (Node.js Application)

**Technology Stack:**
- Node.js (v14+)
- Native HTTPS module
- ws library (WebSocket implementation)

**Components:**
- **HTTPS Server**: Handles TLS/SSL encryption
- **WebSocket Server**: Manages real-time connections
- **Client Manager**: Tracks connected clients
- **Message Router**: Routes broadcast and direct messages

**Files:**
- `server/server.js` - Main server application
- `server/package.json` - Dependencies and metadata

### 3. Bootstrap (Deployment Automation)

**Technology Stack:**
- Bash shell scripts
- systemd service configuration
- OpenSSL for certificate generation

**Functions:**
- Node.js installation
- Repository cloning
- Dependency installation
- SSL certificate generation
- Service creation and management
- Firewall configuration

**Files:**
- `bootstrap/install.sh` - Main installer (auto-detect distro)
- `bootstrap/install-ubuntu.sh` - Ubuntu/Debian specific
- `bootstrap/install-centos.sh` - CentOS/RHEL specific
- `bootstrap/install-fedora.sh` - Fedora specific
- `bootstrap/generate-certs.sh` - Certificate utility
- `bootstrap/uninstall.sh` - Removal script

## Communication Flow

### 1. Connection Establishment

```
Client                          Server
  │                              │
  ├─── WSS Connection Request ───▶
  │                              │
  │◀─── Upgrade to WebSocket ────┤
  │                              │
  │◀──── Welcome Message ─────────┤
  │      (with Client ID)         │
  │                              │
```

### 2. Broadcast Message

```
Client A                 Server                  Client B
  │                       │                        │
  ├─ Broadcast Message ──▶│                        │
  │                       ├─ Route to all ────────▶│
  │                       │                        │
```

### 3. Direct Message

```
Client A                 Server                  Client B
  │                       │                        │
  ├─ Direct Message ─────▶│                        │
  │   (to: Client B)      ├─ Route to Client B ──▶│
  │                       │                        │
```

## Message Format

### Client → Server

**Broadcast Message:**
```json
{
  "type": "broadcast",
  "content": "Message text"
}
```

**Direct Message:**
```json
{
  "type": "direct",
  "to": "client_1234567890_abc123",
  "from": "client_9876543210_xyz789",
  "content": "Private message"
}
```

**Ping:**
```json
{
  "type": "ping"
}
```

### Server → Client

**Welcome:**
```json
{
  "type": "welcome",
  "clientId": "client_1234567890_abc123",
  "timestamp": "2025-11-22T19:00:00.000Z"
}
```

**Message:**
```json
{
  "type": "message",
  "from": "client_1234567890_abc123",
  "content": "Message text",
  "timestamp": "2025-11-22T19:00:00.000Z"
}
```

**Pong:**
```json
{
  "type": "pong",
  "timestamp": "2025-11-22T19:00:00.000Z"
}
```

## Security Architecture

### Transport Layer
- **Protocol**: HTTPS/WSS
- **Encryption**: TLS 1.2+
- **Certificate**: RSA 4096-bit self-signed (default)
- **Port**: 8443 (configurable)

### Application Layer
- **Input Validation**: All messages validated
- **Error Handling**: Graceful error management
- **Connection Limits**: Managed by Node.js and ws library
- **Resource Management**: Automatic cleanup on disconnect

### Deployment Layer
- **Service Isolation**: systemd service
- **Process Management**: Graceful shutdown
- **Logging**: syslog integration
- **Monitoring**: Health check endpoint

## Scalability Considerations

### Current Implementation
- Single-process Node.js server
- In-memory client management
- Suitable for small to medium deployments (hundreds of concurrent connections)

### Scaling Options

**Vertical Scaling:**
- Increase server resources (CPU, RAM)
- Node.js can handle thousands of WebSocket connections on modern hardware

**Horizontal Scaling:**
- Deploy multiple server instances
- Use a load balancer (nginx, HAProxy)
- Implement Redis pub/sub for inter-server communication
- Use sticky sessions for client routing

**Database Integration:**
- Add message persistence (PostgreSQL, MongoDB)
- Implement user authentication
- Store chat history

## Deployment Topologies

### 1. Single Server (Default)
```
Internet → Firewall → FreeSpeechApp Server → Clients
```

### 2. Behind Reverse Proxy
```
Internet → Nginx/Apache → FreeSpeechApp Server → Clients
         (SSL termination)  (Port 8443)
```

### 3. Load Balanced
```
Internet → Load Balancer → FreeSpeechApp Server 1 → Clients
                         → FreeSpeechApp Server 2
                         → FreeSpeechApp Server 3
```

## Technology Choices

### Why Node.js?
- Excellent WebSocket support
- Event-driven architecture ideal for real-time apps
- Large ecosystem
- Easy deployment

### Why Self-Signed Certificates?
- Quick deployment without CA dependencies
- 100-year validity eliminates renewal concerns
- Suitable for internal/development use
- Can be replaced with CA certificates for production

### Why systemd?
- Standard on modern Linux distributions
- Automatic restart on failure
- Service dependencies
- Logging integration

### Why WebSockets?
- Full-duplex communication
- Low latency
- Native browser support
- Efficient for real-time messaging

## Future Enhancements

Potential improvements for the architecture:

1. **Authentication Layer**
   - User registration/login
   - JWT tokens
   - OAuth2 integration

2. **End-to-End Encryption**
   - Client-side encryption
   - Public key infrastructure
   - Perfect forward secrecy

3. **Message Persistence**
   - Database integration
   - Message history
   - Offline message delivery

4. **Advanced Features**
   - File sharing
   - Voice/video calls (WebRTC)
   - Group chats
   - Presence indicators

5. **Monitoring & Analytics**
   - Prometheus metrics
   - Grafana dashboards
   - Connection statistics

6. **Clustering**
   - Redis adapter for ws
   - Multi-server deployments
   - Session persistence

## Development Workflow

### Local Development
1. Clone repository
2. Install dependencies: `cd server && npm install`
3. Generate certificates: `cd bootstrap && ./generate-certs.sh`
4. Start server: `cd server && npm start`
5. Open client: `client/index.html` in browser

### Testing
- Manual testing with client UI
- WebSocket testing tools (wscat, Postman)
- Health endpoint monitoring

### Deployment
1. Run distribution-specific bootstrap script
2. Service starts automatically
3. Monitor with systemd tools
4. Access via WSS connection

## Maintenance

### Regular Tasks
- Monitor service status
- Review logs for errors
- Update Node.js and dependencies
- Backup certificate files
- Monitor disk and resource usage

### Troubleshooting
- Check service status: `systemctl status freespeechapp`
- View logs: `journalctl -u freespeechapp -f`
- Test health endpoint: `curl -k https://localhost:8443/health`
- Verify port listening: `netstat -tlnp | grep 8443`
