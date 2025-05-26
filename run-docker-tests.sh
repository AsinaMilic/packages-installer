#!/bin/bash

set -eo pipefail # Exit on error, pipe failures

IMAGE_NAME="packages-installer-testenv"

# ANSI Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Build the Docker image
log_info "Building Docker test environment as $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" -f Dockerfile.devtest .
log_info "Docker image built."

# --- Test Scenarios --- 

# Scenario 1: Test install.sh and basic tool functionality
test_scenario_1() {
    log_info "--- SCENARIO 1: Testing install.sh and basic functionality ---"
    docker run --rm "$IMAGE_NAME" bash -c "
        set -ex
        echo -e \"${GREEN}[INFO]${NC} Running install.sh inside container...\"
        bash ./install.sh
        echo -e \"${GREEN}[INFO]${NC} Verifying packages-installer presence...\"
        ls -la ~/.local/bin/packages-installer
        echo -e \"${GREEN}[INFO]${NC} Adding to PATH and testing --help...\"
        export PATH=\$PATH:~/.local/bin/
        packages-installer --help
        echo -e \"${GREEN}[INFO]${NC} Scenario 1 Test PASSED\"
    "
}

# Scenario 2: Test with simple local config (no package name arg)
# Config structure: my-test-config/config.json, my-test-config/packages.json
test_scenario_2() {
    log_info "--- SCENARIO 2: Testing simple local config (e.g., -s ./my-test-config) ---"
    # Create test config directory
    rm -rf ./temp-test-config && mkdir -p ./temp-test-config
    cat > ./temp-test-config/config.json <<EOF
{
    "name": "MySimpleTestPackage",
    "id": "my-simple-test",
    "description": "A simple test case.",
    "version": "1.0.0"
}
EOF
    cat > ./temp-test-config/packages.json <<EOF
{
    "packages": [
        {"package": "git", "description": "Git VCS"}    
    ]
}
EOF
    log_info "Created ./temp-test-config for Scenario 2"

    docker run --rm -v "$(pwd)/temp-test-config:/home/testuser/my-test-config" "$IMAGE_NAME" bash -c "
        set -ex
        echo -e \"${GREEN}[INFO]${NC} Installing packages-installer first...\"
        bash /app/install.sh # Use absolute path to app dir inside container
        export PATH=\$PATH:~/.local/bin/
        echo -e \"${GREEN}[INFO]${NC} Running packages-installer -s ./my-test-config -i (preview)\"
        packages-installer -s ./my-test-config -i
        echo -e \"${GREEN}[INFO]${NC} Running packages-installer -s ./my-test-config -y (install)\"
        packages-installer -s ./my-test-config -y
        echo -e \"${GREEN}[INFO]${NC} Scenario 2 Test PASSED\"
    "
    rm -rf ./temp-test-config
}

# Scenario 3: Test with traditional local config (source dir + package name arg)
# Config structure: my-project-source/actual-package-name/pkginst/config.json, .../packages.json
test_scenario_3() {
    log_info "--- SCENARIO 3: Testing traditional local config (e.g., -s ./my-project-source actual-package-name) ---"
    rm -rf ./temp-project-source && mkdir -p ./temp-project-source/actual-package-name/pkginst
    cat > ./temp-project-source/actual-package-name/pkginst/config.json <<EOF
{
    "name": "ActualPackageName",
    "id": "actual-package-id",
    "description": "Traditional structure test.",
    "version": "1.0.0"
}
EOF
    cat > ./temp-project-source/actual-package-name/pkginst/packages.json <<EOF
{
    "packages": [
        {"package": "curl", "description": "Curl utility"}
    ]
}
EOF
    log_info "Created ./temp-project-source for Scenario 3"

    docker run --rm -v "$(pwd)/temp-project-source:/home/testuser/my-project-source" "$IMAGE_NAME" bash -c "
        set -ex
        echo -e \"${GREEN}[INFO]${NC} Installing packages-installer first...\"
        bash /app/install.sh # Use absolute path to app dir inside container
        export PATH=\$PATH:~/.local/bin/
        echo -e \"${GREEN}[INFO]${NC} Running packages-installer -s ./my-project-source actual-package-name -i (preview)\"
        packages-installer -s ./my-project-source actual-package-name -i
        echo -e \"${GREEN}[INFO]${NC} Running packages-installer -s ./my-project-source actual-package-name -y (install)\"
        packages-installer -s ./my-project-source actual-package-name -y
        echo -e \"${GREEN}[INFO]${NC} Scenario 3 Test PASSED\"
    "
    rm -rf ./temp-project-source
}

# Scenario 4: Test with remote URL (Hyprland settings example)
test_scenario_4() {
    log_info "--- SCENARIO 4: Testing with remote URL (Hyprland settings example) ---"
    docker run --rm "$IMAGE_NAME" bash -c "
        set -ex
        echo -e \"${GREEN}[INFO]${NC} Installing packages-installer first...\"
        bash /app/install.sh # Use absolute path to app dir inside container
        export PATH=\$PATH:~/.local/bin/
        REMOTE_URL=\"https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.hyprlandsettings.pkginst\"
        echo -e \"${GREEN}[INFO]${NC} Running packages-installer -s \$REMOTE_URL -i (preview)\"
        packages-installer -s \"\$REMOTE_URL\" -i
        # We won't run -y for remote hyprland example as it's too heavy for a quick test
        echo -e \"${GREEN}[INFO]${NC} Scenario 4 Test (Preview Only) PASSED\"
    "
}

# Run all tests
log_info "Starting all test scenarios..."
test_scenario_1 && log_info "Scenario 1 Done."
test_scenario_2 && log_info "Scenario 2 Done."
test_scenario_3 && log_info "Scenario 3 Done."
test_scenario_4 && log_info "Scenario 4 Done."

log_info "All Docker tests completed. Review output for PASS/FAIL."
