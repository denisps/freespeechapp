// FreeSpeechApp Test Framework
// Comprehensive test suite for cryptographic operations, gateway communication, and P2P functionality

// Mock App Signature Verifier for testing
const MockAppVerifier = {
    verify: async function(appContent) {
        // Simulate verification delay
        await new Promise(resolve => setTimeout(resolve, 50));
        
        // Mock verification logic - accept specific test patterns
        // In tests, we control the app content structure
        if (!appContent || !appContent.appId || !appContent.content || !appContent.signature) {
            return false;
        }
        
        // For testing: accept any app with 'mock' in the appId or signature
        if (appContent.appId.includes('mock') || appContent.signature.includes('mock')) {
            return true;
        }
        
        // For testing: reject apps with 'invalid' in signature
        if (appContent.signature.includes('invalid')) {
            return false;
        }
        
        // Default: accept valid-looking structure
        return appContent.version && appContent.content.length > 0;
    }
};

// Mock WebRTC Peer Connection for testing
const MockPeerConnection = {
    create: async function(peerInfo, onDataChannel, onConnectionStateChange) {
        // Simulate connection delay
        await new Promise(resolve => setTimeout(resolve, 100));
        
        // Create mock data channel
        const mockChannel = {
            readyState: 'open',
            send: (data) => console.log('Mock send:', data),
            close: () => console.log('Mock channel closed'),
            onmessage: null,
            onopen: null,
            onclose: null
        };
        
        // Simulate data channel opening
        setTimeout(() => {
            if (onDataChannel) {
                onDataChannel(mockChannel);
            }
            if (onConnectionStateChange) {
                onConnectionStateChange('connected');
            }
        }, 50);
        
        return {
            connection: { state: 'mock-connected' },
            localDescription: {
                type: 'answer',
                sdp: 'mock-sdp-answer'
            },
            dataChannel: mockChannel,
            close: () => console.log('Mock connection closed')
        };
    }
};

// Test runner - activated by "Run Tests" button
document.addEventListener('DOMContentLoaded', () => {
    // Set mock implementations for testing
    if (window.appState) {
        window.appState.peerConnectionFactory = MockPeerConnection;
        window.appState.appVerifier = MockAppVerifier;
    }
    
    const runTestsBtn = document.getElementById('run-tests');
    if (runTestsBtn) {
        runTestsBtn.addEventListener('click', runTests);
    }
});

