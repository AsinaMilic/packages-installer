#!/bin/bash

# Bulletproof Interactive Packages Installer
# Repository: https://github.com/AsinaMilic/packages-installer
# Designed for ease of use - users choose what they want step by step

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors and formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Global configuration
readonly CONFIG_DIR="$HOME/my-custom-setup"
readonly PACKAGES_FILE="$CONFIG_DIR/packages.json"
readonly CONFIG_FILE="$CONFIG_DIR/config.json"

# Global arrays for collecting user choices
SELECTED_PACKAGES=()
OPTIONAL_CATEGORIES=()

# Logging and display functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

# Progress bar simulation
show_progress() {
    local message="$1"
    echo -ne "${CYAN}$message${NC}"
    for i in {1..5}; do
        sleep 0.2
        echo -n "."
    done
    echo " Done!"
}

# Welcome screen
show_welcome() {
    clear
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║    🚀 INTERACTIVE DEBIAN SYSTEM SETUP 🚀                       ║
║                                                                  ║
║    This installer will guide you step-by-step through           ║
║    choosing exactly the software you want on your Debian        ║
║    system. No manual configuration needed!                      ║
║                                                                  ║
║    Repository: https://github.com/AsinaMilic/packages-installer  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo
}

# Ask yes/no questions with clear defaults
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    
    while true; do
        if [[ "$default" == "y" ]]; then
            echo -ne "${CYAN}$question [Y/n]: ${NC}"
        else
            echo -ne "${CYAN}$question [y/N]: ${NC}"
        fi
        
        read -r response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        
        # Use default if empty response
        [[ -z "$response" ]] && response="$default"
        
        case "$response" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) log_error "Please answer 'y' for yes or 'n' for no." ;;
        esac
    done
}

# Show menu and get user choice
show_menu_and_get_choice() {
    local title="$1"
    shift
    local options=("$@")
    
    echo
    echo -e "${BOLD}${YELLOW}=== $title ===${NC}"
    
    for i in "${!options[@]}"; do
        echo -e "${BLUE}$((i+1)))${NC} ${options[i]}"
    done
    echo -e "${BLUE}0)${NC} Skip this category"
    echo
    
    while true; do
        echo -ne "${CYAN}Enter your choice (0-${#options[@]}): ${NC}"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 0 && choice <= ${#options[@]})); then
            echo "$choice"
            return 0
        else
            log_error "Please enter a number between 0 and ${#options[@]}"
        fi
    done
}

# Add package to selection
add_package() {
    local package="$1"
    local description="$2"
    local apt_override="${3:-}"
    
    if [[ -n "$apt_override" ]]; then
        SELECTED_PACKAGES+=("{\"package\":\"$package\",\"apt\":\"$apt_override\",\"description\":\"$description\"}")
    else
        SELECTED_PACKAGES+=("{\"package\":\"$package\",\"description\":\"$description\"}")
    fi
}

# Install packages-installer if needed
ensure_packages_installer() {
    if command -v packages-installer >/dev/null 2>&1; then
        log_success "packages-installer already installed"
        return 0
    fi
    
    log_info "Installing packages-installer..."
    show_progress "Downloading and installing"
    
    if curl -fsSL https://raw.githubusercontent.com/AsinaMilic/packages-installer/main/install.sh | bash; then
        export PATH="$PATH:$HOME/.local/bin"
        echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
        log_success "packages-installer installed successfully!"
    else
        log_error "Failed to install packages-installer"
        exit 1
    fi
}

# Create configuration directory and files
create_config_files() {
    log_info "Creating configuration files..."
    
    # Create directory
    mkdir -p "$CONFIG_DIR"
    
    # Create config.json
    cat > "$CONFIG_FILE" << 'EOF'
{
    "name": "My Custom Debian Setup",
    "description": "Personalized package selection via interactive installer",
    "author": "Interactive Installer User",
    "version": "1.0.0"
}
EOF
    
    log_success "Configuration directory created at: $CONFIG_DIR"
}

# Step 1: Essential Tools Selection
select_essential_tools() {
    local options=(
        "Basic tools (git, curl, wget, vim) - Essential for most users"
        "Development essentials (build-essential, python3-pip, nodejs, npm)"
        "System monitoring (htop, tree, neofetch, btop)"
        "Network utilities (net-tools, openssh-client, nmap)"
        "File management (zip, unzip, rsync, tree)"
    )
    
    local choice
    choice=$(show_menu_and_get_choice "Essential System Tools" "${options[@]}")
    
    case "$choice" in
        1)
            add_package "git" "Version control system"
            add_package "curl" "Command-line data transfer tool"
            add_package "wget" "Network downloader"
            add_package "vim" "Text editor"
            log_success "Selected: Basic tools"
            ;;
        2)
            add_package "build-essential" "Compilation tools and libraries"
            add_package "python3-pip" "Python package manager"
            add_package "nodejs" "JavaScript runtime"
            add_package "npm" "Node.js package manager"
            log_success "Selected: Development essentials"
            ;;
        3)
            add_package "htop" "Interactive process viewer"
            add_package "tree" "Directory tree display"
            add_package "neofetch" "System information display"
            add_package "btop" "Modern system monitor"
            log_success "Selected: System monitoring tools"
            ;;
        4)
            add_package "net-tools" "Network configuration utilities"
            add_package "openssh-client" "SSH client for remote connections"
            add_package "nmap" "Network discovery and scanning"
            log_success "Selected: Network utilities"
            ;;
        5)
            add_package "zip" "Archive creation tool"
            add_package "unzip" "Archive extraction tool"
            add_package "rsync" "File synchronization tool"
            add_package "tree" "Directory structure display"
            log_success "Selected: File management tools"
            ;;
        0)
            log_warning "Skipped essential tools selection"
            ;;
    esac
}

