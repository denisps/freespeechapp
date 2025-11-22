#!/bin/bash
# Generate or regenerate SSL certificates for FreeSpeechApp

set -e

INSTALL_DIR="${1:-/opt/freespeechapp}"
CERT_DIR="$INSTALL_DIR/server/certs"

echo "Generating SSL Certificates"
echo "============================"

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Backup existing certificates
if [ -f "$CERT_DIR/server.crt" ]; then
    echo "Backing up existing certificates..."
    mv "$CERT_DIR/server.crt" "$CERT_DIR/server.crt.bak.$(date +%s)" || true
    mv "$CERT_DIR/server.key" "$CERT_DIR/server.key.bak.$(date +%s)" || true
fi

# Get hostname
HOSTNAME=$(hostname -f 2>/dev/null || hostname)

# Generate new certificate (valid for 100 years - non-expiring for practical purposes)
echo "Generating new certificate for: $HOSTNAME"
openssl req -x509 -nodes -days 36500 -newkey rsa:4096 \
    -keyout "$CERT_DIR/server.key" \
    -out "$CERT_DIR/server.crt" \
    -subj "/C=US/ST=State/L=City/O=FreeSpeechApp/CN=$HOSTNAME" \
    -addext "subjectAltName=DNS:$HOSTNAME,DNS:localhost,IP:127.0.0.1"

# Set proper permissions
chmod 600 "$CERT_DIR/server.key"
chmod 644 "$CERT_DIR/server.crt"

echo ""
echo "Certificates generated successfully!"
echo "Location: $CERT_DIR"
echo "Valid for: 100 years (36,500 days)"
echo ""
echo "Certificate details:"
openssl x509 -in "$CERT_DIR/server.crt" -noout -subject -dates

# Restart service if it's running
if systemctl is-active --quiet freespeechapp 2>/dev/null; then
    echo ""
    echo "Restarting freespeechapp service..."
    systemctl restart freespeechapp
    echo "Service restarted"
fi
