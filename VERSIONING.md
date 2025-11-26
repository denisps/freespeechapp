# FreeSpeechApp Versioning Strategy

## Version Components

FreeSpeechApp uses **Semantic Versioning** with component tracking:

```
VERSION                # 1.0.0 (overall project)
client/VERSION         # 1.0.0 (client/identity file version)
server/VERSION         # 1.0.0 (server version)  
PROTOCOL_VERSION       # 1.0 (gateway communication protocol)
```

## Semantic Versioning Format

**MAJOR.MINOR.PATCH**

- **MAJOR**: Breaking changes to protocol, crypto, or architecture
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes, documentation, security patches

## Version Rules

### Overall Project Version
Changes when any component has a MAJOR or MINOR update.

### Client Version (Identity Files)
- Embedded in identity files as `"clientVersion": "1.0.0"`
- **MAJOR**: Breaking crypto changes (ECDSA algorithm change)
- **MINOR**: New features (file sharing, new UI modes)
- **PATCH**: Bug fixes, UI improvements
- **Compatibility**: New clients MUST support old identity file versions

### Server Version
- **MAJOR**: Breaking API changes
- **MINOR**: New endpoints, features
- **PATCH**: Bug fixes, performance improvements
- **Note**: Changes rare due to zero-dependency constraint

### Protocol Version (Gateway Communication)
- Format: `MAJOR.MINOR` (e.g., "1.0")
- **MAJOR**: Breaking changes to postMessage API
- **MINOR**: New message types (backward compatible)
- **Rule**: Gateways MUST support all versions >= their implemented version

## Identity File Version Structure

```javascript
{
  "clientVersion": "1.0.0",      // Client that created this file
  "protocolVersion": "1.0",       // Gateway protocol version
  "cryptoVersion": "1.0",         // ECDSA P-256 + AES-256-GCM
  "salt": "...",
  "cryptoBox": "...",
  "gateways": [...],
  "version": "1.0"                // Legacy field (deprecated in 2.0)
}
```

## Gateway Operator Responsibilities

⚠️ **CRITICAL FOR SECURITY AND STABILITY**

Gateways are run by independent operators (individuals/companies, possibly for ad revenue). They MUST:

### 1. Monitor for Updates
- Subscribe to GitHub releases: https://github.com/denisps/freespeechapp/releases
- Watch for security advisories
- Join community channels for announcements

### 2. Update Frequency
- **Security patches**: Within 24-48 hours of release
- **Minor updates**: Within 1 week
- **Major updates**: Plan migration within 1 month

### 3. Version Advertisement
Gateway MUST advertise its protocol version:
```javascript
// On client ready message
{
  type: 'gatewayInfo',
  protocolVersion: '1.0',
  gatewayVersion: '1.2.3',  // Optional: gateway software version
  features: ['peers', 'relay', 'ice']
}
```

### 4. Security Best Practices
- Run gateways behind HTTPS (required)
- Keep Node.js/runtime updated
- Monitor for suspicious activity
- Rate limit client connections
- Validate all incoming messages

### 5. Backward Compatibility
- Support at least 2 protocol versions back
- Example: Protocol v1.2 gateway MUST support v1.0, v1.1, v1.2
- Gracefully handle old client messages

### 6. Deprecation Timeline
When a protocol version is deprecated:
- **T+0 months**: Deprecation announced
- **T+6 months**: New features only in new version
- **T+12 months**: Old version support dropped

## Breaking Change Strategy

### Crypto Algorithm Change (MAJOR bump)
```
1.0.0 → 2.0.0
Timeline:
- Month 0: Announce v2.0.0 with new crypto algorithm
- Month 3: Release v2.0.0 supporting both old and new
- Month 9: v2.1.0 deprecates old algorithm
- Month 12: v3.0.0 removes old algorithm support
```

### Protocol Change (MAJOR bump)
```
protocol-v1.0 → protocol-v2.0
Timeline:
- Month 0: Announce v2.0
- Month 1: Release clients supporting both v1.0 and v2.0
- Month 6: Encourage gateway operators to upgrade
- Month 12: v1.0 deprecated (still works)
- Month 18: v1.0 support dropped
```

### Protocol Extension (MINOR bump)
```
protocol-v1.0 → protocol-v1.1
- New optional features added
- Old clients ignore unknown message types
- No gateway action required (backward compatible)
```

## Version Checking

