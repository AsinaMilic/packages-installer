#!/usr/bin/env bash

# Enhanced Install Script for packages-installer
# Repository: https://github.com/AsinaMilic/packages-installer

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper functions
_checkCommandExists() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        echo 1
    else
        echo 0
    fi
}

echo_info() {
    echo -e "${BLUE}:: $1${NC}"
}

echo_success() {
    echo -e "${GREEN}:: $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}:: $1${NC}"
}

echo_error() {
    echo -e "${RED}:: ERROR: $1${NC}"
}

# Welcome message
clear
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    PACKAGES INSTALLER SETUP                 ║
║                                                              ║
║  This will install the packages-installer tool and          ║
║  optionally help you get started with your first setup.     ║
║                                                              ║
║  Repository: https://github.com/AsinaMilic/packages-installer ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo

# Check for git
if [[ $(_checkCommandExists "git") == 1 ]]; then
    echo_error "Please install 'git' on your system first."
    echo "   Ubuntu/Debian: sudo apt install git"
    echo "   Fedora:        sudo dnf install git"
    echo "   Arch:          sudo pacman -S git"
    exit 1
fi

# Clean up previous installations
echo_info "Preparing installation..."
if [ -f "$HOME/.cache/packages-installer.zip" ]; then
    rm "$HOME/.cache/packages-installer.zip"
fi

if [ -d "$HOME/.cache/packages-installer" ]; then
    rm -rf "$HOME/.cache/packages-installer"
fi

# Create directories
if [ ! -d "$HOME/.cache" ]; then
    mkdir -p "$HOME/.cache"
fi

if [ ! -d "$HOME/.local/bin" ]; then
    mkdir -p "$HOME/.local/bin"
fi

if [ ! -d "$HOME/.local/share" ]; then
    mkdir -p "$HOME/.local/share"
fi

# Download and install
echo_info "Downloading latest version of packages-installer..."
if ! git clone --quiet --depth 1 https://github.com/AsinaMilic/packages-installer.git "$HOME/.cache/packages-installer" > /dev/null 2>&1; then
    echo_error "Failed to download packages-installer"
    exit 1
fi

# Install files
cp -rf "$HOME/.cache/packages-installer/bin/." "$HOME/.local/bin"
echo_success "packages-installer installed in $HOME/.local/bin"

cp -rf "$HOME/.cache/packages-installer/share/." "$HOME/.local/share"
echo_success "packages-installer library installed in $HOME/.local/share"

# Add to PATH
export PATH="$PATH:$HOME/.local/bin"
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc

echo_success "Installation completed successfully!"
echo

# Offer to get started immediately
echo -e "${CYAN}Would you like to get started now? [y/N]: ${NC}"
read -r response

if [[ "$response" =~ ^[Yy] ]]; then
    echo
    echo_info "Great! Let's help you choose what to install..."
    echo
    echo "Choose a quick start option:"
    echo -e "${BLUE}1)${NC} Basic development setup (git, vim, curl, htop)"
    echo -e "${BLUE}2)${NC} Hyprland desktop environment (complete modern desktop)"
    echo -e "${BLUE}3)${NC} Browse available examples"
    echo -e "${BLUE}4)${NC} I'll set it up manually later"
    echo
    echo -ne "${CYAN}Enter your choice (1-4): ${NC}"
    read -r choice
    
    case "$choice" in
        1)
            echo
            echo_info "Setting up basic development environment..."
            
            # Create a basic setup
            mkdir -p "$HOME/basic-dev-setup"
            cat > "$HOME/basic-dev-setup/config.json" << 'EOF'
{
    "name": "Basic Development Setup",
    "description": "Essential tools for development and system administration",
    "version": "1.0.0"
}
EOF
            
            cat > "$HOME/basic-dev-setup/packages.json" << 'EOF'
{
    "packages": [
        {"package": "git", "description": "Version control system"},
        {"package": "vim", "description": "Text editor"},
        {"package": "curl", "description": "Data transfer tool"},
        {"package": "wget", "description": "Web downloader"},
        {"package": "htop", "description": "System monitor"},
        {"package": "tree", "description": "Directory tree viewer"}
    ]
}
EOF
            
            echo_info "Preview of what will be installed:"
            packages-installer -s "$HOME/basic-dev-setup" -i
            echo
            echo -ne "${CYAN}Install these packages? [Y/n]: ${NC}"
            read -r confirm
            
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                packages-installer -s "$HOME/basic-dev-setup" -y
                echo_success "Basic development setup complete!"
            else
                echo_warning "Installation cancelled. Configuration saved to: $HOME/basic-dev-setup"
            fi
            ;;
            
        2)
            echo
            echo_info "Installing Hyprland desktop environment..."
            echo_warning "This is a complete desktop environment - it will install many packages!"
            echo
            echo -ne "${CYAN}Continue with Hyprland installation? [y/N]: ${NC}"
            read -r confirm
            
            if [[ "$confirm" =~ ^[Yy] ]]; then
                # Preview first
                packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.dotfiles/pkginst -i
                echo
                echo -ne "${CYAN}Proceed with installation? [y/N]: ${NC}"
                read -r final_confirm
                
                if [[ "$final_confirm" =~ ^[Yy] ]]; then
                    packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.dotfiles/pkginst -y
                    echo_success "Hyprland desktop environment installed!"
                else
                    echo_warning "Installation cancelled"
                fi
            else
                echo_info "Hyprland installation cancelled"
            fi
            ;;
            
        3)
            echo
            echo_info "Available example configurations:"
            echo
            echo -e "${BLUE}• ML4W Dotfiles:${NC} Complete Hyprland desktop environment"
            echo "  packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.dotfiles/pkginst -i"
            echo
            echo -e "${BLUE}• Hyprland Settings:${NC} Just the Hyprland settings app"
            echo "  packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.hyprlandsettings/pkginst -i"
            echo
            echo_info "Use the commands above to preview any configuration"
            echo_info "Add '-y' flag to install after preview"
            ;;
            
        4)
            echo
            echo_info "No problem! Here's how to get started when you're ready:"
            echo
            echo -e "${BLUE}Basic usage:${NC}"
            echo "  packages-installer -s <source> -i    # Preview packages"
            echo "  packages-installer -s <source> -y    # Install packages"
            echo
            echo -e "${BLUE}Examples:${NC}"
            echo "  packages-installer -s ~/my-config -i"
            echo "  packages-installer -s https://example.com/setup.pkginst -y"
            echo
            echo_info "Check the documentation at: https://github.com/AsinaMilic/packages-installer"
            ;;
            
        *)
            echo_warning "Invalid choice. You can run packages-installer manually later."
            ;;
    esac
else
    echo
    echo_info "packages-installer is ready to use!"
    echo
    echo -e "${BLUE}Quick start:${NC}"
    echo "  packages-installer --help                    # Show help"
    echo "  packages-installer -s <config> -i           # Preview packages"
    echo "  packages-installer -s <config> -y           # Install packages"
    echo
    echo -e "${BLUE}Examples:${NC}"
    echo "  packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.hyprlandsettings/pkginst -i"
    echo
    echo_info "Documentation: https://github.com/AsinaMilic/packages-installer"
fi

echo
echo_success "Setup complete! Enjoy using packages-installer!"