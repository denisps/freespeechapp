# FreeSpeechApp - AI Coding Agent Instructions

## Project Overview

FreeSpeechApp is a **peer-to-peer decentralized communication platform** where users run apps in isolated environments using self-contained identity files. Servers exist **only for distributed bootstrapping** - the real architecture is P2P WebRTC connections between clients.

**Key Architecture Decisions**:
1. **P2P First** - WebRTC peer-to-peer is the primary architecture, not server-client
2. **Self-Contained Identity** - HTML identity files isolated from infrastructure code
3. **Distributed Bootstrapping** - Multiple gateway servers prevent single point of failure/coercion
4. **Zero Dependencies** - Server uses only Node.js built-in modules for security auditing

## Critical "Zero Dependencies" Constraint

The `server/` directory uses **ONLY** Node.js built-in modules:
- `https`, `http` - servers
- `fs`, `path` - file operations  
- `url` - URL parsing

**Never add npm dependencies to server/** - this is a core architectural principle for security, simplicity, and zero-setup deployment.

## Project Structure

```
server/           # Node.js HTTP polling server (zero dependencies!)
  server.js       # Single-file server (~350 lines, stateless)
  package.json    # dependencies: {} (intentionally empty)
  public/         # Static files served to clients
client/           # Pure vanilla JS/HTML/CSS (no frameworks)
  index.html      # Self-contained client with crypto & WebRTC
  mock-gateway.html # Mock gateway for testing
  test.js         # Comprehensive test suite (40 tests)
bootstrap/        # Bash deployment scripts
  install.sh      # Auto-detect Linux distro
  install-*.sh    # Platform-specific installers
  generate-certs.sh # 100-year self-signed certificates
```

## Communication Protocol (HTTP Polling)

The server uses REST endpoints instead of WebSockets:

### API Endpoints (when API_ENABLED=true)

```javascript
POST /connect        // Register client, get clientId
POST /send          // Send message (broadcast or direct)
GET  /poll?clientId // Poll for new messages (2-second interval)
POST /disconnect    // Unregister client
GET  /health        // Server status (always enabled)
```

### In-Memory Storage Structure

```javascript
messages = [
  {
    id: "msg_timestamp_random",
    from: "client_id",
    to: "client_id" | null,  // null = broadcast
    content: "...",
    timestamp: 123456789
  }
]

clients = Map {
  "client_id" => {
    id: "client_id",
    lastSeen: 123456789,
    lastMessageIndex: 42  // Track which messages client has seen
  }
}
```

**Important**: Messages auto-expire after 30 seconds. No persistence across restarts. This is intentional for privacy and simplicity.

## Client Architecture (Stateless P2P Focus)

The client (`client/index.html`) is a **single self-contained HTML file** with four operational modes:

1. **Run Stateful App** - Opens apps using persistent encrypted identity
2. **Run Stateless App** - Temporary identity, no data stored (primary mode)
3. **Generate Identity File** - Creates password-protected identity HTML file
4. **Manage Gateways** - Configure gateway servers for peer discovery

### Key Client Features

- **ECDSA P-256 Cryptography** - User IDs are ECDSA public keys
- **AES-256-GCM Encryption** - Data encrypted with password-derived keys (PBKDF2)
- **WebRTC P2P** - Modular architecture with `ActualPeerConnection` / `MockPeerConnection`
- **ICE Candidate Handling** - Full NAT traversal with candidate gathering/exchange
- **Gateway Communication** - `postMessage` API for gateway iframe communication
- **Comprehensive Testing** - 40 automated tests covering crypto, WebRTC, identity management

### Self-Contained Identity Files (Core Feature)

**This is the key architectural innovation**: Identity files are complete, self-contained HTML files that:
- Contain the entire client application code
- Store encrypted user credentials (ECDSA private key, AES key)
- Are **isolated from infrastructure-controlled code**
- Can be backed up, transferred, and run anywhere
- Prevent single point of failure or coercion

**Security Model**:
```javascript
// Identity file structure
<script id="identity-data" type="application/json">
{
  "salt": "random-salt",
  "cryptoBox": "encrypted(userIdPrivateKey + aesKey)",
  "gateways": ["https://user-gateway1.com", "https://user-gateway2.com"],
  "version": "1.0"
}
</script>
```

**Gateway Configuration**:
- `https://freespeechapp.org/` - Default fallback gateway (also project homepage)
- Users should configure their own trusted gateways
- Demo URLs like `gateway1.com`, `gateway2.com` are for documentation only - never use in tests or production

**Isolation Principle**: User apps run in sandboxed iframes, completely isolated from:
- Server infrastructure code
- Gateway code (which runs in separate iframe)
- Other user apps

**This prevents code injection attacks** - apps cannot modify client/server infrastructure.

### Gateway Integration Pattern

```javascript
// Gateway lifecycle: visible → hidden → removed
1. User sees gateway (captcha/ad)
2. Gateway sends peer list with SDP offers + ICE candidates
3. Client creates answers, gathers ICE candidates
4. Client sends answers + ICE candidates back to gateway
5. Gateway relays connection info between peers
6. WebRTC establishes direct P2P connections using ICE
7. Client downloads/verifies app from peers
8. Gateway hidden after min peers (3), removed after max (20) or manually
```

**Distributed Trust Model**: Multiple gateways configured to prevent:
- **Single Point of Failure** - If one gateway is down, others work
- **Single Point of Coercion** - No single entity can control access or censor users
- **Gateway Isolation** - Each gateway runs in sandboxed iframe with `postMessage` API only

**Security**: Gateways are untrusted - they cannot inject code or access user data. The `sandbox` attribute restricts iframe capabilities.

**Gateway URLs**:
- Production: Users configure their own trusted gateways
- Fallback: `https://freespeechapp.org/` (default when no user gateways configured)
- Testing: Use `mock-gateway.html` for local tests
- Documentation: Example URLs like `gateway1.example.com` are for illustration only

### Testing Architecture

The client uses **dependency injection** for testability:

```javascript
// Production (index.html)
appState.peerConnectionFactory = ActualPeerConnection;
appState.appVerifier = ActualAppVerifier;

// Testing (test.js)
appState.peerConnectionFactory = MockPeerConnection;
appState.appVerifier = MockAppVerifier;
```

Run tests via toolbar button "Run Tests" or programmatically: `runTests()`

## Deployment Workflows

### Local Development

```bash
# Quick start (no installation)
cd server
node server.js

# With installation (creates systemd/LaunchAgent service)
./admin-deploy.sh --local
```

### Remote Deployment

```bash
# 1. Generate config (first run)
./admin-deploy.sh

# 2. Edit config with your server details
nano freespeech-admin.conf

# 3. Deploy
./admin-deploy.sh

# Updates: run again to pull latest, restart service
```

### Bootstrap Process

The `bootstrap/install.sh` script:
1. Detects Linux distro (Ubuntu/CentOS/Fedora/macOS)
2. Installs Node.js v18
3. Clones repository to `/opt/freespeechapp`
4. ~~Installs dependencies~~ (NO-OP - zero dependencies!)
5. Generates 100-year self-signed certificates (RSA 4096-bit)
6. Creates systemd service (or LaunchAgent on macOS)
7. Configures firewall, starts service

## Common Development Patterns

### Adding Server Endpoints

```javascript
// In server.js handleRequest()
if (pathname === '/new-endpoint' && req.method === 'POST') {
  parseBody(req, (err, data) => {
    // Validate input
    if (!data.requiredField) {
      sendJSON(res, 400, { error: 'Missing field' });
      return;
    }
    
    // Process request
    sendJSON(res, 200, { status: 'success' });
  });
  return;
}
```

**Never use external middleware** - keep all logic in `server.js` using built-in modules.

### Modifying Client Crypto

```javascript
// All crypto operations use Web Crypto API
const keyPair = await window.crypto.subtle.generateKey(
  { name: "ECDSA", namedCurve: "P-256" },
  true,
  ["sign", "verify"]
);

// Always use ECDSA P-256 for User IDs
// Always use AES-256-GCM for data encryption
// Always use PBKDF2 (100k iterations) for password derivation
```

### Testing New Features

```javascript
// Add tests to client/test.js
function test_new_feature() {
  const result = yourFunction();
  if (result !== expected) {
    throw new Error(`Expected ${expected}, got ${result}`);
  }
  console.log("✓ Test passed");
}

// Run via "Run Tests" button or: runTests()
```

**Test Data Preservation**:
- Always preserve existing localStorage data before modifying in tests
- Restore original values after test completes
- Use `test.example.com` domains for test gateway URLs (never production URLs)
- Never test for demo/documentation URLs (`gateway1.com`, `gateway2.com`)

## Configuration & Environment

### Server Environment Variables

```bash
HTTP_PORT=80         # HTTP port (default: 80)
HTTPS_PORT=443       # HTTPS port (default: 443)
USE_HTTPS=true       # Enable HTTPS (fallback to HTTP if certs missing)
CERT_PATH=./certs    # Certificate directory
API_ENABLED=false    # API disabled by default (under security review)
```

**Note**: APIs are temporarily disabled pending full specification and security review. The server's role is limited to bootstrapping - P2P connections are the primary architecture.

### Service Management

```bash
# Linux (systemd)
sudo systemctl status freespeechapp
sudo journalctl -u freespeechapp -f
sudo systemctl restart freespeechapp

# macOS (LaunchAgent)
launchctl list | grep freespeechapp
tail -f ~/Library/Logs/freespeechapp.log
launchctl unload/load ~/Library/LaunchAgents/org.freespeechapp.plist
```

## Testing Strategy

### Running Tests

```bash
# All tests
./run-all-tests.sh

# Individual test suites
cd server && npm test          # Server tests (3 tests)
./test-admin-deploy.sh        # Admin script tests (18 tests)
./test-bootstrap.sh           # Bootstrap tests (70 tests)

# Client tests (40 tests)
# Open client/index.html → Click "Run Tests" button
```

### Test Coverage

- **Server**: Health endpoint, home page, API state
- **Admin Script**: Config validation, deployment modes
- **Bootstrap**: Script structure, function completeness, variable declarations
- **Client**: Crypto operations, identity management, WebRTC, gateway communication

## Security Considerations

### Current Limitations

⚠️ **No authentication** - Anyone can connect and send messages
⚠️ **No rate limiting** - Vulnerable to spam/DoS
⚠️ **Service runs as root** - Default for quick deployment (not production-ready)
⚠️ **Self-signed certificates** - Browsers show warnings (use Let's Encrypt in production)

### Production Hardening Checklist

- [ ] Create dedicated `freespeechapp` user (not root)
- [ ] Use CA-signed certificates (Let's Encrypt)
- [ ] Add rate limiting per IP/client
- [ ] Implement authentication (API keys, JWT)
- [ ] Add Redis for multi-server scaling
- [ ] Configure firewall rules (`ufw`, `firewalld`)
- [ ] Set up monitoring (Prometheus, Grafana)

## Important Files & Documentation

- `VERSIONING.md` - **Read for release process** and version strategy
- `CHANGELOG.md` - Update with all changes before release
- `VERSION`, `client/VERSION`, `server/VERSION`, `PROTOCOL_VERSION` - Version tracking files
- `ARCHITECTURE_OVERVIEW.md` - **Read this first** for HTTP polling transition details
- `SECURITY.md` - Security audit results, hardening steps
- `TESTING.md` - Test suite documentation
- `LOCAL_DEVELOPMENT.md` - Local setup instructions
- `client/README.md` - **Critical** for understanding crypto architecture & WebRTC flow

## Anti-Patterns to Avoid

❌ Adding npm dependencies to `server/` (breaks zero-dependency principle)
❌ Using WebSockets (breaks Cloudflare compatibility)  
❌ Adding database persistence without explicit request (intentionally stateless)
❌ Breaking single-file nature of `client/index.html` (must remain self-contained)
❌ Changing ECDSA P-256 curve (standardized for User IDs)
❌ Removing mock implementations (needed for testing without network)
❌ Mixing infrastructure code with app code (isolation violation)
❌ Using `eval()`, `Function()`, or `innerHTML` with untrusted content (code injection risk)
❌ Committing to main with failing tests (breaks deployment)

## When Making Changes

1. **Server changes**: Ensure no external dependencies, restart service to test
2. **Client changes**: Test both production and mock modes, run test suite
3. **Bootstrap changes**: Test on target OS, update corresponding test file
4. **API changes**: Update both server and client, document in README
5. **Crypto changes**: Run full test suite, verify Web Crypto API compatibility

### Critical Workflow: Sync Specs → Tests → Code → Commits

⚠️ **MANDATORY BEFORE COMMITTING**:

```bash
# 1. Update specs in markdown files
# 2. Update tests to match new specs
# 3. Implement changes
# 4. Run ALL tests
./run-all-tests.sh

# 5. Verify all tests pass
# 6. Commit ONLY if tests pass
```

**Never commit with failing tests** - this breaks the deployment pipeline.

### Branch Strategy & Auto-Commit

**For small changes** (bug fixes, doc updates, minor tweaks):
```bash
# Make changes on main branch
./run-all-tests.sh
# If tests pass, commit automatically:
git add -A
git commit -m "Brief description of changes"
git push origin main
```

**For major work** (new features, significant refactoring):
```bash
# 1. Create feature branch
git checkout -b feature/descriptive-name

# 2. Make changes incrementally
# 3. Run tests after each logical change
./run-all-tests.sh

# 4. Commit when tests pass
git add -A
git commit -m "Descriptive commit message"

# 5. When feature complete, merge to main
git checkout main
git merge feature/descriptive-name
git push origin main

# 6. Delete feature branch
git branch -d feature/descriptive-name
```

**Auto-commit rules**:
- ✅ Auto-commit when all tests pass (91/91)
- ✅ Include all changed files (`git add -A`)
- ✅ Write descriptive commit messages explaining what changed
- ❌ Never commit with failing tests
- ❌ Never commit work-in-progress code to main
- ⚠️ Always run `./run-all-tests.sh` before committing

### Versioning & Releases

**Version files to update**:
```bash
VERSION                # Overall project version
client/VERSION         # Client/identity file version
server/VERSION         # Server version
PROTOCOL_VERSION       # Gateway protocol version (MAJOR.MINOR only)
CHANGELOG.md           # Document all changes
```

**Release process**:
```bash
# 1. Update version files
echo "1.1.0" > VERSION
echo "1.1.0" > client/VERSION
# Update others if changed

# 2. Update CHANGELOG.md
# Add section with all changes

# 3. Run tests
./run-all-tests.sh

# 4. Commit and tag
git add -A
git commit -m "Release v1.1.0: Description"
git tag v1.1.0 -m "Release notes with gateway operator notice"
git push origin main --tags
```

**See `VERSIONING.md` for complete strategy and gateway operator responsibilities.**

### Code Isolation & Security Requirements

🔒 **CRITICAL SECURITY PRINCIPLES**:

1. **Infrastructure Code Isolation**:
   - Server code (`server/`) never mixes with client code
   - Gateway code runs in sandboxed iframe
   - User apps run in separate sandboxed iframes
   - No shared globals between isolation boundaries

2. **Prevent Code Injection**:
   ```javascript
   // ❌ NEVER do this - allows code injection
   iframe.innerHTML = untrustedContent;
   eval(userInput);
   new Function(gatewayData)();
   
   // ✅ Always use sandbox and postMessage
   <iframe sandbox="allow-scripts allow-same-origin" src="..."></iframe>
   window.addEventListener('message', (event) => {
     // Validate event.origin
     if (event.origin !== expectedOrigin) return;
     // Process data-only messages
   });
   ```

3. **Iframe Sandbox Attributes**:
   - Gateway iframes: `sandbox="allow-scripts allow-same-origin"`
   - App iframes: `sandbox="allow-scripts"` (no same-origin)
   - Never use `allow-same-origin` + `allow-scripts` together for untrusted content

4. **Data Validation**:
   - Validate all `postMessage` data structures
   - Reject unexpected message types
   - Sanitize before displaying user content

5. **Identity File Integrity**:
   - Identity files are self-contained HTML
   - Encrypted credentials in `<script id="identity-data">` tag only
   - Never modify identity file structure programmatically
   - Users must re-generate identity if compromised

## Common Gotchas

- **"Port already in use"** - Check with `lsof -i :8443`, kill process or change port
- **Certificate warnings** - Normal for self-signed certs, click "Proceed to localhost"
- **API disabled by default** - Set `API_ENABLED=true` environment variable
- **Gateway iframe CSP** - Sandbox attribute limits what gateways can do
- **ICE candidate timeout** - 3-second timeout in `ActualPeerConnection.createOffer()`
- **Message retention** - Only 30 seconds, not a bug - by design for privacy

## Quick Reference Commands

```bash
# Start server (development)
cd server && USE_HTTPS=false HTTP_PORT=8080 node server.js

# Check server health
curl -k https://localhost:8443/health

# Deploy locally
./admin-deploy.sh --local

# Run all tests
./run-all-tests.sh

# View service logs
sudo journalctl -u freespeechapp -f  # Linux
tail -f ~/Library/Logs/freespeechapp.log  # macOS

# Regenerate certificates
cd bootstrap && ./generate-certs.sh
```

---

**Last Updated**: 2025-11-26  
**Architecture Version**: HTTP Polling (Cloudflare-compatible, zero dependencies)
