#!/bin/bash

# Interactive Packages Installer Setup Script
# Created by AsinaMilic - https://github.com/AsinaMilic/packages-installer

set -e

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Progress indicator
show_progress() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

show_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

show_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Welcome screen
show_welcome() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                   ${CYAN}INTERACTIVE SYSTEM SETUP${NC}                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Welcome to the interactive packages installer!              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  This will guide you through setting up your Debian system   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  with exactly the software you want.                         ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Repository: https://github.com/AsinaMilic/packages-installer${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        if [ "$default" = "y" ]; then
            echo -ne "${CYAN}$question [Y/n]: ${NC}"
        else
            echo -ne "${CYAN}$question [y/N]: ${NC}"
        fi
        
        read response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        
        if [ -z "$response" ]; then
            response="$default"
        fi
        
        case "$response" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo -e "${RED}Please answer yes or no.${NC}" ;;
        esac
    done
}

# Multi-choice selection
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo -e "\n${YELLOW}=== $title ===${NC}"
    for i in "${!options[@]}"; do
        echo -e "${BLUE}$((i+1)))${NC} ${options[i]}"
    done
    echo -e "${BLUE}0)${NC} Skip this category"
    echo ""
}

get_choice() {
    local max="$1"
    local choice
    
    while true; do
        echo -ne "${CYAN}Enter your choice (0-$max): ${NC}"
        read choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "$max" ]; then
            echo "$choice"  # Return the choice value
            return 0
        else
            echo -e "${RED}Invalid choice. Please enter a number between 0 and $max.${NC}"
        fi
    done
}

# Install packages-installer
install_packages_installer() {
    show_progress "Installing packages-installer..."
    
    if ! curl -s https://raw.githubusercontent.com/AsinaMilic/packages-installer/main/install.sh | bash; then
        show_error "Failed to install packages-installer"
        exit 1
    fi
    
    # Add to PATH
    export PATH=$PATH:~/.local/bin
    echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
    
    show_success "packages-installer installed successfully!"
}

# Create configuration files
create_config() {
    local config_dir="$1"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/config.json" << 'EOF'
{
    "name": "Interactive Custom Setup",
    "description": "Packages selected through interactive installer",
    "author": "Interactive Installer",
    "version": "1.0.0"
}
EOF
}

# Global arrays for package collection
declare -a selected_packages
declare -a optional_categories

# Add package to configuration  
add_package() {
    local package="$1"
    local description="$2"
    local apt_name="$3"
    
    if [ -z "$apt_name" ]; then
        apt_name="$package"
    fi
    
    selected_packages+=("{\"package\":\"$package\",\"apt\":\"$apt_name\",\"description\":\"$description\"}")
}

