# FreeSpeechApp Client

Web-based client for secure communication.

## Features

- Clean, modern user interface
- Real-time WebSocket communication
- Broadcast and direct messaging
- Connection status indicator
- Message history display
- Responsive design

## Usage

1. Open `index.html` in a web browser
2. Enter the server URL (e.g., `wss://localhost:8443`)
3. Click "Connect"
4. Start sending messages

## Deployment

The client is a static web application consisting of:
- `index.html` - Main HTML file
- `app.js` - JavaScript application logic
- `style.css` - Styling

Deploy these files to any web server or use them locally by opening `index.html` in a browser.

## Security Note

When connecting to a server with a self-signed certificate, your browser will show a security warning. You'll need to accept the certificate to proceed. For production use, consider using a certificate from a trusted Certificate Authority.
