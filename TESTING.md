# FreeSpeechApp Test Suite

Comprehensive test coverage for the FreeSpeechApp deployment and server infrastructure.

## Test Suites

### 1. Server Tests (`server/test.js`)
Tests the core server functionality:
- **Home page loading** - Verifies the server serves index.html correctly
- **Health endpoint** - Tests the `/health` API endpoint
- **API disabled state** - Confirms API endpoints return 503 when disabled

**Run server tests:**
```bash
cd server
USE_HTTPS=false HTTP_PORT=8080 node server.js &
USE_HTTPS=false PORT=8080 npm test
kill %1
```

### 2. Admin Deploy Tests (`test-admin-deploy.sh`)
Tests the admin deployment script (`admin-deploy.sh`):
- Configuration file handling
- Config validation (required fields)
- Local deployment mode detection
- Remote deployment configuration
- Custom config file paths
- Bootstrap script references

**Run admin deploy tests:**
```bash
./test-admin-deploy.sh
```

**Coverage:** 18 test cases

### 3. Bootstrap Tests (`test-bootstrap.sh`)
Tests all bootstrap installation scripts:
- Script existence and executability
- Function structure and completeness
- Configuration variables
- Platform-specific implementations (Ubuntu, CentOS, Fedora, macOS)
- Certificate generation (100-year validity)
- Systemd service configuration
- Firewall setup
- Node.js installation
- Error handling

**Run bootstrap tests:**
```bash
./test-bootstrap.sh
```

**Coverage:** 70 test cases

## Running All Tests

Use the master test runner to execute all test suites:

```bash
./run-all-tests.sh
```

This will:
1. Start the server and run server tests
2. Run admin-deploy tests
3. Run bootstrap tests
4. Display a summary of results

## Test Results

```
Test Suites: 3
Total Tests: 91 (3 server + 18 admin-deploy + 70 bootstrap)
Status: ✓ All tests passing
```

## Test Structure

```
freespeechapp/
├── server/
│   └── test.js              # Server functionality tests
├── test-admin-deploy.sh     # Admin deployment script tests
├── test-bootstrap.sh        # Bootstrap scripts tests
├── run-all-tests.sh         # Master test runner
└── TESTING.md              # This file
```

## Test Output

All tests use colored output:
- ✓ **Green** - Test passed
- ✗ **Red** - Test failed
- **Yellow** - Section headers
- **Blue** - Suite information

## Requirements

- **Bash** 4.0+
- **Node.js** 18+
- **Standard Unix tools** (grep, sed, cat, etc.)

## CI/CD Integration

The test suite can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run tests
  run: ./run-all-tests.sh
```

## Test Categories

### Functional Tests
- Server endpoints (3 tests)
- Configuration loading (11 tests)
- Script execution logic (25 tests)

### Structural Tests
- File existence (14 tests)
- Function definitions (20 tests)
- Variable declarations (12 tests)

### Integration Tests
- Bootstrap flow (10 tests)
- Config validation (6 tests)

## Adding New Tests

To add new tests:

1. **For server tests:** Edit `server/test.js`
2. **For admin-deploy:** Add test functions to `test-admin-deploy.sh`
3. **For bootstrap:** Add test functions to `test-bootstrap.sh`

Follow the existing test pattern:
```bash
test_my_new_feature() {
    echo "Test N: Description"
    echo "===================="
    
    # Test code here
    assert_equal "expected" "actual" "Test message"
}
```

## Troubleshooting

**Tests fail with "command not found":**
- Ensure scripts are executable: `chmod +x *.sh`

**Server tests fail with connection errors:**
- Check if port 8080 is available
- Ensure server starts properly before tests run

**Bootstrap tests fail:**
- Verify all bootstrap scripts exist in `bootstrap/` directory
- Check file permissions

## License

Same as the main project (see LICENSE file).
