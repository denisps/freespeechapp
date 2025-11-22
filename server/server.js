const https = require('https');
const fs = require('fs');
const path = require('path');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8443;
const CERT_PATH = process.env.CERT_PATH || path.join(__dirname, 'certs');

// Load SSL certificates
let httpsOptions;
try {
  httpsOptions = {
    cert: fs.readFileSync(path.join(CERT_PATH, 'server.crt')),
    key: fs.readFileSync(path.join(CERT_PATH, 'server.key'))
  };
} catch (err) {
  console.error('Error loading SSL certificates:', err.message);
  console.error('Please ensure certificates exist at:', CERT_PATH);
  process.exit(1);
}

// Create HTTPS server
const server = https.createServer(httpsOptions, (req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', timestamp: new Date().toISOString() }));
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

// Create WebSocket server
const wss = new WebSocket.Server({ server });

// Store connected clients with their IDs
const clients = new Map();

wss.on('connection', (ws, req) => {
  const clientId = generateClientId();
  clients.set(clientId, ws);
  
  console.log(`Client connected: ${clientId} from ${req.socket.remoteAddress}`);
  
  // Send welcome message with client ID
  ws.send(JSON.stringify({
    type: 'welcome',
    clientId: clientId,
    timestamp: new Date().toISOString()
  }));
  
  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data);
      
      // Handle different message types
      switch (message.type) {
        case 'broadcast':
          // Broadcast to all clients except sender
          broadcastMessage(clientId, message);
          break;
        case 'direct':
          // Send direct message to specific client
          sendDirectMessage(message.to, message);
          break;
        case 'ping':
          // Respond to ping
          ws.send(JSON.stringify({ type: 'pong', timestamp: new Date().toISOString() }));
          break;
        default:
          console.log(`Unknown message type: ${message.type}`);
      }
    } catch (err) {
      console.error('Error processing message:', err.message);
    }
  });
  
  ws.on('close', () => {
    clients.delete(clientId);
    console.log(`Client disconnected: ${clientId}`);
  });
  
  ws.on('error', (err) => {
    console.error(`WebSocket error for client ${clientId}:`, err.message);
  });
});

function generateClientId() {
  return `client_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

function broadcastMessage(senderId, message) {
  const broadcastData = JSON.stringify({
    type: 'message',
    from: senderId,
    content: message.content,
    timestamp: new Date().toISOString()
  });
  
  clients.forEach((client, clientId) => {
    if (clientId !== senderId && client.readyState === WebSocket.OPEN) {
      client.send(broadcastData);
    }
  });
}

function sendDirectMessage(recipientId, message) {
  const recipient = clients.get(recipientId);
  if (recipient && recipient.readyState === WebSocket.OPEN) {
    recipient.send(JSON.stringify({
      type: 'message',
      from: message.from,
      content: message.content,
      timestamp: new Date().toISOString()
    }));
  }
}

server.listen(PORT, () => {
  console.log(`FreeSpeechApp server listening on port ${PORT}`);
  console.log(`WebSocket endpoint: wss://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, closing server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
