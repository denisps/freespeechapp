# FreeSpeechApp Client

Secure, privacy-focused communication client built on cryptographic principles.

## Principle of Operation

The client is a single, self-contained HTML file that operates in three modes:

### 1. Run Stateless App
- User provides an **App ID** (ECDSA private key)
- Generates ephemeral identity on-the-fly
- No data stored locally - fully stateless operation
- Perfect for one-time secure communications

**Interface:**
- Input field for App ID (ECDSA key)
- Start button to begin session

### 2. Generate Identity File
- User creates a password-protected identity
- Generates ECDSA key pair for signing user data
- ECDSA public key becomes the user's identity
- Generates AES-256 encryption key for data encryption
- Encrypts both ECDSA private key and AES key with user password using PBKDF2 + salt
- Exports encrypted identity as a downloadable HTML file (copy of the client itself)
- Encrypted keys embedded in a `<script>` tag within the HTML
- Opening the identity file reveals a 4th section: **Run Stateful App**

**Interface:**
- Password input field
- Generate button
- Downloads identity file as HTML blob

**Technical Details:**
- ECDSA key pair generation (P-256 curve)
- ECDSA public key = user identity
- ECDSA private key = signing key (encrypted)
- AES-256 key generation for data encryption
- PBKDF2 password derivation
- Random salt generation
- All keys encrypted and stored in `<script>` tag within HTML
- Identity file is self-contained copy of the client with embedded credentials

**Identity File Structure:**
```html
<!DOCTYPE html>
<html>
  <head>...</head>
  <body>
    <!-- Client UI -->
    <script id="identity-data" type="application/json">
    {
      "encryptedEcdsaPrivateKey": "...",
      "ecdsaPublicKey": "...",
      "encryptedAesKey": "...",
      "salt": "...",
      "version": "1.0"
    }
    </script>
    <!-- Client logic -->
  </body>
</html>
```

### 4. Run Stateful App (Available only in Identity Files)
- Appears only when opening a generated identity file
- User enters password to decrypt embedded keys
- Maintains persistent identity across sessions
- Secure, password-protected stateful operation

**Interface:**
- Password input field to unlock identity
- Unlock button to decrypt and start session

### 3. Provide More FreeSpeech Gateways
- Add additional gateway server URLs
- Distributed trust model - no single point of failure
- Routes through multiple gateways for enhanced privacy
- Load balancing and redundancy

**Interface:**
- Text area for adding gateway URLs
- Save/update gateway configuration

## Features

- Single HTML file - fully self-contained
- Zero external dependencies
- Client-side encryption
- HTTP polling for real-time communication (no WebSockets)
- Cloudflare compatible
- Broadcast and direct messaging
- Connection status indicator
- Message history display
- Responsive design

## Usage

1. Open `index.html` in a web browser
2. Enter the server URL (e.g., `https://localhost:8443`)
3. Click "Connect"
4. Start sending messages

## How It Works

The client uses HTTP polling instead of WebSockets:

1. **Connect**: POST to `/connect` to get a client ID
2. **Poll**: GET `/poll` every 2 seconds to fetch new messages
3. **Send**: POST to `/send` to send messages
4. **Disconnect**: POST to `/disconnect` when done

This approach is compatible with:
- ✅ Cloudflare free plan
- ✅ Any HTTP proxy/CDN
- ✅ Corporate firewalls
- ✅ Restrictive networks

## Deployment

The client is a static web application consisting of:
- `index.html` - Main HTML file
- `app.js` - JavaScript application logic (polling implementation)
- `style.css` - Styling

Deploy these files to:
- Any web server (nginx, Apache)
- Static hosting (GitHub Pages, Netlify, Vercel)
- CDN (Cloudflare Pages)
- Or open locally in a browser

## Configuration

Edit the default server URL in `index.html`:
```html
<input type="text" id="serverUrl" placeholder="https://your-server.com" value="https://your-server.com">
```

## Polling Interval

The default polling interval is 2 seconds. To change it, edit `app.js`:
```javascript
const POLL_INTERVAL = 2000; // milliseconds
```

## Security Note

When connecting to a server with a self-signed certificate, your browser will show a security warning. You'll need to accept the certificate to proceed. For production use, consider using a certificate from a trusted Certificate Authority.
