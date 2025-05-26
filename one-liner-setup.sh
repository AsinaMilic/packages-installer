#!/bin/bash

# One-liner Debian Setup with packages-installer
# Usage: curl -s https://your-url/one-liner-setup.sh | bash

set -e

echo "🚀 Starting Debian Setup..."

# Install packages-installer if not present
if ! command -v packages-installer >/dev/null 2>&1; then
    echo "📦 Installing packages-installer..."
    curl -s https://raw.githubusercontent.com/mylinuxforwork/packages-installer/main/install.sh | bash
    export PATH="$HOME/.local/bin:$PATH"
fi

# Create a temporary config directory
TEMP_CONFIG=$(mktemp -d)
trap "rm -rf $TEMP_CONFIG" EXIT

# Create a basic Debian essentials config
cat > "$TEMP_CONFIG/config.json" << 'EOF'
{
    "name": "Debian Essentials",
    "id": "debian-essentials",
    "version": "1.0.0"
}
EOF

cat > "$TEMP_CONFIG/packages.json" << 'EOF'
{
    "packages": [
        {"package": "git", "description": "Version control"},
        {"package": "curl", "description": "Data transfer"},
        {"package": "wget", "description": "Network downloader"},
        {"package": "vim", "description": "Text editor"},
        {"package": "htop", "description": "System monitor"},
        {"package": "tree", "description": "Directory viewer"},
        {"package": "build-essential", "description": "Development tools"},
        {"package": "python3-pip", "description": "Python packages"},
        {"package": "neofetch", "description": "System info"},
        {"package": "zip", "description": "Archive tool"},
        {"package": "unzip", "description": "Archive extractor"}
    ]
}
EOF

# Show what will be installed
echo "📋 Preview of packages to install:"
packages-installer -s "$TEMP_CONFIG" -i

# Install with automatic yes
echo "🔧 Installing packages..."
packages-installer -s "$TEMP_CONFIG" -y

echo "✅ Setup complete!"