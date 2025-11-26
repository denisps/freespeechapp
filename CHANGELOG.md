# Changelog

All notable changes to FreeSpeechApp will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-26

### Added - Client
- Self-contained identity files with encrypted credentials
- ECDSA P-256 cryptography for User IDs
- AES-256-GCM encryption with PBKDF2 password derivation
- WebRTC P2P peer connections with ICE candidate handling
- Four operational modes: Stateful App, Stateless App, Generate Identity, Manage Gateways
- Mock gateway for local testing
- Comprehensive test suite (40 tests)

### Added - Server
- Zero-dependency HTTP polling server
- In-memory message storage (30-second retention)
- Health check endpoint
- Bootstrap scripts for Ubuntu, CentOS, Fedora, macOS
- 100-year self-signed certificate generation
- Systemd/LaunchAgent service configuration

### Added - Protocol
- Gateway communication via postMessage API
- Peer discovery and WebRTC signaling
- ICE candidate gathering and exchange
- Distributed trust model with multiple gateway support

### Security
- Sandboxed iframe isolation for gateways and apps
- Code injection prevention through postMessage-only API
- No external dependencies for security auditing

### Documentation
- Comprehensive README with deployment guides
- Architecture documentation for P2P model
- Security audit results and hardening checklist
- Testing guide with 91 automated tests
- AI agent instructions for development workflow

## Version Components

- **Client Version**: 1.0.0 (embedded in identity files)
- **Server Version**: 1.0.0
- **Protocol Version**: 1.0 (gateway communication)
- **Crypto Version**: 1.0 (ECDSA P-256 + AES-256-GCM)

## Compatibility

- Identity files from v1.0.0 are supported indefinitely
- Protocol v1.0 is the baseline for all gateway implementations
- Clients must support protocol v1.0 for backward compatibility

[1.0.0]: https://github.com/denisps/freespeechapp/releases/tag/v1.0.0
