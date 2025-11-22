# FreeSpeechApp Server

Secure HTTP server for safe communication over untrusted internet. Uses HTTP polling instead of WebSockets for Cloudflare compatibility.

## Features

- HTTPS secure communication (or HTTP if certificates not available)
- HTTP polling for real-time messaging (Cloudflare compatible)
- Broadcast and direct messaging support
- Zero external dependencies (uses only Node.js built-in modules)
- In-memory message queue with automatic cleanup
- Health check endpoint
- CORS enabled for cross-origin requests
- Graceful shutdown handling

## Prerequisites

- Node.js (v14 or higher)
- SSL certificates (optional - will fall back to HTTP)

## Installation

No dependencies to install! The server uses only Node.js built-in modules.

## Running the Server

```bash
node server.js
```

The server will start on port 8443 by default (HTTPS if certificates available, HTTP otherwise).

## Environment Variables

- `PORT`: Server port (default: 8443)
- `USE_HTTPS`: Enable/disable HTTPS (default: true, falls back to HTTP if certs missing)
- `CERT_PATH`: Path to SSL certificates directory (default: ./certs)

## API Endpoints

### Health Check
**GET** `/health`

Returns server status and statistics.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-22T19:00:00.000Z",
  "clients": 5,
  "messages": 23
}
```

### Connect
**POST** `/connect`

Register a new client and get a client ID.

**Response:**
```json
{
  "clientId": "client_1234567890_abc123",
  "timestamp": "2025-11-22T19:00:00.000Z"
}
```

### Send Message
**POST** `/send`

Send a broadcast or direct message.

**Request Body:**
```json
{
  "clientId": "client_1234567890_abc123",
  "content": "Your message here",
  "to": "client_0987654321_xyz789"  // Optional - omit for broadcast
}
```

**Response:**
```json
{
  "status": "sent",
  "messageId": "msg_1234567890_abc123",
  "timestamp": "2025-11-22T19:00:00.000Z"
}
```

### Poll Messages
**GET** `/poll?clientId=client_1234567890_abc123`

Get new messages since last poll.

**Response:**
```json
{
  "messages": [
    {
      "id": "msg_1234567890_abc123",
      "from": "client_0987654321_xyz789",
      "content": "Hello!",
      "timestamp": "2025-11-22T19:00:00.000Z",
      "type": "broadcast"
    }
  ],
  "timestamp": "2025-11-22T19:00:05.000Z"
}
```

### Disconnect
**POST** `/disconnect`

Disconnect a client.

**Request Body:**
```json
{
  "clientId": "client_1234567890_abc123"
}
```

**Response:**
```json
{
  "status": "disconnected"
}
```

## Message Retention

- Messages are kept in memory for 30 seconds
- Inactive clients are removed after 60 seconds
- Maximum 100 messages retained at any time
- Automatic cleanup runs every 10 seconds

## Cloudflare Compatibility

This server is designed to work with Cloudflare's free plan:

- ✅ Uses HTTP/HTTPS (not WebSockets)
- ✅ No long-lived connections
- ✅ Works with Cloudflare proxy
- ✅ Standard REST API
- ✅ CORS enabled

## Testing

Test the server with curl:

```bash
# Health check
curl https://localhost:8443/health

# Connect
curl -X POST https://localhost:8443/connect

# Send message (replace CLIENT_ID with actual ID)
curl -X POST https://localhost:8443/send \
  -H "Content-Type: application/json" \
  -d '{"clientId":"CLIENT_ID","content":"Hello World"}'

# Poll for messages
curl "https://localhost:8443/poll?clientId=CLIENT_ID"
```

## Security

- TLS/SSL encryption when certificates available
- CORS enabled (configure as needed)
- Request body size limited to 1MB
- Automatic cleanup of old data
- No persistent storage (memory only)
