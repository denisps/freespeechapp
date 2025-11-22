let ws = null;
let clientId = null;

// Update message type selector
document.getElementById('messageType').addEventListener('change', function() {
    const recipientInput = document.getElementById('recipientId');
    if (this.value === 'direct') {
        recipientInput.style.display = 'inline-block';
    } else {
        recipientInput.style.display = 'none';
    }
});

function connect() {
    const serverUrl = document.getElementById('serverUrl').value;
    
    if (!serverUrl) {
        addMessage('system', 'Please enter a server URL');
        return;
    }
    
    try {
        ws = new WebSocket(serverUrl);
        
        ws.onopen = function() {
            updateStatus('connected', 'Connected');
            addMessage('system', 'Connected to server');
            document.getElementById('connectBtn').disabled = true;
            document.getElementById('disconnectBtn').disabled = false;
        };
        
        ws.onmessage = function(event) {
            try {
                const data = JSON.parse(event.data);
                handleMessage(data);
            } catch (err) {
                console.error('Error parsing message:', err);
            }
        };
        
        ws.onerror = function(error) {
            console.error('WebSocket error:', error);
            addMessage('system', 'Connection error occurred');
        };
        
        ws.onclose = function() {
            updateStatus('disconnected', 'Disconnected');
            addMessage('system', 'Disconnected from server');
            document.getElementById('connectBtn').disabled = false;
            document.getElementById('disconnectBtn').disabled = true;
            ws = null;
            clientId = null;
        };
    } catch (err) {
        addMessage('system', `Connection failed: ${err.message}`);
    }
}

function disconnect() {
    if (ws) {
        ws.close();
    }
}

function handleMessage(data) {
    switch (data.type) {
        case 'welcome':
            clientId = data.clientId;
            document.getElementById('clientInfo').innerHTML = `Your ID: <strong>${clientId}</strong>`;
            addMessage('system', `Connected with ID: ${clientId}`);
            break;
        case 'message':
            addMessage('received', data.content, data.from, data.timestamp);
            break;
        case 'pong':
            addMessage('system', 'Pong received');
            break;
        default:
            console.log('Unknown message type:', data.type);
    }
}

function sendMessage() {
    const input = document.getElementById('messageInput');
    const messageType = document.getElementById('messageType').value;
    const recipientId = document.getElementById('recipientId').value;
    const content = input.value.trim();
    
    if (!ws || ws.readyState !== WebSocket.OPEN) {
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
    
    const message = {
        type: messageType,
        content: content,
        from: clientId
    };
    
    if (messageType === 'direct') {
        message.to = recipientId;
    }
    
    try {
        ws.send(JSON.stringify(message));
        addMessage('sent', content, 'You', new Date().toISOString());
        input.value = '';
    } catch (err) {
        addMessage('system', `Failed to send message: ${err.message}`);
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
