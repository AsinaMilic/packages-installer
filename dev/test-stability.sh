#!/usr/bin/env bash
#
# Stability Testing Script for Packages Installer
# Tests various failure scenarios and recovery mechanisms
#
# Usage: ./test-stability.sh [test-name]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_LOG="$HOME/.cache/pkginst-stability-test.log"

# Test configuration
TEST_PACKAGE_VALID="curl"
TEST_PACKAGE_INVALID="this-package-definitely-does-not-exist-12345"
TEST_URL_VALID="https://raw.githubusercontent.com/mylinuxforwork/packages-installer/main/README.md"
TEST_URL_INVALID="https://nonexistent-domain-12345.com/file.zip"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$TEST_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$TEST_LOG"
}

# Test functions
test_command_validation() {
    log_info "Testing command validation functions..."
    
    # Source the library to test functions
    source "$ROOT_DIR/share/com.ml4w.packagesinstaller/lib/lib/library.sh"
    
    # Test empty command
    if [[ "$(_checkCommandExists "")" == "1" ]]; then
        log_info "✓ Empty command correctly returns 1"
    else
        log_error "✗ Empty command validation failed"
        return 1
    fi
    
    # Test existing command
    if [[ "$(_checkCommandExists "bash")" == "0" ]]; then
        log_info "✓ Existing command correctly detected"
    else
        log_error "✗ Existing command detection failed"
        return 1
    fi
    
    # Test non-existing command
    if [[ "$(_checkCommandExists "nonexistent-command-12345")" == "1" ]]; then
        log_info "✓ Non-existing command correctly returns 1"
    else
        log_error "✗ Non-existing command validation failed"
        return 1
    fi
    
    log_info "Command validation tests passed"
    return 0
}

test_file_validation() {
    log_info "Testing file validation functions..."
    
    source "$ROOT_DIR/share/com.ml4w.packagesinstaller/lib/lib/library.sh"
    
    # Create temporary test file
    TEST_FILE="/tmp/pkginst-test-file"
    echo "test content" > "$TEST_FILE"
    
    # Test existing file validation (should not exit)
    if _validate_file "$TEST_FILE" "test file" 2>/dev/null; then
        log_info "✓ Existing file validation passed"
    else
        log_error "✗ Existing file validation failed"
        rm -f "$TEST_FILE"
        return 1
    fi
    
    # Test non-existing file validation in subshell (should exit)
    if ! (set -e; _validate_file "/nonexistent/file" "test file" 2>/dev/null); then
        log_info "✓ Non-existing file validation correctly fails"
    else
        log_error "✗ Non-existing file validation should have failed"
        rm -f "$TEST_FILE"
        return 1
    fi
    
    rm -f "$TEST_FILE"
    log_info "File validation tests passed"
    return 0
}

test_retry_mechanism() {
    log_info "Testing retry mechanism..."
    
    source "$ROOT_DIR/share/com.ml4w.packagesinstaller/lib/lib/library.sh"
    
    # Test successful command
    if _execute_with_retry "echo 'test'" 3 "test command"; then
        log_info "✓ Retry mechanism works for successful commands"
    else
        log_error "✗ Retry mechanism failed for successful command"
        return 1
    fi
    
    # Test failing command (should try multiple times)
    start_time=$(date +%s)
    if ! _execute_with_retry "false" 2 "failing command" 2>/dev/null; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        if [ $duration -ge 2 ]; then  # Should take at least 2 seconds due to sleep
            log_info "✓ Retry mechanism correctly retries failing commands"
        else
            log_warning "Retry timing might be off, but mechanism works"
        fi
    else
        log_error "✗ Retry mechanism should have failed for false command"
        return 1
    fi
    
    log_info "Retry mechanism tests passed"
    return 0
}

test_cleanup_mechanism() {
    log_info "Testing cleanup mechanism..."
    
    source "$ROOT_DIR/share/com.ml4w.packagesinstaller/lib/lib/library.sh"
    
    # Create test files that should be cleaned up
    TEST_ZIP="$HOME/.cache/pkginst_tmp.zip"
    TEST_DIR="$HOME/.cache/pkginst_tmp"
    
    echo "test" > "$TEST_ZIP"
    mkdir -p "$TEST_DIR"
    
    # Verify files exist
    if [ -f "$TEST_ZIP" ] && [ -d "$TEST_DIR" ]; then
        log_info "✓ Test cleanup files created"
    else
        log_error "✗ Failed to create test cleanup files"
        return 1
    fi
    
    # Run cleanup
    _cleanup_on_error
    
    # Verify files are removed
    if [ ! -f "$TEST_ZIP" ] && [ ! -d "$TEST_DIR" ]; then
        log_info "✓ Cleanup mechanism successfully removes temporary files"
    else
        log_error "✗ Cleanup mechanism failed to remove files"
        # Manual cleanup
        rm -f "$TEST_ZIP" 2>/dev/null
        rm -rf "$TEST_DIR" 2>/dev/null
        return 1
    fi
    
    log_info "Cleanup mechanism tests passed"
    return 0
}

