const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const HTTP_PORT = process.env.HTTP_PORT || 80;
const HTTPS_PORT = process.env.HTTPS_PORT || 443;
const USE_HTTPS = process.env.USE_HTTPS !== 'false';
const CERT_PATH = process.env.CERT_PATH || path.join(__dirname, 'certs');
const MESSAGE_RETENTION_TIME = 30000; // 30 seconds
const MAX_MESSAGES = 100;
const API_ENABLED = process.env.API_ENABLED === 'true'; // API disabled by default

// In-memory storage
const messages = [];
const clients = new Map();

// Load SSL certificates if using HTTPS
let serverOptions = {};
if (USE_HTTPS) {
  try {
    serverOptions = {
      cert: fs.readFileSync(path.join(CERT_PATH, 'server.crt')),
      key: fs.readFileSync(path.join(CERT_PATH, 'server.key'))
    };
  } catch (err) {
    console.error('Error loading SSL certificates:', err.message);
    console.error('Falling back to HTTP mode');
    process.env.USE_HTTPS = 'false';
  }
}

// Helper to parse JSON body
function parseBody(req, callback) {
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
    // Limit body size to 1MB
    if (body.length > 1e6) {
      req.connection.destroy();
    }
  });
  req.on('end', () => {
    try {
      const data = body ? JSON.parse(body) : {};
      callback(null, data);
    } catch (err) {
      callback(err);
    }
  });
}

// Helper to send JSON response
function sendJSON(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end(JSON.stringify(data));
}

// Clean old messages
function cleanOldMessages() {
  const now = Date.now();
  const cutoff = now - MESSAGE_RETENTION_TIME;
  
  for (let i = messages.length - 1; i >= 0; i--) {
    if (messages[i].timestamp < cutoff) {
      messages.splice(i, 1);
    }
  }
  
  // Also clean old clients
  clients.forEach((client, id) => {
    if (now - client.lastSeen > MESSAGE_RETENTION_TIME * 2) {
      clients.delete(id);
    }
  });
}

// Run cleanup every 10 seconds
setInterval(cleanOldMessages, 10000);

// Serve home page
function serveHomePage(res) {
  const homePath = path.join(__dirname, 'public', 'index.html');
  
  fs.readFile(homePath, 'utf8', (err, content) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Home page not found');
      return;
    }
    
    res.writeHead(200, { 
      'Content-Type': 'text/html',
      'Cache-Control': 'public, max-age=300'
    });
    res.end(content);
  });
}

// Request handler
function handleRequest(req, res) {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    sendJSON(res, 200, { status: 'ok' });
    return;
  }
  
  // Serve home page
  if (pathname === '/' && req.method === 'GET') {
    serveHomePage(res);
    return;
  }
  
  // Check if API is enabled
  if (!API_ENABLED && pathname !== '/health') {
    sendJSON(res, 503, { 
      error: 'API is currently disabled. The service is under development.',
      message: 'Please visit https://github.com/denisps/freespeechapp for more information.'
    });
    return;
  }
  
  // Health check (always enabled)
  if (pathname === '/health' && req.method === 'GET') {
    sendJSON(res, 200, {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      clients: clients.size,
      messages: messages.length,
      apiEnabled: API_ENABLED
    });
    return;
  }
  
  // Connect - register a client
  if (pathname === '/connect' && req.method === 'POST') {
    const clientId = `client_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
    clients.set(clientId, {
      id: clientId,
      lastSeen: Date.now(),
      lastMessageIndex: messages.length
    });
    
    sendJSON(res, 200, {
      clientId: clientId,
      timestamp: new Date().toISOString()
    });
    return;
  }
  
  // Send message
  if (pathname === '/send' && req.method === 'POST') {
    parseBody(req, (err, data) => {
      if (err) {
        sendJSON(res, 400, { error: 'Invalid JSON' });
        return;
      }
      
      const { clientId, content, to } = data;
      
      if (!clientId || !content) {
        sendJSON(res, 400, { error: 'Missing clientId or content' });
        return;
      }
      
      // Validate client exists
      const client = clients.get(clientId);
      if (!client) {
        sendJSON(res, 401, { error: 'Invalid clientId. Please reconnect.' });
        return;
      }
      
      // Update last seen
      client.lastSeen = Date.now();
      
      // Add message to queue
      const message = {
        id: `msg_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`,
        from: clientId,
        to: to || null, // null means broadcast
        content: content,
        timestamp: Date.now()
      };
      
      messages.push(message);
      
      // Keep only recent messages
      if (messages.length > MAX_MESSAGES) {
        messages.shift();
      }
      
      sendJSON(res, 200, {
        status: 'sent',
        messageId: message.id,
        timestamp: new Date(message.timestamp).toISOString()
      });
    });
    return;
  }
  
  // Poll for new messages
  if (pathname === '/poll' && req.method === 'GET') {
    const clientId = parsedUrl.query.clientId;
    
    if (!clientId) {
      sendJSON(res, 400, { error: 'Missing clientId parameter' });
      return;
    }
    
    const client = clients.get(clientId);
    if (!client) {
      sendJSON(res, 401, { error: 'Invalid clientId. Please reconnect.' });
      return;
    }
    
    // Update last seen
    client.lastSeen = Date.now();
    
    // Get new messages since last poll
    const newMessages = messages.slice(client.lastMessageIndex)
      .filter(msg => {
        // Include broadcasts and direct messages to this client
        return msg.to === null || msg.to === clientId;
      })
      .map(msg => ({
        id: msg.id,
        from: msg.from,
        content: msg.content,
        timestamp: new Date(msg.timestamp).toISOString(),
        type: msg.to ? 'direct' : 'broadcast'
      }));
    
    // Update client's message index
    client.lastMessageIndex = messages.length;
    
    sendJSON(res, 200, {
      messages: newMessages,
      timestamp: new Date().toISOString()
    });
    return;
  }
  
  // Disconnect
  if (pathname === '/disconnect' && req.method === 'POST') {
    parseBody(req, (err, data) => {
      if (err) {
        sendJSON(res, 400, { error: 'Invalid JSON' });
        return;
      }
      
      const { clientId } = data;
      if (clientId && clients.has(clientId)) {
        clients.delete(clientId);
      }
      
      sendJSON(res, 200, { status: 'disconnected' });
    });
    return;
  }
  
  // Not found
  sendJSON(res, 404, { error: 'Not found' });
}

// Create server
const server = USE_HTTPS && serverOptions.cert
  ? https.createServer(serverOptions, handleRequest)
  : http.createServer(handleRequest);

const PORT = USE_HTTPS && serverOptions.cert ? HTTPS_PORT : HTTP_PORT;

server.listen(PORT, () => {
  const protocol = USE_HTTPS && serverOptions.cert ? 'https' : 'http';
  console.log(`FreeSpeechApp server listening on port ${PORT}`);
  console.log(`Protocol: ${protocol}`);
  console.log(`Health check: ${protocol}://localhost:${PORT}/health`);
  console.log('Cloudflare compatible - using HTTP polling');
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
