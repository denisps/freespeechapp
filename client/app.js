let clientId = null;
let pollingInterval = null;
const POLL_INTERVAL = 2000; // Poll every 2 seconds

// Update message type selector
document.getElementById('messageType').addEventListener('change', function() {
    const recipientInput = document.getElementById('recipientId');
    if (this.value === 'direct') {
        recipientInput.style.display = 'inline-block';
    } else {
        recipientInput.style.display = 'none';
    }
});

async function connect() {
    const serverUrl = document.getElementById('serverUrl').value;
    
    if (!serverUrl) {
        addMessage('system', 'Please enter a server URL');
        return;
    }
    
    try {
        updateStatus('connecting', 'Connecting...');
        
        // Call /connect endpoint
        const response = await fetch(`${serverUrl}/connect`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        clientId = data.clientId;
        
        updateStatus('connected', 'Connected');
        addMessage('system', `Connected with ID: ${clientId}`);
        document.getElementById('clientInfo').innerHTML = `Your ID: <strong>${clientId}</strong>`;
        document.getElementById('connectBtn').disabled = true;
        document.getElementById('disconnectBtn').disabled = false;
        
        // Start polling for messages
        startPolling(serverUrl);
        
    } catch (err) {
        updateStatus('disconnected', 'Connection failed');
        addMessage('system', `Connection failed: ${err.message}`);
        console.error('Connection error:', err);
    }
}

async function disconnect() {
    const serverUrl = document.getElementById('serverUrl').value;
    
    if (pollingInterval) {
        clearInterval(pollingInterval);
        pollingInterval = null;
    }
    
    if (clientId) {
        try {
            await fetch(`${serverUrl}/disconnect`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ clientId: clientId })
            });
        } catch (err) {
            console.error('Disconnect error:', err);
        }
    }
    
    clientId = null;
    updateStatus('disconnected', 'Disconnected');
    addMessage('system', 'Disconnected from server');
    document.getElementById('connectBtn').disabled = false;
    document.getElementById('disconnectBtn').disabled = true;
    document.getElementById('clientInfo').innerHTML = '';
}

function startPolling(serverUrl) {
    // Poll immediately
    pollMessages(serverUrl);
    
    // Then poll at intervals
    pollingInterval = setInterval(() => {
        pollMessages(serverUrl);
    }, POLL_INTERVAL);
}

async function pollMessages(serverUrl) {
    if (!clientId) return;
    
    try {
        const response = await fetch(`${serverUrl}/poll?clientId=${encodeURIComponent(clientId)}`);
        
        if (!response.ok) {
            if (response.status === 401) {
                // Client ID expired, need to reconnect
                addMessage('system', 'Session expired. Please reconnect.');
                disconnect();
                return;
            }
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        
        // Display new messages
        if (data.messages && data.messages.length > 0) {
            data.messages.forEach(msg => {
                addMessage('received', msg.content, msg.from, msg.timestamp);
            });
        }
        
    } catch (err) {
        console.error('Polling error:', err);
        // Don't disconnect on network errors, just log them
    }
}

async function sendMessage() {
    const input = document.getElementById('messageInput');
    const messageType = document.getElementById('messageType').value;
    const recipientId = document.getElementById('recipientId').value;
    const content = input.value.trim();
    const serverUrl = document.getElementById('serverUrl').value;
    
    if (!clientId) {
        addMessage('system', 'Not connected to server');
        return;
    }
    
    if (!content) {
        addMessage('system', 'Please enter a message');
        return;
    }
    
    if (messageType === 'direct' && !recipientId) {
        addMessage('system', 'Please enter a recipient ID for direct messages');
        return;
    }
    
    const payload = {
        clientId: clientId,
        content: content
    };
    
    if (messageType === 'direct') {
        payload.to = recipientId;
    }
    
    try {
        const response = await fetch(`${serverUrl}/send`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || `HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        addMessage('sent', content, 'You', data.timestamp);
        input.value = '';
        
    } catch (err) {
        addMessage('system', `Failed to send message: ${err.message}`);
        console.error('Send error:', err);
    }
}

function addMessage(type, content, from, timestamp) {
    const messagesDiv = document.getElementById('messages');
    const messageDiv = document.createElement('div');
    messageDiv.className = `message message-${type}`;
    
    let messageContent = '';
    
    if (type === 'system') {
        messageContent = `<div class="message-content"><strong>System:</strong> ${content}</div>`;
    } else {
        const time = timestamp ? new Date(timestamp).toLocaleTimeString() : new Date().toLocaleTimeString();
        messageContent = `
            <div class="message-header">
                <strong>${from || 'Unknown'}</strong>
                <span class="message-time">${time}</span>
            </div>
            <div class="message-content">${escapeHtml(content)}</div>
        `;
    }
    
    messageDiv.innerHTML = messageContent;
    messagesDiv.appendChild(messageDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

function updateStatus(status, text) {
    const indicator = document.getElementById('statusIndicator');
    const statusText = document.getElementById('statusText');
    
    statusText.textContent = text;
    
    if (status === 'connected') {
        indicator.textContent = '🟢';
    } else if (status === 'connecting') {
        indicator.textContent = '🟡';
    } else {
        indicator.textContent = '⚫';
    }
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

// Allow Enter key to send message (Shift+Enter for new line)
document.getElementById('messageInput').addEventListener('keydown', function(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
});

// Clean up on page unload
window.addEventListener('beforeunload', () => {
    if (clientId) {
        disconnect();
    }
});