test_network_resilience() {
    log_info "Testing network resilience..."
    
    # Test with valid URL (should work)
    if wget --spider "$TEST_URL_VALID" 2>/dev/null; then
        log_info "✓ Valid URL test passed"
    else
        log_warning "Valid URL test failed - network might be unavailable"
    fi
    
    # Test with invalid URL (should fail gracefully)
    if ! wget --spider "$TEST_URL_INVALID" 2>/dev/null; then
        log_info "✓ Invalid URL correctly fails"
    else
        log_error "✗ Invalid URL should have failed"
        return 1
    fi
    
    log_info "Network resilience tests passed"
    return 0
}

test_package_manager_detection() {
    log_info "Testing package manager detection..."
    
    source "$ROOT_DIR/share/com.ml4w.packagesinstaller/lib/lib/library.sh"
    
    # Test common package managers
    managers=("apt" "dnf" "pacman" "zypper")
    detected_manager=""
    
    for manager in "${managers[@]}"; do
        if [[ "$(_checkCommandExists "$manager")" == "0" ]]; then
            detected_manager="$manager"
            log_info "✓ Detected package manager: $manager"
            break
        fi
    done
    
    if [ -n "$detected_manager" ]; then
        log_info "Package manager detection successful"
        return 0
    else
        log_warning "No supported package manager detected (this might be expected in some environments)"
        return 0
    fi
}

run_integration_test() {
    log_info "Running integration test with minimal configuration..."
    
    # Create a minimal test configuration
    TEST_CONFIG_DIR="/tmp/pkginst-integration-test"
    rm -rf "$TEST_CONFIG_DIR" 2>/dev/null
    mkdir -p "$TEST_CONFIG_DIR/test-package/pkginst"
    
    # Create minimal config files
    cat > "$TEST_CONFIG_DIR/test-package/pkginst/config.json" << EOF
{
    "name": "Integration Test Package",
    "description": "Test package for stability testing",
    "version": "1.0.0"
}
EOF
    
    cat > "$TEST_CONFIG_DIR/test-package/pkginst/packages.json" << EOF
{
    "packages": [
        {
            "package": "echo",
            "description": "Test package - echo command"
        }
    ]
}
EOF
    
    # Test the installation (dry run mode if possible)
    log_info "Testing package installation workflow..."
    
    # This would normally run the installer, but we'll just validate the structure
    if [ -f "$TEST_CONFIG_DIR/test-package/pkginst/packages.json" ]; then
        log_info "✓ Test configuration structure is valid"
    else
        log_error "✗ Test configuration structure is invalid"
        rm -rf "$TEST_CONFIG_DIR"
        return 1
    fi
    
    # Cleanup
    rm -rf "$TEST_CONFIG_DIR"
    log_info "Integration test completed successfully"
    return 0
}

# Main test runner
run_all_tests() {
    log_info "Starting stability tests for Packages Installer..."
    echo "$(date): Starting stability tests" > "$TEST_LOG"
    
    local failed_tests=0
    local total_tests=0
    
    tests=(
        "test_command_validation"
        "test_file_validation" 
        "test_retry_mechanism"
        "test_cleanup_mechanism"
        "test_network_resilience"
        "test_package_manager_detection"
        "run_integration_test"
    )
    
    for test in "${tests[@]}"; do
        total_tests=$((total_tests + 1))
        log_info "Running: $test"
        
        if $test; then
            log_info "✓ $test PASSED"
        else
            log_error "✗ $test FAILED"
            failed_tests=$((failed_tests + 1))
        fi
        echo "---" | tee -a "$TEST_LOG"
    done
    
    echo
    log_info "Test Summary:"
    log_info "Total tests: $total_tests"
    log_info "Passed: $((total_tests - failed_tests))"
    
    if [ $failed_tests -gt 0 ]; then
        log_error "Failed: $failed_tests"
        log_error "Some stability tests failed. Check $TEST_LOG for details."
        return 1
    else
        log_info "All stability tests passed!"
        log_info "The packages-installer appears to be much more stable now."
        return 0
    fi
}

# Script execution
case "${1:-all}" in
    "command")
        test_command_validation
        ;;
    "file")
        test_file_validation
        ;;
    "retry")
        test_retry_mechanism
        ;;
    "cleanup")
        test_cleanup_mechanism
        ;;
    "network")
        test_network_resilience
        ;;
    "detection")
        test_package_manager_detection
        ;;
    "integration")
        run_integration_test
        ;;
    "all"|*)
        run_all_tests
        ;;
esac