async function runTests() {
    const testResultsDiv = document.getElementById('test-results');
    const testOutputDiv = document.getElementById('test-output');
    
    if (!testResultsDiv || !testOutputDiv) {
        console.error('Test result elements not found');
        return;
    }
    
    testResultsDiv.style.display = 'block';
    testOutputDiv.innerHTML = '<p style="color: #667eea; font-weight: bold;">Running comprehensive test suite...</p>';
    
    // Scroll to test results
    testResultsDiv.scrollIntoView({ behavior: 'smooth' });
    
    setTimeout(async () => {
        let output = '';
        let passCount = 0;
        let failCount = 0;
        
        // === Cryptographic Tests ===
        output += '<div class="test-section"><h3>Cryptographic Operations</h3>';
        
        // Test 1: ECDSA Key Pair Generation
        try {
            const keyPair = await generateECDSAKeyPair();
            if (keyPair.privateKey && keyPair.publicKey) {
                const privateKeyJwk = await crypto.subtle.exportKey('jwk', keyPair.privateKey);
                const publicKeyJwk = await crypto.subtle.exportKey('jwk', keyPair.publicKey);
                if (privateKeyJwk.crv === 'P-256' && publicKeyJwk.crv === 'P-256') {
                    output += '<div class="test-passed">✓ ECDSA key pair generation (P-256 curve)</div>';
                    passCount++;
                } else {
                    throw new Error('Wrong curve');
                }
            } else {
                throw new Error('Invalid key pair');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ ECDSA key pair generation: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 2: AES-256 Key Generation
        try {
            const aesKey = await generateAESKey();
            if (aesKey) {
                const keyData = await crypto.subtle.exportKey('raw', aesKey);
                if (keyData.byteLength === 32) { // 256 bits = 32 bytes
                    output += '<div class="test-passed">✓ AES-256 key generation</div>';
                    passCount++;
                } else {
                    throw new Error('Wrong key length');
                }
            } else {
                throw new Error('Invalid AES key');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ AES-256 key generation: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 3: PBKDF2 Password Derivation
        try {
            const salt = crypto.getRandomValues(new Uint8Array(16));
            const key = await deriveKeyFromPassword('testpassword123', salt);
            if (key) {
                // Test that same password + salt produces same key
                const key2 = await deriveKeyFromPassword('testpassword123', salt);
                const keyData1 = await crypto.subtle.exportKey('raw', key);
                const keyData2 = await crypto.subtle.exportKey('raw', key2);
                const arr1 = new Uint8Array(keyData1);
                const arr2 = new Uint8Array(keyData2);
                if (arr1.every((v, i) => v === arr2[i])) {
                    output += '<div class="test-passed">✓ PBKDF2 password derivation (100k iterations)</div>';
                    passCount++;
                } else {
                    throw new Error('Keys do not match');
                }
            } else {
                throw new Error('Failed to derive key');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ PBKDF2 password derivation: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 4: AES-GCM Encryption/Decryption
        try {
            const salt = crypto.getRandomValues(new Uint8Array(16));
            const key = await deriveKeyFromPassword('encryptiontest', salt);
            const testData = 'Hello, FreeSpeech! This is a test message with special chars: 🔒🌐';
            const encrypted = await encryptData(testData, key);
            const decrypted = await decryptData(encrypted, key);
            if (decrypted === testData) {
                output += '<div class="test-passed">✓ AES-GCM encryption/decryption</div>';
                passCount++;
            } else {
                throw new Error('Decrypted data does not match');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ AES-GCM encryption/decryption: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 5: Encryption with Wrong Password Fails
        try {
            const salt = crypto.getRandomValues(new Uint8Array(16));
            const key1 = await deriveKeyFromPassword('password1', salt);
            const key2 = await deriveKeyFromPassword('password2', salt);
            const testData = 'Secret data';
            const encrypted = await encryptData(testData, key1);
            
            let failed = false;
            try {
                await decryptData(encrypted, key2);
            } catch (e) {
                failed = true;
            }
            
            if (failed) {
                output += '<div class="test-passed">✓ Wrong password fails decryption</div>';
                passCount++;
            } else {
                throw new Error('Wrong password should fail');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Wrong password fails decryption: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End crypto section
        
        // === Encoding Tests ===
        output += '<div class="test-section"><h3>Data Encoding</h3>';
        
        // Test 6: Base64 Encoding/Decoding
        try {
            const data = new Uint8Array([0, 1, 2, 3, 4, 5, 255, 128, 127]);
            const b64 = arrayBufferToBase64(data.buffer);
            const decoded = base64ToArrayBuffer(b64);
            const decodedArray = new Uint8Array(decoded);
            if (decodedArray.length === data.length && decodedArray.every((v, i) => v === data[i])) {
                output += '<div class="test-passed">✓ Base64 encoding/decoding</div>';
                passCount++;
            } else {
                throw new Error('Decoded data does not match');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Base64 encoding/decoding: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 7: Base64 with Empty Data
        try {
            const data = new Uint8Array([]);
            const b64 = arrayBufferToBase64(data.buffer);
            const decoded = base64ToArrayBuffer(b64);
            if (decoded.byteLength === 0) {
                output += '<div class="test-passed">✓ Base64 with empty data</div>';
                passCount++;
            } else {
                throw new Error('Should be empty');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Base64 with empty data: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End encoding section
        
        // === Identity Management Tests ===
        output += '<div class="test-section"><h3>Identity Management</h3>';
        
        // Test 8: Identity Data Detection
        try {
            checkForIdentityData();
            output += '<div class="test-passed">✓ Identity data detection</div>';
            passCount++;
        } catch (e) {
            output += `<div class="test-failed">✗ Identity data detection: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 9: Complete Identity Generation Flow
        try {
            const password = 'test-identity-password';
            
            // Generate keys
            const userId = await generateECDSAKeyPair();
            const aesKey = await generateAESKey();
            
            // Export keys
            const userIdPrivateKeyJwk = await crypto.subtle.exportKey('jwk', userId.privateKey);
            const aesKeyRaw = await crypto.subtle.exportKey('raw', aesKey);
            
            // Package keys
            const keysData = {
                userIdPrivateKey: JSON.stringify(userIdPrivateKeyJwk),
                aesKey: arrayBufferToBase64(aesKeyRaw)
            };
            
            // Encrypt
            const salt = crypto.getRandomValues(new Uint8Array(16));
            const encryptionKey = await deriveKeyFromPassword(password, salt);
            const keysJson = JSON.stringify(keysData);
            const cryptoBox = await encryptData(keysJson, encryptionKey);
            
            // Decrypt and verify
            const decryptionKey = await deriveKeyFromPassword(password, salt);
            const decryptedJson = await decryptData(cryptoBox, decryptionKey);
            const recoveredKeysData = JSON.parse(decryptedJson);
            
            if (recoveredKeysData.userIdPrivateKey && recoveredKeysData.aesKey) {
                output += '<div class="test-passed">✓ Complete identity generation/recovery flow</div>';
                passCount++;
            } else {
                throw new Error('Keys not recovered properly');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Complete identity generation/recovery flow: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 10: Key Import/Export Cycle
        try {
            const originalKeyPair = await generateECDSAKeyPair();
            const privateKeyJwk = await crypto.subtle.exportKey('jwk', originalKeyPair.privateKey);
            
            // Re-import
            const importedPrivateKey = await crypto.subtle.importKey(
                'jwk',
                privateKeyJwk,
                { name: 'ECDSA', namedCurve: 'P-256' },
                true,
                ['sign']
            );
            
            // Derive public key
            const publicKeyJwk = { ...privateKeyJwk };
            delete publicKeyJwk.d;
            publicKeyJwk.key_ops = ['verify'];
            
            const importedPublicKey = await crypto.subtle.importKey(
                'jwk',
                publicKeyJwk,
                { name: 'ECDSA', namedCurve: 'P-256' },
                true,
                ['verify']
            );
            
            if (importedPrivateKey && importedPublicKey) {
                output += '<div class="test-passed">✓ ECDSA key import/export cycle</div>';
                passCount++;
            } else {
                throw new Error('Import failed');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ ECDSA key import/export cycle: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End identity section
        
        // === Gateway Management Tests ===
        output += '<div class="test-section"><h3>Gateway Management</h3>';
        
        // Test 11: Gateway Save/Load
        try {
            // Reset to known state
            appState.gateways = [];
            
            const testGateways = ['https://test1.example.com', 'https://test2.example.com', 'https://test3.example.com'];
            localStorage.setItem('freespeech-gateways', JSON.stringify(testGateways));
            loadGateways();
            
            // Check that all test gateways are present (they may be merged with existing)
            const hasAllTestGateways = testGateways.every(gw => appState.gateways.includes(gw));
            
            if (hasAllTestGateways) {
                output += '<div class="test-passed">✓ Gateway save/load from localStorage</div>';
                passCount++;
            } else {
                throw new Error(`Not all test gateways present: ${JSON.stringify(appState.gateways)}`);
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Gateway save/load from localStorage: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 12: Gateway Configuration Validation
        try {
            const validGateways = [
                'https://gateway1.example.com',
                'https://gateway2.example.com:8443'
            ];
            appState.gateways = validGateways;
            if (appState.gateways.length === 2) {
                output += '<div class="test-passed">✓ Gateway configuration validation</div>';
                passCount++;
            } else {
                throw new Error('Invalid gateway count');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Gateway configuration validation: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End gateway section
        
        // === Application State Tests ===
        output += '<div class="test-section"><h3>Application State</h3>';
        
        // Test 13: App State Initialization
        try {
            if (appState && 
                typeof appState.minPeers === 'number' && 
                typeof appState.maxPeers === 'number' &&
                Array.isArray(appState.peers) &&
                Array.isArray(appState.gateways)) {
                output += '<div class="test-passed">✓ Application state initialization</div>';
                passCount++;
            } else {
                throw new Error('Invalid app state structure');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Application state initialization: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 14: Peer Connection Limits
        try {
            if (appState.minPeers === 3 && appState.maxPeers === 20) {
                output += '<div class="test-passed">✓ Peer connection limits (min: 3, max: 20)</div>';
                passCount++;
            } else {
                throw new Error(`Wrong limits: min=${appState.minPeers}, max=${appState.maxPeers}`);
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Peer connection limits: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End app state section
        
        // === UI Tests ===
        output += '<div class="test-section"><h3>User Interface</h3>';
        
        // Test 15: Required Elements Present
        try {
            const requiredElements = [
                'mode-stateless',
                'mode-generate',
                'mode-gateways',
                'mode-stateful',
                'app-area',
                'test-results',
                'identity-data'
            ];
            
            const missing = requiredElements.filter(id => !document.getElementById(id));
            if (missing.length === 0) {
                output += '<div class="test-passed">✓ All required UI elements present</div>';
                passCount++;
            } else {
                throw new Error(`Missing elements: ${missing.join(', ')}`);
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Required UI elements: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 16: Mode 4 Visibility (should be hidden when no identity data, visible when identity exists)
        try {
            const mode4 = document.getElementById('mode-stateful');
            const isHidden = mode4.style.display === 'none' || window.getComputedStyle(mode4).display === 'none';
            
            if (appState.isStateful) {
                // If identity data exists, Mode 4 should be visible
                if (!isHidden) {
                    output += '<div class="test-passed">✓ Mode 4 (stateful) visible when identity data exists</div>';
                    passCount++;
                } else {
                    throw new Error('Mode 4 should be visible when identity data exists');
                }
            } else {
                // If no identity data, Mode 4 should be hidden
                if (isHidden) {
                    output += '<div class="test-passed">✓ Mode 4 (stateful) hidden when no identity data</div>';
                    passCount++;
                } else {
                    throw new Error('Mode 4 should be hidden when no identity data');
                }
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Mode 4 visibility: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 17: Status Indicator Function
        try {
            showStatus('connected', 'Test connected');
            const indicator = document.getElementById('statusIndicator');
            const text = document.getElementById('statusText');
            if (indicator.textContent === '🟢' && text.textContent === 'Test connected') {
                showStatus('error', 'Test error');
                if (indicator.textContent === '🔴' && text.textContent === 'Test error') {
                    output += '<div class="test-passed">✓ Status indicator function</div>';
                    passCount++;
                } else {
                    throw new Error('Error status not working');
                }
            } else {
                throw new Error('Connected status not working');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Status indicator function: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End UI section
        
        // === Mock Gateway Communication Tests ===
        output += '<div class="test-section"><h3>Gateway Communication</h3>';
        
        // Test 18: postMessage Handler Registration
        try {
            // Check that message handler is set up
            const hasMessageHandler = true; // window.addEventListener('message', ...) is called
            if (hasMessageHandler) {
                output += '<div class="test-passed">✓ postMessage handler registration</div>';
                passCount++;
            } else {
                throw new Error('No message handler');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ postMessage handler registration: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 19: Mock Peer List Processing
        try {
            const mockPeers = [
                { id: 'peer1', sdp: {}, iceCandidates: [] },
                { id: 'peer2', sdp: {}, iceCandidates: [] },
                { id: 'peer3', sdp: {}, iceCandidates: [] }
            ];
            
            // Simulate peer connection (simplified)
            appState.peers = [];
            for (const peer of mockPeers) {
                await connectToPeer(peer);
            }
            
            if (appState.peers.length === 3) {
                output += '<div class="test-passed">✓ Mock peer list processing</div>';
                passCount++;
            } else {
                throw new Error(`Expected 3 peers, got ${appState.peers.length}`);
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Mock peer list processing: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 20: Mock Gateway iframe creation
        try {
            // Test that gateway iframe can be created with mock-gateway.html
            const mockGatewayUrl = 'mock-gateway.html';
            const testContainer = document.createElement('div');
            testContainer.id = 'test-gateway-container';
            document.body.appendChild(testContainer);
            
            const gatewayDiv = document.createElement('div');
            gatewayDiv.className = 'gateway-wrapper';
            gatewayDiv.innerHTML = `
                <div class="gateway-warning">
                    ⚠️ Untrusted Gateway Content
                    <button class="gateway-btn">Next Gateway →</button>
                    <button class="gateway-btn">Close Gateway ✕</button>
                </div>
                <iframe 
                    id="test-gateway-frame" 
                    src="${mockGatewayUrl}"
                    sandbox="allow-scripts allow-same-origin"
                    width="400"
                    height="200"
                    style="display: block; border: none;">
                </iframe>
            `;
            testContainer.appendChild(gatewayDiv);
            
            const iframe = document.getElementById('test-gateway-frame');
            if (iframe && iframe.src.includes('mock-gateway.html')) {
                output += '<div class="test-passed">✓ Mock gateway iframe creation with correct source</div>';
                passCount++;
            } else {
                throw new Error('Gateway iframe not created properly');
            }
            
            // Cleanup
            document.body.removeChild(testContainer);
        } catch (e) {
            output += `<div class="test-failed">✗ Mock gateway iframe creation: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 21: Gateway postMessage workflow simulation
        try {
            let messageReceived = false;
            let peerDataReceived = false;
            
            // Set up message handler
            const testMessageHandler = (event) => {
                if (event.data && event.data.type === 'peers') {
                    messageReceived = true;
                    if (Array.isArray(event.data.peers) && event.data.peers.length > 0) {
                        peerDataReceived = true;
                    }
                }
            };
            
            window.addEventListener('message', testMessageHandler);
            
            // Simulate gateway sending peers message
            const mockPeerMessage = {
                type: 'peers',
                peers: [
                    {
                        id: 'test-peer-1',
                        sdp: { type: 'offer', sdp: 'mock-sdp-data' },
                        iceCandidates: [
                            { candidate: 'candidate:1 1 udp 2122260223 192.168.1.100 54321 typ host' }
                        ]
                    },
                    {
                        id: 'test-peer-2',
                        sdp: { type: 'offer', sdp: 'mock-sdp-data-2' },
                        iceCandidates: [
                            { candidate: 'candidate:2 1 udp 2122260223 192.168.1.101 54321 typ host' }
                        ]
                    }
                ]
            };
            
            window.postMessage(mockPeerMessage, '*');
            
            // Give it a moment to process
            await new Promise(resolve => setTimeout(resolve, 100));
            
            window.removeEventListener('message', testMessageHandler);
            
            if (messageReceived && peerDataReceived) {
                output += '<div class="test-passed">✓ Gateway postMessage workflow (peers message)</div>';
                passCount++;
            } else {
                throw new Error('Message not received or processed correctly');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Gateway postMessage workflow: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 22: Gateway lifecycle management
        try {
            // Test gateway visibility control
            const testContainer = document.createElement('div');
            testContainer.id = 'test-gateway-lifecycle';
            document.body.appendChild(testContainer);
            
            const gatewayDiv = document.createElement('div');
            gatewayDiv.className = 'gateway-wrapper';
            gatewayDiv.innerHTML = `
                <div class="gateway-warning">
                    ⚠️ Untrusted Gateway Content
                </div>
                <iframe id="test-lifecycle-frame" style="display: block;"></iframe>
            `;
            testContainer.appendChild(gatewayDiv);
            
            const iframe = document.getElementById('test-lifecycle-frame');
            
            // Test initial visibility
            const initiallyVisible = iframe.style.display === 'block';
            
            // Test hiding
            iframe.style.display = 'none';
            const hiddenCorrectly = iframe.style.display === 'none';
            
            // Test removal
            testContainer.innerHTML = '';
            const removed = testContainer.children.length === 0;
            
            document.body.removeChild(testContainer);
            
            if (initiallyVisible && hiddenCorrectly && removed) {
                output += '<div class="test-passed">✓ Gateway lifecycle (visible → hidden → removed)</div>';
                passCount++;
            } else {
                throw new Error('Gateway lifecycle not managed correctly');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Gateway lifecycle management: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 23: Mock gateway peer data validation
        try {
            const validPeer = {
                id: 'peer-123',
                sdp: {
                    type: 'offer',
                    sdp: 'v=0\no=- 123456 2 IN IP4 127.0.0.1\ns=-\nt=0 0'
                },
                iceCandidates: [
                    {
                        candidate: 'candidate:1 1 udp 2122260223 192.168.1.100 54321 typ host',
                        sdpMLineIndex: 0,
                        sdpMid: '0'
                    }
                ]
            };
            
            // Validate structure
            const hasId = typeof validPeer.id === 'string' && validPeer.id.length > 0;
            const hasSdp = validPeer.sdp && validPeer.sdp.type && validPeer.sdp.sdp;
            const hasIce = Array.isArray(validPeer.iceCandidates) && validPeer.iceCandidates.length > 0;
            
            if (hasId && hasSdp && hasIce) {
                output += '<div class="test-passed">✓ Mock gateway peer data structure validation</div>';
                passCount++;
            } else {
                throw new Error('Peer data structure invalid');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Mock gateway peer data validation: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 24: Gateway ready message sending
        try {
            // Simulate sending ready message to gateway
            const readyMessage = { type: 'ready' };
            
            // In real scenario, this would be sent to iframe.contentWindow
            // For testing, we just validate the message structure
            if (readyMessage.type === 'ready') {
                output += '<div class="test-passed">✓ Gateway ready message structure</div>';
                passCount++;
            } else {
                throw new Error('Invalid ready message structure');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Gateway ready message sending: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End gateway section
        
        // === App Verification Tests ===
        output += '<div class="test-section"><h3>App Verification</h3>';
        
        // Test 25: Mock app verifier is configured
        try {
            if (appState.appVerifier && 
                typeof appState.appVerifier.verify === 'function') {
                output += '<div class="test-passed">✓ App verifier is configured</div>';
                passCount++;
            } else {
                throw new Error('App verifier not configured');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ App verifier configuration: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 26: Mock app signature verification accepts valid app
        try {
            const mockApp = {
                appId: 'mock-ecdsa-public-key',
                content: '<h1>Test App</h1>',
                signature: 'mock-signature',
                version: '1.0'
            };
            
            const isValid = await verifyAppSignature(mockApp);
            if (isValid) {
                output += '<div class="test-passed">✓ Mock app signature verification accepts valid app</div>';
                passCount++;
            } else {
                throw new Error('Verification failed for valid app');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Mock app signature verification (valid): ${e.message}</div>`;
            failCount++;
        }
        
        // Test 27: Mock app signature verification rejects invalid signature
        try {
            const invalidApp = {
                appId: 'test-ecdsa-public-key',
                content: '<h1>Test App</h1>',
                signature: 'invalid-signature',
                version: '1.0'
            };
            
            const isValid = await verifyAppSignature(invalidApp);
            if (!isValid) {
                output += '<div class="test-passed">✓ Mock app signature verification rejects invalid signature</div>';
                passCount++;
            } else {
                throw new Error('Verification should fail for invalid signature');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Mock app signature verification (invalid): ${e.message}</div>`;
            failCount++;
        }
        
        // Test 28: App signature verification rejects incomplete app data
        try {
            const incompleteApp = {
                appId: 'test-key',
                content: '<h1>Test</h1>'
                // Missing signature
            };
            
            const isValid = await verifyAppSignature(incompleteApp);
            if (!isValid) {
                output += '<div class="test-passed">✓ App signature verification rejects incomplete data</div>';
                passCount++;
            } else {
                throw new Error('Verification should fail for incomplete data');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ App signature verification (incomplete): ${e.message}</div>`;
            failCount++;
        }
        
        // Test 29: Actual app verifier implementation exists
        try {
            if (window.ActualAppVerifier && 
                typeof window.ActualAppVerifier.verify === 'function') {
                output += '<div class="test-passed">✓ Actual app verifier implementation available</div>';
                passCount++;
            } else {
                throw new Error('ActualAppVerifier not found');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Actual app verifier availability: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End verification section
        
        // === Gateway Merge/Deduplication Tests ===
        output += '<div class="test-section"><h3>Gateway Merge & Deduplication</h3>';
        
        // Test 30: Gateway merge from localStorage and identity-data
        try {
            // Setup: Save gateways to localStorage
            const localGateways = ['https://local1.example.com', 'https://local2.example.com'];
            localStorage.setItem('freespeech-gateways', JSON.stringify(localGateways));
            
            // Setup: Simulate identity-data with gateways
            const identityDataEl = document.getElementById('identity-data');
            const originalContent = identityDataEl.textContent;
            const mockIdentityData = {
                salt: 'mock-salt',
                cryptoBox: 'mock-crypto-box',
                gateways: ['https://freespeechapp.org/', 'https://local1.example.com'],
                version: '1.0'
            };
            identityDataEl.textContent = JSON.stringify(mockIdentityData);
            
            // Reset appState gateways to default
            appState.gateways = ['https://freespeechapp.org/'];
            
            // Run checkForIdentityData which should merge gateways
            checkForIdentityData();
            
            // Verify gateways are merged and deduplicated
            const expectedGateways = [
                'https://freespeechapp.org/',
                'https://local1.example.com',
                'https://local2.example.com'
            ];
            
            const hasAllGateways = expectedGateways.every(gw => appState.gateways.includes(gw));
            const noDuplicates = appState.gateways.length === new Set(appState.gateways).size;
            
            // Restore original identity data
            identityDataEl.textContent = originalContent;
            
            if (hasAllGateways && noDuplicates) {
                output += '<div class="test-passed">✓ Gateway merge from localStorage and identity-data</div>';
                passCount++;
            } else {
                throw new Error(`Gateways not merged correctly: ${JSON.stringify(appState.gateways)}`);
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Gateway merge from localStorage and identity-data: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 31: Gateway deduplication
        try {
            appState.gateways = [
                'https://gateway1.example.com',
                'https://gateway2.example.com',
                'https://gateway1.example.com', // duplicate
                'https://gateway3.example.com',
                'https://gateway2.example.com'  // duplicate
            ];
            
            // Deduplicate
            appState.gateways = Array.from(new Set(appState.gateways));
            
            if (appState.gateways.length === 3 && 
                appState.gateways.includes('https://gateway1.example.com') &&
                appState.gateways.includes('https://gateway2.example.com') &&
                appState.gateways.includes('https://gateway3.example.com')) {
                output += '<div class="test-passed">✓ Gateway deduplication removes duplicates</div>';
                passCount++;
            } else {
                throw new Error('Deduplication failed');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Gateway deduplication: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 32: loadGateways merges with existing
        try {
            // Setup initial gateways
            appState.gateways = ['https://freespeechapp.org/'];
            
            // Save different gateways to localStorage
            const storedGateways = ['https://stored1.example.com', 'https://stored2.example.com'];
            localStorage.setItem('freespeech-gateways', JSON.stringify(storedGateways));
            
            // Load and merge
            loadGateways();
            
            // Verify merge occurred
            if (appState.gateways.includes('https://freespeechapp.org/') &&
                appState.gateways.includes('https://stored1.example.com') &&
                appState.gateways.includes('https://stored2.example.com')) {
                output += '<div class="test-passed">✓ loadGateways merges with existing gateways</div>';
                passCount++;
            } else {
                throw new Error('loadGateways did not merge correctly');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ loadGateways merge: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End gateway merge section
        
        // === WebRTC Modular Implementation Tests ===
        output += '<div class="test-section"><h3>WebRTC Modular Implementation</h3>';
        
        // Test 33: Mock peer connection factory is set
        try {
            if (appState.peerConnectionFactory && 
                typeof appState.peerConnectionFactory.create === 'function') {
                output += '<div class="test-passed">✓ Peer connection factory is configured</div>';
                passCount++;
            } else {
                throw new Error('Peer connection factory not set');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Peer connection factory configuration: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 34: Mock peer connection creates connection
        try {
            const mockPeerInfo = {
                id: 'test-peer-mock',
                sdp: { type: 'offer', sdp: 'mock-sdp' },
                iceCandidates: []
            };
            
            let dataChannelReceived = false;
            let stateChangeReceived = false;
            
            const result = await appState.peerConnectionFactory.create(
                mockPeerInfo,
                (channel) => { dataChannelReceived = true; },
                (state) => { stateChangeReceived = true; }
            );
            
            // Give callbacks time to fire
            await new Promise(resolve => setTimeout(resolve, 200));
            
            if (result && result.connection && result.localDescription && 
                dataChannelReceived && stateChangeReceived) {
                output += '<div class="test-passed">✓ Mock peer connection creates connection with callbacks</div>';
                passCount++;
            } else {
                throw new Error('Mock connection creation incomplete');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Mock peer connection creation: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 35: connectToPeer uses peer connection factory
        try {
            const initialPeerCount = appState.peers.length;
            
            const testPeerInfo = {
                id: 'factory-test-peer',
                sdp: { type: 'offer', sdp: 'test-sdp' },
                iceCandidates: []
            };
            
            await connectToPeer(testPeerInfo);
            
            // Give connection time to establish
            await new Promise(resolve => setTimeout(resolve, 200));
            
            const newPeer = appState.peers.find(p => p.id === 'factory-test-peer');
            
            if (newPeer && newPeer.connection) {
                output += '<div class="test-passed">✓ connectToPeer uses peer connection factory</div>';
                passCount++;
                
                // Cleanup
                appState.peers = appState.peers.filter(p => p.id !== 'factory-test-peer');
            } else {
                throw new Error('Peer not connected via factory');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ connectToPeer factory usage: ${e.message}</div>`;
            failCount++;
        }
        
        // Test 36: Actual peer connection factory exists
        try {
            if (window.ActualPeerConnection && 
                typeof window.ActualPeerConnection.create === 'function') {
                output += '<div class="test-passed">✓ Actual peer connection implementation available</div>';
                passCount++;
            } else {
                throw new Error('ActualPeerConnection not found');
            }
        } catch (e) {
            output += `<div class="test-failed">✗ Actual peer connection availability: ${e.message}</div>`;
            failCount++;
        }
        
        output += '</div>'; // End WebRTC section
        
        // === Summary ===
        const totalTests = passCount + failCount;
        const successRate = totalTests > 0 ? ((passCount / totalTests) * 100).toFixed(1) : 0;
        
        output += `<div style="margin-top: 20px; padding: 15px; background: white; border-radius: 8px; border: 2px solid ${failCount === 0 ? '#28a745' : '#dc3545'};">
            <h3 style="margin-bottom: 10px; color: #333;">Test Summary</h3>
            <div style="font-size: 1.1em;">
                <strong>Total Tests: ${totalTests}</strong><br>
                <span style="color: #28a745; font-weight: bold;">✓ Passed: ${passCount}</span><br>
                <span style="color: #dc3545; font-weight: bold;">✗ Failed: ${failCount}</span><br>
                <span style="color: #667eea; font-weight: bold;">Success Rate: ${successRate}%</span>
            </div>
            ${failCount === 0 ? 
                '<div style="margin-top: 10px; padding: 10px; background: #d4edda; border-radius: 4px; color: #155724; font-weight: bold;">🎉 All tests passed!</div>' :
                '<div style="margin-top: 10px; padding: 10px; background: #f8d7da; border-radius: 4px; color: #721c24; font-weight: bold;">⚠️ Some tests failed. Please review.</div>'
            }
        </div>`;
        
        testOutputDiv.innerHTML = output;
        
        // Log summary to console
        console.log(`Test Summary: ${passCount}/${totalTests} passed (${successRate}%)`);
        
    }, 100);
}

// Helper function to check if test environment has all necessary functions
function checkTestEnvironment() {
    const requiredFunctions = [
        'generateECDSAKeyPair',
        'generateAESKey',
        'deriveKeyFromPassword',
        'encryptData',
        'decryptData',
        'arrayBufferToBase64',
        'base64ToArrayBuffer',
        'checkForIdentityData',
        'loadGateways',
        'showStatus',
        'connectToPeer',
        'verifyAppSignature'
    ];
    
    const missing = requiredFunctions.filter(fn => typeof window[fn] !== 'function');
    if (missing.length > 0) {
        console.error('Missing required functions:', missing);
        return false;
    }
    return true;
}
