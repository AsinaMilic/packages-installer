#!/bin/bash

# Step-by-Step Interactive Setup
# Repository: https://github.com/AsinaMilic/packages-installer
# Goes through all options automatically - user chooses yes/no for each

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration directory
CONFIG_DIR="$HOME/my-custom-setup"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          STEP-BY-STEP DEBIAN SETUP                       ║${NC}"
echo -e "${BLUE}║   We'll go through each option - just say yes or no!     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

# Function to install packages-installer if needed
install_tool() {
    if ! command -v packages-installer >/dev/null 2>&1; then
        echo -e "${CYAN}Installing packages-installer...${NC}"
        if curl -s https://raw.githubusercontent.com/AsinaMilic/packages-installer/main/install.sh | bash; then
            export PATH="$PATH:$HOME/.local/bin"
            echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
            echo -e "${GREEN}✓ packages-installer installed${NC}"
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

# Initialize configuration
init_config() {
    echo -e "${CYAN}Preparing your custom configuration...${NC}"
    rm -rf "$CONFIG_DIR" 2>/dev/null
    mkdir -p "$CONFIG_DIR"
    
    # Create config.json directly in CONFIG_DIR - packages-installer will find it
    cat > "$CONFIG_DIR/config.json" << 'EOF'
{
    "name": "My Custom Debian Setup",
    "description": "Step-by-step selected packages",
    "author": "Interactive Setup",
    "version": "1.0.0"
}
EOF
    
    # Start packages.json directly in CONFIG_DIR
    echo '{"packages":[' > "$CONFIG_DIR/packages.json"
}

# Function to add packages to config
add_packages() {
    local category="$1"
    shift
    local packages=("$@")
    
    echo -e "${GREEN}Adding $category packages...${NC}"
    
    for package_line in "${packages[@]}"; do
        # Add comma if not first package
        if [ -s "$CONFIG_DIR/packages.json" ] && [ "$(tail -c 2 "$CONFIG_DIR/packages.json")" != "[" ]; then
            echo ',' >> "$CONFIG_DIR/packages.json"
        fi
        echo "        $package_line" >> "$CONFIG_DIR/packages.json"
    done
}

# Function to finalize JSON
finalize_config() {
    echo '' >> "$CONFIG_DIR/packages.json"
    echo '    ]' >> "$CONFIG_DIR/packages.json"
    echo '}' >> "$CONFIG_DIR/packages.json"
    
    echo -e "${GREEN}✓ Configuration created!${NC}"
}

# Main setup process
main() {
    echo -e "${YELLOW}Let's build your perfect Debian setup!${NC}"
    echo -e "${CYAN}I'll ask about each category - just answer yes or no.${NC}"
    echo
    
    # Install tool first
    install_tool
    
    # Initialize config
    init_config
    
    local has_packages=false
    
    # 1. Basic Tools
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
    
    # 2. Development Environment
    echo -e "\n${YELLOW}=== DEVELOPMENT ENVIRONMENT ===${NC}"
    echo "Programming tools: build-essential, python3-pip, nodejs, npm"
    if ask_yes_no "Install development tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$CONFIG_DIR/packages.json"
        add_packages "Development" \
            '{"package":"build-essential","description":"Compilation tools"}' \
            '{"package":"python3-pip","description":"Python package manager"}' \
            '{"package":"nodejs","description":"JavaScript runtime"}' \
            '{"package":"npm","description":"Node package manager"}'
        has_packages=true
    fi
    
    # 3. System Monitoring
    echo -e "\n${YELLOW}=== SYSTEM MONITORING ===${NC}"
    echo "System tools: btop, neofetch, lsof, netstat"
    if ask_yes_no "Install system monitoring tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$CONFIG_DIR/packages.json"
        add_packages "System Monitoring" \
            '{"package":"btop","description":"Modern system monitor"}' \
            '{"package":"neofetch","description":"System information"}' \
            '{"package":"lsof","description":"List open files"}' \
            '{"package":"net-tools","description":"Network utilities"}'
        has_packages=true
    fi
    
    # 4. Media Tools
    echo -e "\n${YELLOW}=== MEDIA TOOLS ===${NC}"
    echo "Graphics and media: gimp, vlc, audacity, imagemagick"
    if ask_yes_no "Install media tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$CONFIG_DIR/packages.json"
        add_packages "Media Tools" \
            '{"package":"gimp","description":"Image editor"}' \
            '{"package":"vlc","description":"Media player"}' \
            '{"package":"audacity","description":"Audio editor"}' \
            '{"package":"imagemagick","description":"Image processing"}'
        has_packages=true
    fi
    
    # 5. Office & Productivity
    echo -e "\n${YELLOW}=== OFFICE & PRODUCTIVITY ===${NC}"
    echo "Office software: libreoffice, thunderbird, evince (PDF viewer)"
    if ask_yes_no "Install office tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$CONFIG_DIR/packages.json"
        add_packages "Office Tools" \
            '{"package":"libreoffice","description":"Office suite"}' \
            '{"package":"thunderbird","description":"Email client"}' \
            '{"package":"evince","description":"PDF viewer"}'
        has_packages=true
    fi
    
    # 6. Security Tools
    echo -e "\n${YELLOW}=== SECURITY TOOLS ===${NC}"
    echo "Security utilities: ufw (firewall), gnupg, fail2ban"
    if ask_yes_no "Install security tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$CONFIG_DIR/packages.json"
        add_packages "Security Tools" \
            '{"package":"ufw","description":"Firewall"}' \
            '{"package":"gnupg","description":"Encryption tools"}' \
            '{"package":"fail2ban","description":"Intrusion prevention"}'
        has_packages=true
    fi
    
    # 7. Web Browsers
    echo -e "\n${YELLOW}=== WEB BROWSERS ===${NC}"
    echo "Additional browsers: firefox-esr, chromium"
    if ask_yes_no "Install additional browsers?"; then
        [ "$has_packages" = true ] && echo ',' >> "$CONFIG_DIR/packages.json"
        add_packages "Web Browsers" \
            '{"package":"firefox-esr","description":"Firefox web browser"}' \
            '{"package":"chromium","description":"Chromium web browser"}'
        has_packages=true
    fi
    
    # 8. Archive Tools
    echo -e "\n${YELLOW}=== ARCHIVE TOOLS ===${NC}"
    echo "File compression: zip, unzip, rar, 7zip"
    if ask_yes_no "Install archive tools?"; then
        [ "$has_packages" = true ] && echo ',' >> "$CONFIG_DIR/packages.json"
        add_packages "Archive Tools" \
            '{"package":"zip","description":"ZIP archiver"}' \
            '{"package":"unzip","description":"ZIP extractor"}' \
            '{"package":"rar","description":"RAR archiver"}' \
            '{"package":"p7zip-full","description":"7-Zip archiver"}'
        has_packages=true
    fi
    
    # Finalize configuration
    finalize_config
    
    # Check if user selected anything
    if [ "$has_packages" = false ]; then
        echo -e "\n${YELLOW}No packages selected. That's okay!${NC}"
        echo -e "${CYAN}packages-installer is ready for manual configuration.${NC}"
        echo
        echo -e "${BLUE}Usage examples:${NC}"
        echo "  packages-installer --help"
        echo "  packages-installer -s <config> -i    # Preview"
        echo "  packages-installer -s <config> -y    # Install"
        return
    fi
    
    # Show preview
    echo -e "\n${YELLOW}=== YOUR CUSTOM CONFIGURATION ===${NC}"
    echo -e "${CYAN}Here's everything you selected:${NC}"
    echo
    
    if packages-installer -s "$CONFIG_DIR" -i; then
        echo
        echo -e "${CYAN}Ready to install your custom selection?${NC}"
        if ask_yes_no "Install all selected packages?"; then
            echo
            echo -e "${CYAN}Installing your packages...${NC}"
            if packages-installer -s "$CONFIG_DIR" -y; then
                echo -e "\n${GREEN}🎉 Installation completed successfully!${NC}"
                echo -e "${CYAN}Your configuration is saved at: $CONFIG_DIR${NC}"
                echo -e "${CYAN}You can reinstall anytime with: packages-installer -s $CONFIG_DIR -y${NC}"
            else
                echo -e "\n${RED}✗ Installation failed${NC}"
                return 1
            fi
        else
            echo -e "\n${YELLOW}Installation cancelled${NC}"
            echo -e "${CYAN}Your configuration is saved at: $CONFIG_DIR${NC}"
            echo -e "${CYAN}Install later with: packages-installer -s $CONFIG_DIR -y${NC}"
        fi
    else
        echo -e "\n${RED}✗ Failed to preview packages${NC}"
        return 1
    fi
    
    # Optional: Hyprland desktop
    echo -e "\n${YELLOW}=== BONUS: COMPLETE DESKTOP ENVIRONMENT ===${NC}"
    echo "Want a complete modern desktop? Hyprland provides a full desktop experience."
    if ask_yes_no "Install Hyprland desktop environment? (This will install many packages)"; then
        echo -e "\n${CYAN}Previewing Hyprland desktop...${NC}"
        packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.hyprlandsettings/pkginst -i
        echo
        if ask_yes_no "Install Hyprland desktop?"; then
            packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.hyprlandsettings/pkginst -y
            echo -e "${GREEN}✓ Hyprland desktop installed!${NC}"
        fi
    fi
    
    echo -e "\n${GREEN}🚀 Setup complete! Enjoy your customized Debian system!${NC}"
}

# Run main function
main "$@"
