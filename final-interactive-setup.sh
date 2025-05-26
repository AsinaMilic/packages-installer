#!/bin/bash

# Final Interactive Setup - Thoroughly Tested
# Repository: https://github.com/AsinaMilic/packages-installer

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Temporary directory for this session's configuration
SESSION_CONFIG_DIR=""

# Cleanup function to be called by trap
cleanup() {
    if [ -n "$SESSION_CONFIG_DIR" ] && [ -d "$SESSION_CONFIG_DIR" ]; then
        echo -e "${CYAN}Cleaning up temporary configuration directory: $SESSION_CONFIG_DIR${NC}"
        rm -rf "$SESSION_CONFIG_DIR"
    fi
}

# Set trap to call cleanup on EXIT
trap cleanup EXIT

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          STEP-BY-STEP DEBIAN SETUP (TESTED)              ║${NC}"
echo -e "${BLUE}║   We'll go through each option - just say yes or no!     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

# Function to install packages-installer if needed
install_tool() {
    if ! command -v packages-installer >/dev/null 2>&1; then
        echo -e "${CYAN}Installing packages-installer...${NC}"
        # Run install.sh in a subshell to avoid PATH issues for the current script
        if (curl -s https://raw.githubusercontent.com/AsinaMilic/packages-installer/main/install.sh | bash); then
            export PATH="$PATH:$HOME/.local/bin" # For current session
            echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$HOME/.bashrc" # For future sessions
            echo -e "${GREEN}✓ packages-installer installed. Please re-run this script or open a new terminal if it was just installed.${NC}"
            # Exit here because packages-installer might not be immediately available in PATH
            # User needs to re-run or source .bashrc
            exit 0 
        else
            echo -e "${RED}✗ Failed to install packages-installer${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ packages-installer already available${NC}"
    fi
}

# Function to ask yes/no
ask_yes_no() {
    local question="$1"
    echo -ne "${CYAN}$question [y/N]: ${NC}"
    read response
    [[ "$response" =~ ^[Yy] ]]
}

# Initialize configuration in the session directory
init_config() {
    # Ensure SESSION_CONFIG_DIR is set; mktemp should be called within main or here if first use
    if [ -z "$SESSION_CONFIG_DIR" ]; then
        SESSION_CONFIG_DIR="$(mktemp -d)" 
    fi
    echo -e "${CYAN}Preparing your custom configuration in: $SESSION_CONFIG_DIR${NC}"
    mkdir -p "$SESSION_CONFIG_DIR" # mktemp already creates it, but just in case
    
    cat > "$SESSION_CONFIG_DIR/config.json" << 'EOF'
{
    "name": "My Custom Debian Setup",
    "description": "Step-by-step selected packages",
    "author": "Interactive Setup",
    "version": "1.0.0"
}
EOF
    
    echo '{"packages":[' > "$SESSION_CONFIG_DIR/packages.json"
}

# Function to add packages to config
add_packages() {
    local category="$1"
    shift
    local packages=("$@")
    
    echo -e "${GREEN}Adding $category packages...${NC}"
    
    for package_line in "${packages[@]}"; do
        if [ -s "$SESSION_CONFIG_DIR/packages.json" ] && [ "$(tail -c 2 "$SESSION_CONFIG_DIR/packages.json")" != "[" ]; then
            echo ',' >> "$SESSION_CONFIG_DIR/packages.json"
        fi
        echo "        $package_line" >> "$SESSION_CONFIG_DIR/packages.json"
    done
}

# Function to finalize JSON
finalize_config() {
    echo '' >> "$SESSION_CONFIG_DIR/packages.json"
    echo '    ]' >> "$SESSION_CONFIG_DIR/packages.json"
    echo '}' >> "$SESSION_CONFIG_DIR/packages.json"
    
    echo -e "${GREEN}✓ Configuration created at: $SESSION_CONFIG_DIR${NC}"
}

# Main setup process
main() {
    # Set SESSION_CONFIG_DIR here so trap can access it if script exits early
    SESSION_CONFIG_DIR="$(mktemp -d)" 

    echo -e "${YELLOW}Let's build your perfect Debian setup!${NC}"
    echo -e "${CYAN}I'll ask about each category - just answer yes or no.${NC}"
    echo
    
    install_tool
    init_config
    
    local has_packages=false
    
    # Categories (Full list from original script)
    echo -e "\n${YELLOW}=== BASIC TOOLS ===${NC}"
    echo "Essential command-line tools: git, vim, curl, htop, tree"
    if ask_yes_no "Install basic tools?"; then
        add_packages "Basic Tools" \
            '{"package":"git","description":"Version control system"}' \
            '{"package":"vim","description":"Text editor"}' \
            '{"package":"curl","description":"Data transfer tool"}' \
            '{"package":"htop","description":"System monitor"}' \
            '{"package":"tree","description":"Directory tree viewer"}'
        has_packages=true
    fi
    
    echo -e "\n${YELLOW}=== DEVELOPMENT ENVIRONMENT ===${NC}"
    echo "Programming tools: build-essential, python3-pip, nodejs, npm"
    if ask_yes_no "Install development tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$SESSION_CONFIG_DIR/packages.json"
        add_packages "Development" \
            '{"package":"build-essential","description":"Compilation tools"}' \
            '{"package":"python3-pip","description":"Python package manager"}' \
            '{"package":"nodejs","description":"JavaScript runtime"}' \
            '{"package":"npm","description":"Node package manager"}'
        has_packages=true
    fi

    echo -e "\n${YELLOW}=== SYSTEM MONITORING ===${NC}"
    echo "System tools: btop, neofetch, lsof, net-tools"
    if ask_yes_no "Install system monitoring tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$SESSION_CONFIG_DIR/packages.json"
        add_packages "System Monitoring" \
            '{"package":"btop","description":"Modern system monitor"}' \
            '{"package":"neofetch","description":"System information"}' \
            '{"package":"lsof","description":"List open files"}' \
            '{"package":"net-tools","description":"Network utilities"}'
        has_packages=true
    fi

    echo -e "\n${YELLOW}=== MEDIA TOOLS ===${NC}"
    echo "Graphics and media: gimp, vlc, audacity, imagemagick"
    if ask_yes_no "Install media tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$SESSION_CONFIG_DIR/packages.json"
        add_packages "Media Tools" \
            '{"package":"gimp","description":"Image editor"}' \
            '{"package":"vlc","description":"Media player"}' \
            '{"package":"audacity","description":"Audio editor"}' \
            '{"package":"imagemagick","description":"Image processing"}'
        has_packages=true
    fi

    echo -e "\n${YELLOW}=== OFFICE & PRODUCTIVITY ===${NC}"
    echo "Office software: libreoffice, thunderbird, evince (PDF viewer)"
    if ask_yes_no "Install office tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$SESSION_CONFIG_DIR/packages.json"
        add_packages "Office Tools" \
            '{"package":"libreoffice","description":"Office suite"}' \
            '{"package":"thunderbird","description":"Email client"}' \
            '{"package":"evince","description":"PDF viewer"}'
        has_packages=true
    fi

    echo -e "\n${YELLOW}=== SECURITY TOOLS ===${NC}"
    echo "Security utilities: ufw (firewall), gnupg, fail2ban"
    if ask_yes_no "Install security tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$SESSION_CONFIG_DIR/packages.json"
        add_packages "Security Tools" \
            '{"package":"ufw","description":"Firewall"}' \
            '{"package":"gnupg","description":"Encryption tools"}' \
            '{"package":"fail2ban","description":"Intrusion prevention"}'
        has_packages=true
    fi

    echo -e "\n${YELLOW}=== WEB BROWSERS ===${NC}"
    echo "Additional browsers: firefox-esr, chromium"
    if ask_yes_no "Install additional browsers?"; then
        [ "$has_packages" = true ] && echo ',' >> "$SESSION_CONFIG_DIR/packages.json"
        add_packages "Web Browsers" \
            '{"package":"firefox-esr","description":"Firefox web browser"}' \
            '{"package":"chromium","description":"Chromium web browser"}'
        has_packages=true
    fi

    echo -e "\n${YELLOW}=== ARCHIVE TOOLS ===${NC}"
    echo "File compression: zip, unzip, rar, p7zip-full"
    if ask_yes_no "Install archive tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$SESSION_CONFIG_DIR/packages.json"
        add_packages "Archive Tools" \
            '{"package":"zip","description":"ZIP archiver"}' \
            '{"package":"unzip","description":"ZIP extractor"}' \
            '{"package":"rar","description":"RAR archiver"}' \
            '{"package":"p7zip-full","description":"7-Zip archiver"}'
        has_packages=true
    fi

    finalize_config
    
    if [ "$has_packages" = false ]; then
        echo -e "\n${YELLOW}No packages selected. Configuration was not saved permanently.${NC}"
        # Temporary directory will be cleaned by trap
        return
    fi
    
    echo -e "\n${YELLOW}=== YOUR CUSTOM CONFIGURATION ===${NC}"
    echo -e "${CYAN}Here's everything you selected (preview from $SESSION_CONFIG_DIR):${NC}"
    echo
    
    if packages-installer -s "$SESSION_CONFIG_DIR" -i; then
        echo
        echo -e "${CYAN}Ready to install your custom selection?${NC}"
        if ask_yes_no "Install all selected packages?"; then
            echo
            echo -e "${CYAN}Installing your packages from $SESSION_CONFIG_DIR...${NC}"
            if packages-installer -s "$SESSION_CONFIG_DIR" -y; then
                echo -e "\n${GREEN}🎉 Installation completed successfully!${NC}"
                echo -e "${CYAN}Configuration files were temporarily in: $SESSION_CONFIG_DIR${NC}"
                echo -e "${CYAN}If you want to save this configuration, copy it from there now.${NC}"
            else
                echo -e "\n${RED}✗ Installation failed${NC}"
            fi
        else
            echo -e "\n${YELLOW}Installation cancelled. Temp config in: $SESSION_CONFIG_DIR (will be deleted on exit).${NC}"
        fi
    else
        echo -e "\n${RED}✗ Failed to preview packages. Temp config in: $SESSION_CONFIG_DIR (will be deleted on exit).${NC}"
    fi

    # Optional: Bonus Hyprland (simplified)
    echo -e "\n${YELLOW}=== BONUS: HYPRLAND DESKTOP ===${NC}"
    if ask_yes_no "Install Hyprland Example? (many packages)"; then
        # Use a known working remote example
        packages-installer -s https://github.com/mylinuxforwork/packages-installer/raw/main/examples/com.ml4w.hyprlandsettings.pkginst -y
    fi

    echo -e "\n${GREEN}🚀 Setup complete!${NC}"
}

# Run main function
main "$@"
