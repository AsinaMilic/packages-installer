#!/bin/bash

# Test script to verify packages-installer fixes

set -e

echo "=== Testing packages-installer fixes ==="
echo

# Create test configuration directory
TEST_DIR="test-config-dir"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Create a test config.json
cat > "$TEST_DIR/config.json" << 'EOF'
{
    "name": "Test Config",
    "id": "test-config",
    "author": "Test Author",
    "desc": "Test configuration for packages-installer",
    "version": "1.0.0",
    "repository": "https://github.com/test/test"
}
EOF

# Create a test packages.json
cat > "$TEST_DIR/packages.json" << 'EOF'
{
    "packages": [
        {
            "package": "htop",
            "pacman": "htop",
            "apt": "htop",
            "dnf": "htop",
            "zypper": "htop"
        },
        {
            "package": "neofetch",
            "pacman": "neofetch",
            "apt": "neofetch",
            "dnf": "neofetch",
            "zypper": "neofetch"
        }
    ]
}
EOF

echo "Test 1: Help command"
echo "--------------------"
packages-installer --help
echo

echo "Test 2: Direct config directory (no package name)"
echo "-------------------------------------------------"
packages-installer -s ./$TEST_DIR -i
echo

echo "Test 3: Direct config directory with absolute path"
echo "--------------------------------------------------"
packages-installer -s "$(pwd)/$TEST_DIR" -i
echo

echo "Test 4: Traditional structure"
echo "-----------------------------"
# Create traditional structure
TRAD_DIR="test-parent"
rm -rf "$TRAD_DIR"
mkdir -p "$TRAD_DIR/my-project/pkginst"
cp "$TEST_DIR"/* "$TRAD_DIR/my-project/pkginst/"

packages-installer -s ./$TRAD_DIR my-project -i
echo

echo "Test 5: Already installed package"
echo "---------------------------------"
# First install it
packages-installer -s ./$TEST_DIR -y || true

# Then preview the installed version
DERIVED_NAME=$(echo "test-config" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
packages-installer "$DERIVED_NAME" -i || echo "Note: This might fail if the install didn't complete"
echo

echo "Test 6: Check for double slashes"
echo "--------------------------------"
# This should not produce any double slashes in paths
packages-installer -s ".///$TEST_DIR///" -i 2>&1 | grep -E "//|Processing|Error|Data folder" || true
echo

echo "Test 7: Missing config files"
echo "----------------------------"
EMPTY_DIR="empty-test"
mkdir -p "$EMPTY_DIR"
packages-installer -s ./$EMPTY_DIR -i 2>&1 | grep -E "Error|Invalid" || true
echo

echo "Test 8: URL handling (mock)"
echo "---------------------------"
echo "Would test with: packages-installer -s https://example.com/test.pkginst -i"
echo "(Skipping actual URL test to avoid network dependency)"
echo

# Cleanup
rm -rf "$TEST_DIR" "$TRAD_DIR" "$EMPTY_DIR"

echo "=== All tests completed ==="
echo
echo "If you see package lists for tests 2-4 and appropriate errors for tests 6-7,"
echo "then the fixes are working correctly!"