# Add optional package category
add_option_category() {
    local category_name="$1"
    shift
    local category_packages=("$@")
    
    if [ ${#category_packages[@]} -gt 0 ]; then
        local category_json="{\"name\":\"$category_name\",\"packages\":["
        for i in "${!category_packages[@]}"; do
            if [ $i -gt 0 ]; then
                category_json+=","
            fi
            category_json+="${category_packages[i]}"
        done
        category_json+="]}"
        
        optional_categories+=("$category_json")
    fi
}

# Main interactive setup
main_setup() {
    local config_dir="~/interactive-setup-config"
    
    # Clear global arrays
    selected_packages=()
    optional_categories=()
    
    # Essential packages selection
    show_menu "Essential System Tools" \
        "Basic tools (git, curl, wget, vim)" \
        "Development tools (build-essential, python3-pip)" \
        "System monitoring (htop, tree, neofetch)" \
        "Network tools (net-tools, openssh-client)" \
        "File management (zip, unzip, rsync)"
    
    essential_choice=$(get_choice 5)
    
    case $essential_choice in
        1)
            add_package "git" "Version control system"
            add_package "curl" "Data transfer tool"
            add_package "wget" "Web downloader"
            add_package "vim" "Text editor"
            show_success "Selected basic tools"
            ;;
        2)
            add_package "build-essential" "Compilation tools"
            add_package "python3-pip" "Python package manager"
            add_package "nodejs" "JavaScript runtime"
            add_package "npm" "Node package manager"
            show_success "Selected development tools"
            ;;
        3)
            add_package "htop" "Interactive process viewer"
            add_package "tree" "Directory tree display"
            add_package "neofetch" "System information display"
            show_success "Selected monitoring tools"
            ;;
        4)
            add_package "net-tools" "Network utilities"
            add_package "openssh-client" "SSH client"
            add_package "nmap" "Network scanner"
            show_success "Selected network tools"
            ;;
        5)
            add_package "zip" "Archive creator"
            add_package "unzip" "Archive extractor"
            add_package "rsync" "File synchronization"
            show_success "Selected file management tools"
            ;;
        0)
            show_warning "Skipped essential tools"
            ;;
    esac
    
    # Optional categories
    local dev_packages=()
    local media_packages=()
    local office_packages=()
    local security_packages=()
    
    # Development tools
    if ask_yes_no "Do you want development tools?"; then
        show_menu "Development Tools" \
            "Web Development (nodejs, npm, yarn)" \
            "Python Development (python3-dev, virtualenv)" \
            "Database tools (sqlite3, postgresql-client)" \
            "Docker and containers" \
            "All development tools"
        
        dev_choice=$(get_choice 5)
        
        case $dev_choice in
            1) dev_packages+=("{\"package\":\"nodejs\"}" "{\"package\":\"npm\"}" "{\"package\":\"yarn\"}") ;;
            2) dev_packages+=("{\"package\":\"python3-dev\"}" "{\"package\":\"python3-venv\"}" "{\"package\":\"virtualenv\"}") ;;
            3) dev_packages+=("{\"package\":\"sqlite3\"}" "{\"package\":\"postgresql-client\"}") ;;
            4) dev_packages+=("{\"package\":\"docker.io\"}" "{\"package\":\"docker-compose\"}") ;;
            5) dev_packages+=("{\"package\":\"nodejs\"}" "{\"package\":\"npm\"}" "{\"package\":\"python3-dev\"}" "{\"package\":\"sqlite3\"}" "{\"package\":\"docker.io\"}") ;;
        esac
    fi
    
    # Media tools
    if ask_yes_no "Do you want media tools?"; then
        show_menu "Media Tools" \
            "Image editing (gimp, imagemagick)" \
            "Audio/Video tools (vlc, audacity)" \
            "Graphics tools (inkscape, blender)" \
            "All media tools"
        
        media_choice=$(get_choice 4)
        
        case $media_choice in
            1) media_packages+=("{\"package\":\"gimp\"}" "{\"package\":\"imagemagick\"}") ;;
            2) media_packages+=("{\"package\":\"vlc\"}" "{\"package\":\"audacity\"}") ;;
            3) media_packages+=("{\"package\":\"inkscape\"}" "{\"package\":\"blender\"}") ;;
            4) media_packages+=("{\"package\":\"gimp\"}" "{\"package\":\"vlc\"}" "{\"package\":\"inkscape\"}") ;;
        esac
    fi
    
    # Office and productivity
    if ask_yes_no "Do you want office and productivity tools?"; then
        show_menu "Office & Productivity" \
            "LibreOffice suite" \
            "Text editors (code, atom)" \
            "PDF tools (evince, pdftk)" \
            "All office tools"
        
        office_choice=$(get_choice 4)
        
        case $office_choice in
            1) office_packages+=("{\"package\":\"libreoffice\"}") ;;
            2) office_packages+=("{\"package\":\"code\",\"apt\":\"code\"}" "{\"package\":\"gedit\"}") ;;
            3) office_packages+=("{\"package\":\"evince\"}" "{\"package\":\"pdftk\"}") ;;
            4) office_packages+=("{\"package\":\"libreoffice\"}" "{\"package\":\"evince\"}" "{\"package\":\"gedit\"}") ;;
        esac
    fi
    
    # Security tools
    if ask_yes_no "Do you want security tools?"; then
        show_menu "Security Tools" \
            "Basic security (ufw, fail2ban)" \
            "Password management (pass, gnupg)" \
            "Network security (wireshark, nmap)" \
            "All security tools"
        
        security_choice=$(get_choice 4)
        
        case $security_choice in
            1) security_packages+=("{\"package\":\"ufw\"}" "{\"package\":\"fail2ban\"}") ;;
            2) security_packages+=("{\"package\":\"pass\"}" "{\"package\":\"gnupg\"}") ;;
            3) security_packages+=("{\"package\":\"wireshark\"}" "{\"package\":\"nmap\"}") ;;
            4) security_packages+=("{\"package\":\"ufw\"}" "{\"package\":\"pass\"}" "{\"package\":\"wireshark\"}") ;;
        esac
    fi
    
    # Build categories
    add_option_category "Development_Tools" "${dev_packages[@]}"
    add_option_category "Media_Tools" "${media_packages[@]}"
    add_option_category "Office_Productivity" "${office_packages[@]}"
    add_option_category "Security_Tools" "${security_packages[@]}"
    
    # Create packages.json
    eval config_dir="$config_dir"
    mkdir -p "$config_dir"
    create_config "$config_dir"
    
    # Build packages.json
    cat > "$config_dir/packages.json" << EOF
{
    "packages": [
$(IFS=','; echo "${selected_packages[*]}")
    ]$(if [ ${#optional_categories[@]} -gt 0 ]; then echo ',
    "options": [
'"$(IFS=','; echo "${optional_categories[*]}")"'
    ]'; fi)
}
EOF
    
    # Show preview
    echo -e "\n${YELLOW}=== INSTALLATION PREVIEW ===${NC}"
    show_progress "Here's what will be installed:"
    
    if ! packages-installer -s "$config_dir" -i; then
        show_error "Failed to preview packages"
        exit 1
    fi
    
    echo ""
    if ask_yes_no "Do you want to proceed with the installation?" "y"; then
        show_progress "Starting installation..."
        
        if packages-installer -s "$config_dir" -y -d; then
            show_success "Installation completed successfully!"
            echo -e "\n${GREEN}🎉 Your Debian system has been set up according to your preferences!${NC}"
            echo -e "${CYAN}Configuration saved to: $config_dir${NC}"
        else
            show_error "Installation failed. Check the logs above."
            exit 1
        fi
    else
        show_warning "Installation cancelled by user."
        echo -e "${CYAN}Your configuration has been saved to: $config_dir${NC}"
        echo -e "${CYAN}You can run it later with: packages-installer -s $config_dir -y${NC}"
    fi
}

# Main execution
main() {
    show_welcome
    
    if ask_yes_no "Are you ready to start the interactive setup?" "y"; then
        echo ""
        show_progress "Preparing for installation..."
        
        # Check if packages-installer is already installed
        if ! command -v packages-installer >/dev/null 2>&1; then
            install_packages_installer
        else
            show_success "packages-installer already installed"
        fi
        
        # Start interactive setup
        main_setup
        
        echo -e "\n${GREEN}🚀 Setup complete! Enjoy your customized Debian system!${NC}"
    else
        echo -e "\n${YELLOW}Setup cancelled. Run this script again when you're ready!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