# Step 2: Development Tools (Optional)
select_development_tools() {
    if ! ask_yes_no "Would you like to add development tools?"; then
        log_info "Skipping development tools"
        return 0
    fi
    
    local options=(
        "Web Development (nodejs, npm, yarn, live-server)"
        "Python Development (python3-dev, virtualenv, ipython)"
        "Database Tools (sqlite3, postgresql-client, mysql-client)"
        "Container Tools (docker.io, docker-compose)"
        "Version Control (git, git-flow, gh - GitHub CLI)"
        "All Development Tools (everything above)"
    )
    
    local choice
    choice=$(show_menu_and_get_choice "Development Tools" "${options[@]}")
    local dev_packages=()
    
    case "$choice" in
        1)
            dev_packages+=("{\"package\":\"nodejs\"}" "{\"package\":\"npm\"}" "{\"package\":\"yarn\"}")
            log_success "Selected: Web Development tools"
            ;;
        2)
            dev_packages+=("{\"package\":\"python3-dev\"}" "{\"package\":\"python3-venv\"}" "{\"package\":\"ipython3\"}")
            log_success "Selected: Python Development tools"
            ;;
        3)
            dev_packages+=("{\"package\":\"sqlite3\"}" "{\"package\":\"postgresql-client\"}" "{\"package\":\"mysql-client\"}")
            log_success "Selected: Database tools"
            ;;
        4)
            dev_packages+=("{\"package\":\"docker.io\"}" "{\"package\":\"docker-compose\"}")
            log_success "Selected: Container tools"
            ;;
        5)
            dev_packages+=("{\"package\":\"git\"}" "{\"package\":\"git-flow\"}" "{\"package\":\"gh\"}")
            log_success "Selected: Version Control tools"
            ;;
        6)
            dev_packages+=("{\"package\":\"nodejs\"}" "{\"package\":\"python3-dev\"}" "{\"package\":\"sqlite3\"}" "{\"package\":\"docker.io\"}" "{\"package\":\"git-flow\"}")
            log_success "Selected: All Development tools"
            ;;
        0)
            log_info "Skipped development tools"
            return 0
            ;;
    esac
    
    if [[ ${#dev_packages[@]} -gt 0 ]]; then
        local dev_category="{\"name\":\"Development_Tools\",\"packages\":[$(printf "%s," "${dev_packages[@]}" | sed 's/,$//')]}"
        OPTIONAL_CATEGORIES+=("$dev_category")
    fi
}

# Step 3: Media and Graphics Tools (Optional)
select_media_tools() {
    if ! ask_yes_no "Would you like to add media and graphics tools?"; then
        log_info "Skipping media tools"
        return 0
    fi
    
    local options=(
        "Image Editing (gimp, imagemagick, inkscape)"
        "Audio/Video (vlc, audacity, ffmpeg)"
        "Graphics Design (blender, krita, darktable)"
        "All Media Tools"
    )
    
    local choice
    choice=$(show_menu_and_get_choice "Media & Graphics Tools" "${options[@]}")
    local media_packages=()
    
    case "$choice" in
        1)
            media_packages+=("{\"package\":\"gimp\"}" "{\"package\":\"imagemagick\"}" "{\"package\":\"inkscape\"}")
            log_success "Selected: Image Editing tools"
            ;;
        2)
            media_packages+=("{\"package\":\"vlc\"}" "{\"package\":\"audacity\"}" "{\"package\":\"ffmpeg\"}")
            log_success "Selected: Audio/Video tools"
            ;;
        3)
            media_packages+=("{\"package\":\"blender\"}" "{\"package\":\"krita\"}" "{\"package\":\"darktable\"}")
            log_success "Selected: Graphics Design tools"
            ;;
        4)
            media_packages+=("{\"package\":\"gimp\"}" "{\"package\":\"vlc\"}" "{\"package\":\"blender\"}")
            log_success "Selected: All Media tools"
            ;;
        0)
            log_info "Skipped media tools"
            return 0
            ;;
    esac
    
    if [[ ${#media_packages[@]} -gt 0 ]]; then
        local media_category="{\"name\":\"Media_Tools\",\"packages\":[$(printf "%s," "${media_packages[@]}" | sed 's/,$//')]}"
        OPTIONAL_CATEGORIES+=("$media_category")
    fi
}

# Step 4: Office and Productivity (Optional)
select_office_tools() {
    if ! ask_yes_no "Would you like to add office and productivity tools?"; then
        log_info "Skipping office tools"
        return 0
    fi
    
    local options=(
        "LibreOffice Suite (Writer, Calc, Impress)"
        "Text Editors (code, atom, gedit)"
        "PDF Tools (evince, pdftk, okular)"
        "Communication (thunderbird, slack)"
        "All Office Tools"
    )
    
    local choice
    choice=$(show_menu_and_get_choice "Office & Productivity" "${options[@]}")
    local office_packages=()
    
    case "$choice" in
        1)
            office_packages+=("{\"package\":\"libreoffice\"}")
            log_success "Selected: LibreOffice Suite"
            ;;
        2)
            office_packages+=("{\"package\":\"code\"}" "{\"package\":\"gedit\"}")
            log_success "Selected: Text Editors"
            ;;
        3)
            office_packages+=("{\"package\":\"evince\"}" "{\"package\":\"pdftk\"}" "{\"package\":\"okular\"}")
            log_success "Selected: PDF Tools"
            ;;
        4)
            office_packages+=("{\"package\":\"thunderbird\"}")
            log_success "Selected: Communication tools"
            ;;
        5)
            office_packages+=("{\"package\":\"libreoffice\"}" "{\"package\":\"evince\"}" "{\"package\":\"thunderbird\"}")
            log_success "Selected: All Office tools"
            ;;
        0)
            log_info "Skipped office tools"
            return 0
            ;;
    esac
    
    if [[ ${#office_packages[@]} -gt 0 ]]; then
        local office_category="{\"name\":\"Office_Productivity\",\"packages\":[$(printf "%s," "${office_packages[@]}" | sed 's/,$//')]}"
        OPTIONAL_CATEGORIES+=("$office_category")
    fi
}

# Generate packages.json file
generate_packages_file() {
    log_info "Generating packages configuration..."
    
    # Start building JSON
    local json_content='{\n    "packages": ['
    
    # Add selected packages
    if [[ ${#SELECTED_PACKAGES[@]} -gt 0 ]]; then
        json_content+='\n        '
        printf -v packages_str '%s,\n        ' "${SELECTED_PACKAGES[@]}"
        json_content+="${packages_str%,*}"
    fi
    
    json_content+='\n    ]'
    
    # Add optional categories if any
    if [[ ${#OPTIONAL_CATEGORIES[@]} -gt 0 ]]; then
        json_content+=',\n    "options": [\n        '
        printf -v categories_str '%s,\n        ' "${OPTIONAL_CATEGORIES[@]}"
        json_content+="${categories_str%,*}"
        json_content+='\n    ]'
    fi
    
    json_content+='\n}'
    
    # Write to file
    echo -e "$json_content" > "$PACKAGES_FILE"
    log_success "Packages configuration created"
}

# Preview what will be installed
show_preview() {
    echo
    echo -e "${BOLD}${YELLOW}=== INSTALLATION PREVIEW ===${NC}"
    log_info "Here's what will be installed on your system:"
    echo
    
    if ! packages-installer -s "$CONFIG_DIR" -i; then
        log_error "Failed to generate preview"
        return 1
    fi
    
    echo
}

# Perform the actual installation
perform_installation() {
    log_info "Starting installation process..."
    echo
    
    if packages-installer -s "$CONFIG_DIR" -y -d; then
        echo
        log_success "🎉 Installation completed successfully!"
        echo
        echo -e "${GREEN}${BOLD}Your Debian system has been customized with your selected packages!${NC}"
        echo -e "${CYAN}Configuration saved to: ${CONFIG_DIR}${NC}"
        echo -e "${CYAN}You can run this configuration again anytime with:${NC}"
        echo -e "${YELLOW}  packages-installer -s ${CONFIG_DIR} -y${NC}"
    else
        log_error "Installation failed. Please check the output above for details."
        return 1
    fi
}

# Main execution flow
main() {
    show_welcome
    
    if ! ask_yes_no "Ready to start your personalized Debian setup?" "y"; then
        echo -e "\n${YELLOW}Setup cancelled. Run this installer again when you're ready!${NC}"
        exit 0
    fi
    
    echo
    log_info "Starting interactive setup process..."
    
    # Step 1: Ensure packages-installer is available
    ensure_packages_installer
    
    # Step 2: Create configuration files
    create_config_files
    
    # Step 3: Essential tools selection
    select_essential_tools
    
    # Step 4: Optional categories
    select_development_tools
    select_media_tools  
    select_office_tools
    
    # Step 5: Generate configuration
    generate_packages_file
    
    # Step 6: Show preview
    show_preview
    
    # Step 7: Confirm and install
    echo
    if ask_yes_no "Do you want to proceed with the installation?" "y"; then
        perform_installation
        echo
        echo -e "${GREEN}🚀 Setup complete! Enjoy your customized Debian system!${NC}"
    else
        log_warning "Installation cancelled by user"
        echo -e "${CYAN}Your configuration has been saved to: ${CONFIG_DIR}${NC}"
        echo -e "${CYAN}You can install it later with: packages-installer -s ${CONFIG_DIR} -y${NC}"
    fi
}

# Error handling
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"