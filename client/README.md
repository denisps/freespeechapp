# FreeSpeechApp Client

Secure, privacy-focused communication client built on cryptographic principles.

## Principle of Operation

The client is a single, self-contained HTML file that operates in three modes:

### 1. Run Stateless App
- User provides an **App ID** (ECDSA public key) - identifies and verifies the application
- App ID used to fetch app from other peers and verify its integrity
- Generates temporary **User ID** (ECDSA key pair) - identifies the user
- User ID is ephemeral and not stored
- No data stored locally - fully stateless operation
- Perfect for one-time secure communications

**Interface:**
- Input field for App ID (ECDSA public key)
- Start button to begin session

### 2. Generate Identity File
- User creates a password-protected identity
- Generates **User ID** ECDSA key pair for signing user data
- User ID public key becomes the user's persistent identity
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
- User ID: ECDSA key pair generation (P-256 curve)
- User ID public key = persistent user identity (derived from private key)
- User ID private key = signing key (encrypted)
- AES-256 key generation for data encryption
- PBKDF2 password derivation with random salt
- Keys packaged into JSON structure
- JSON encrypted with password-derived key
- Encrypted data base64 encoded
- Salt stored separately (needed for decryption)
- Identity file is self-contained copy of the client with embedded credentials

**Encryption Process:**
1. Generate User ID (ECDSA key pair) + AES key
2. Package keys into JSON: `{"userIdPrivateKey": "...", "aesKey": "..."}`
3. Derive encryption key from password + salt using PBKDF2
4. Encrypt JSON with derived key → crypto-box
5. Base64 encode crypto-box
6. Store salt + base64(crypto-box) + gateways list in HTML (gateways stored unencrypted)

**Identity File Structure:**
```html
<!DOCTYPE html>
<html>
  <head>...</head>
  <body>
    <!-- Client UI -->
    <script id="identity-data" type="application/json">
    {
      "salt": "base64-encoded-salt",
      "cryptoBox": "base64(encrypt(json(keys)))",
      "gateways": [
        "https://gateway1.example.com",
        "https://gateway2.example.com"
      ],
      "version": "1.0"
    }
    </script>
    <!-- Client logic -->
  </body>
</html>
```

**Decryption Process:**
1. Read salt from identity-data
2. User enters password
3. Derive decryption key from password + salt using PBKDF2
4. Base64 decode crypto-box
5. Decrypt crypto-box with derived key → JSON
6. Parse JSON to extract User ID private key and AES key

### 4. Run Stateful App (Available only in Identity Files)
- Appears only when opening a generated identity file
- User enters **App ID** to fetch and verify the application
- User enters password to decrypt embedded User ID keys
- Maintains persistent identity across sessions
- Secure, password-protected stateful operation

**Interface:**
- Input field for App ID (ECDSA public key)
- Password input field to unlock identity
- Unlock button to decrypt and start session

## Application Startup Flow

When user starts the app (either stateless or stateful mode):

1. **App Verification:**
   - User enters **App ID** (ECDSA public key)
   - Fetch app code from peers using App ID
   - Verify app integrity using App ID signature

2. **Key Preparation:**
   - **Stateless mode:** Generates temporary User ID (identifies user)
   - **Stateful mode:** User enters password → decrypts embedded User ID (persistent user identity)

3. **Gateway Selection:**
   - Selects first gateway from configured list
   - Creates iframe with gateway URL as `src`
   - Iframe is small but visible to user

4. **Gateway Communication:**
   - Listens for `postMessage` events from gateway iframe
   - Gateway presents content to user (ads, captcha, etc.)
   - Two-way communication via `window.postMessage` API

5. **Peer Discovery:**
   - Gateway verifies user action (captcha solved, ad viewed, etc.)
   - Gateway sends peer list via `postMessage` to client
   - Each peer includes: SDP offer and ICE candidates
   - Peer ID = hash(SDP + ICE candidates)

6. **WebRTC Connection Establishment:**
   - Client attempts to connect to peers (up to connection limit)
   - Creates WebRTC DataChannel for each peer
   - Sends own SDP answer and ICE candidates back to gateway
   - Gateway relays connection info between peers

7. **App Content Download & Verification:**
   - Wait for minimum peer connections (e.g., 3 peers)
   - Download App Content from peers using App ID
   - Verify App Content signature with App ID (ECDSA public key)
   - Hide gateway iframe temporarily (allow more peers to connect)
   - Continue accepting connections up to maximum (e.g., 20 peers)
   - Remove gateway iframe automatically when complete

8. **Gateway UI:**
   - Iframe wrapped with warning: "⚠️ Untrusted Gateway Content"
   - "Next Gateway" button to switch to next in list
   - "Close Gateway" button in toolbar (user can manually remove iframe)
   - Gateway may display ads, captcha, or other content

**Gateway Iframe Structure:**
```html
<div class="gateway-container">
  <div class="gateway-warning">
    ⚠️ Untrusted Gateway Content
    <button id="next-gateway">Next Gateway →</button>
    <button id="close-gateway">Close Gateway ✕</button>
  </div>
  <iframe 
    id="gateway-frame" 
    src="https://gateway1.example.com"
    sandbox="allow-scripts allow-same-origin"
    width="400"
    height="200"
    style="display: block;">
  </iframe>
</div>
```

**Gateway Lifecycle:**
1. **Visible**: Initial captcha/ad display
2. **Hidden** (temporary): After minimum peers + app download + verification
3. **Removed**: After maximum peers reached OR user clicks "Close Gateway"

**Message Flow:**
```
1. Client → Gateway: Ready
2. Gateway → Client: Display captcha/ad
3. User completes captcha/views ad
4. Gateway → Client: Peer list (SDP + ICE candidates)
5. Client → Gateway: Own SDP + ICE candidates for each peer
6. Gateway relays connection info
7. Client ↔ Peers: WebRTC DataChannel established
8. Client downloads App Content from peers (minimum 3 peers)
9. Client verifies App Content signature with App ID
10. Gateway iframe hidden (more peers can still connect)
11. Maximum peers reached OR user clicks "Close Gateway"
12. Gateway iframe removed
```

**Peer List Message Format:**
```javascript
{
  type: "peers",
  peers: [
    {
      id: "hash(sdp+ice)",
      sdp: {...},
      iceCandidates: [...]
    },
    ...
  ]
}
```

**Connection Limits:**
- Minimum peers for app download: 3
- Maximum concurrent peer connections: 10-20
- Priority: closest peers by latency
- Drop slowest connections when limit reached
- Gateway iframe lifecycle: visible → hidden (after min peers) → removed (after max peers or user request)

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
