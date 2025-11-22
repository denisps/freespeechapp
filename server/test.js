#!/usr/bin/env node
// Simple test script for FreeSpeechApp server

const https = require('https');
const http = require('http');

// Test configuration
const TEST_HOST = 'localhost';
const TEST_PORT = process.env.PORT || 443;
const USE_HTTPS = process.env.USE_HTTPS !== 'false';

let passedTests = 0;
let failedTests = 0;

// Helper to make requests
function makeRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: TEST_HOST,
      port: TEST_PORT,
      path: path,
      method: method,
      headers: data ? { 'Content-Type': 'application/json' } : {},
      rejectUnauthorized: false // Allow self-signed certs
    };
    
    const client = USE_HTTPS ? https : http;
    const req = client.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const json = path === '/' ? body : JSON.parse(body);
          resolve({ status: res.statusCode, data: json, headers: res.headers });
        } catch (e) {
          resolve({ status: res.statusCode, data: body, headers: res.headers });
        }
      });
    });
    
    req.on('error', reject);
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

// Test functions
async function testHomePage() {
  try {
    const res = await makeRequest('/');
    if (res.status === 200 && res.data.includes('FreeSpeechApp')) {
      console.log('✓ Home page loads correctly');
      passedTests++;
      return true;
    } else {
      console.log('✗ Home page failed:', res.status);
      failedTests++;
      return false;
    }
  } catch (err) {
    console.log('✗ Home page error:', err.message);
    failedTests++;
    return false;
  }
}

async function testHealthEndpoint() {
  try {
    const res = await makeRequest('/health');
    if (res.status === 200 && res.data.status === 'healthy') {
      console.log('✓ Health endpoint works');
      passedTests++;
      return true;
    } else {
      console.log('✗ Health endpoint failed:', res.status);
      failedTests++;
      return false;
    }
  } catch (err) {
    console.log('✗ Health endpoint error:', err.message);
    failedTests++;
    return false;
  }
}

async function testAPIDisabled() {
  try {
    const res = await makeRequest('/connect', 'POST');
    if (res.status === 503 && res.data.error) {
      console.log('✓ API endpoints are correctly disabled');
      passedTests++;
      return true;
    } else {
      console.log('✗ API should be disabled but got:', res.status);
      failedTests++;
      return false;
    }
  } catch (err) {
    console.log('✗ API disabled test error:', err.message);
    failedTests++;
    return false;
  }
}

// Run all tests
async function runTests() {
  console.log('');
  console.log('FreeSpeechApp Server Tests');
  console.log('==========================');
  console.log(`Testing: ${USE_HTTPS ? 'https' : 'http'}://${TEST_HOST}:${TEST_PORT}`);
  console.log('');
  
  await testHomePage();
  await testHealthEndpoint();
  await testAPIDisabled();
  
  console.log('');
  console.log('==========================');
  console.log(`Tests passed: ${passedTests}`);
  console.log(`Tests failed: ${failedTests}`);
  console.log('==========================');
  console.log('');
  
  process.exit(failedTests > 0 ? 1 : 0);
}

// Wait for server to be ready
setTimeout(runTests, 1000);