### Client Checks Identity File Version
```javascript
function checkIdentityVersion(identityData) {
  const CLIENT_VERSION = "1.1.0";
  const identityVersion = identityData.clientVersion || "1.0.0";
  
  if (compareVersions(identityVersion, CLIENT_VERSION) < 0) {
    console.log(`Identity file is v${identityVersion}, current client is v${CLIENT_VERSION}`);
    offerUpgrade(identityVersion, CLIENT_VERSION);
  }
}
```

### Gateway Protocol Negotiation
```javascript
// Client announces supported protocols
window.postMessage({
  type: 'ready',
  clientVersion: '1.1.0',
  supportedProtocols: ['1.0', '1.1']
}, '*');

// Gateway responds with protocol to use
{
  type: 'gatewayInfo',
  protocolVersion: '1.0',  // Use lowest common version
  gatewayVersion: '1.2.3'
}
```

## Release Process

```bash
# 1. Update version files
echo "1.1.0" > VERSION
echo "1.1.0" > client/VERSION
# Update PROTOCOL_VERSION if protocol changed

# 2. Update CHANGELOG.md
# Document all changes

# 3. Update identity file version in client/index.html
# Search for "clientVersion" and update

# 4. Run all tests
./run-all-tests.sh

# 5. Commit with version number
git add -A
git commit -m "Release v1.1.0: Brief description"

# 6. Create git tag
git tag v1.1.0 -m "Release v1.1.0

Added:
- Feature 1
- Feature 2

Changed:
- Change 1

Security:
- Security fix 1

Gateway operators: Please update within 1 week for stability improvements."

# 7. Push with tags
git push origin main --tags

# 8. Create GitHub release
# Attach release notes, migration guide if needed
```

## Version Display

### Server Startup
```
FreeSpeechApp Server v1.1.0
Protocol: v1.0
Client compatibility: v1.0.0+
Listening on port 8443 (HTTPS)
```

### Client UI
Display in footer or about dialog:
```
FreeSpeechApp v1.1.0
Protocol: v1.0
Identity: v1.0.0
```

### Gateway Startup
```
FreeSpeechApp Gateway v1.2.3
Supported protocols: v1.0, v1.1
Listening on port 443
```

## Gateway Update Notification System

Gateways should implement update checking:

```javascript
// Check for updates daily
async function checkForUpdates() {
  const response = await fetch('https://api.github.com/repos/denisps/freespeechapp/releases/latest');
  const latest = await response.json();
  const currentVersion = '1.0.0';
  
  if (compareVersions(latest.tag_name, currentVersion) > 0) {
    console.warn(`⚠️  Update available: ${latest.tag_name}`);
    console.warn(`   Current version: ${currentVersion}`);
    console.warn(`   Release notes: ${latest.html_url}`);
    
    // If security update
    if (latest.name.includes('[SECURITY]')) {
      console.error('🚨 SECURITY UPDATE REQUIRED - Update within 48 hours');
    }
  }
}
```

## Compatibility Matrix

| Client Version | Server Version | Protocol Version | Compatible |
|----------------|----------------|------------------|------------|
| 1.0.0          | 1.0.0          | 1.0              | ✅ Yes     |
| 1.1.0          | 1.0.0          | 1.0              | ✅ Yes     |
| 1.0.0          | 1.1.0          | 1.0              | ✅ Yes     |
| 2.0.0          | 1.0.0          | 2.0              | ❌ No      |
| 1.0.0          | 2.0.0          | 1.0              | ⚠️  Degraded |

## Migration Guides

When breaking changes occur, provide migration guides:

### Example: Protocol v1.0 → v2.0 Migration Guide
```markdown
# Gateway Migration Guide: Protocol v1.0 → v2.0

## Changes
- New message type: `peerRating`
- Changed: `peers` message now includes `capability` field

## Code Changes Required
[Code examples]

## Testing
[Test instructions]

## Rollback Plan
[How to rollback if issues occur]
```

## Version Deprecation Policy

- **MINOR versions**: Supported for 12 months after next MINOR release
- **MAJOR versions**: Supported for 18 months after next MAJOR release
- **Security patches**: Applied to current MAJOR + previous MAJOR only

## Questions?

- GitHub Issues: https://github.com/denisps/freespeechapp/issues
- Security: See SECURITY.md for responsible disclosure
- Gateway operators: Consider joining operator mailing list (TBD)
