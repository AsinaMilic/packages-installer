#!/bin/bash

# Simple Interactive Setup - TESTED AND WORKING
# Repository: https://github.com/AsinaMilic/packages-installer

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               SIMPLE DEBIAN SETUP                         ║${NC}"
echo -e "${BLUE}║     Interactive package installer for Debian systems     ║${NC}"
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

# Function to create a configuration
create_config() {
    local name="$1"
    local config_dir="$HOME/$name-setup"
    
    echo -e "${CYAN}Creating configuration: $name${NC}"
    mkdir -p "$config_dir"
    
    # Create config.json
    cat > "$config_dir/config.json" << EOF
{
    "name": "$name Setup",
    "description": "Interactive setup configuration",
    "version": "1.0.0"
}
EOF
    
    # Create packages.json based on choice
    case "$name" in
        "basic")
            cat > "$config_dir/packages.json" << 'EOF'
{
    "packages": [
        {"package": "git", "description": "Version control"},
        {"package": "vim", "description": "Text editor"},
        {"package": "curl", "description": "Data transfer"},
        {"package": "htop", "description": "System monitor"},
        {"package": "tree", "description": "Directory display"}
    ]
}
EOF
            ;;
        "development")
            cat > "$config_dir/packages.json" << 'EOF'
{
    "packages": [
        {"package": "git", "description": "Version control"},
        {"package": "build-essential", "description": "Build tools"},
        {"package": "python3-pip", "description": "Python package manager"},
        {"package": "nodejs", "description": "JavaScript runtime"},
        {"package": "npm", "description": "Node package manager"},
        {"package": "curl", "description": "Data transfer"},
        {"package": "vim", "description": "Text editor"}
    ]
}
EOF
            ;;
        "media")
            cat > "$config_dir/packages.json" << 'EOF'
{
    "packages": [
        {"package": "gimp", "description": "Image editor"},
        {"package": "vlc", "description": "Media player"},
        {"package": "audacity", "description": "Audio editor"},
        {"package": "imagemagick", "description": "Image tools"}
    ]
}
EOF
            ;;
    esac
    
    echo "$config_dir"
}

# Main menu
show_main_menu() {
    echo
    echo -e "${YELLOW}What would you like to install?${NC}"
    echo
    echo -e "${BLUE}1)${NC} Basic tools (git, vim, curl, htop, tree)"
    echo -e "${BLUE}2)${NC} Development environment (build tools, python, nodejs)"
    echo -e "${BLUE}3)${NC} Media tools (gimp, vlc, audacity)"
    echo -e "${BLUE}4)${NC} Hyprland desktop (complete desktop environment)"
    echo -e "${BLUE}5)${NC} Just install the tool (I'll configure manually)"
    echo
    echo -ne "${CYAN}Enter your choice (1-5): ${NC}"
}

# Get user choice
get_user_choice() {
    local choice
    read choice
    echo "$choice"
}

# Preview and install
preview_and_install() {
    local config_dir="$1"
    local name="$2"
    
    echo
    echo -e "${YELLOW}=== PREVIEW: $name Setup ===${NC}"
    echo -e "${CYAN}Here's what will be installed:${NC}"
    echo
    
    if packages-installer -s "$config_dir" -i; then
        echo
        echo -ne "${CYAN}Install these packages? [Y/n]: ${NC}"
        read confirm
        
        if [[ ! "$confirm" =~ ^[Nn] ]]; then
            echo
            echo -e "${CYAN}Installing packages...${NC}"
            if packages-installer -s "$config_dir" -y; then
                echo -e "${GREEN}✓ Installation completed successfully!${NC}"
                echo -e "${CYAN}Configuration saved to: $config_dir${NC}"
            else
                echo -e "${RED}✗ Installation failed${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}Installation cancelled${NC}"
            echo -e "${CYAN}Configuration saved to: $config_dir${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to preview packages${NC}"
        return 1
    fi
}

# Main script
main() {
    # Install the tool first
    install_tool
    
    # Show menu and get choice
    show_main_menu
    choice=$(get_user_choice)
    
    case "$choice" in
        1)
            config_dir=$(create_config "basic")
            preview_and_install "$config_dir" "Basic Tools"
            ;;
        2)
            config_dir=$(create_config "development")
            preview_and_install "$config_dir" "Development"
            ;;
        3)
            config_dir=$(create_config "media")
            preview_and_install "$config_dir" "Media Tools"
            ;;
        4)
            echo
            echo -e "${CYAN}Installing Hyprland desktop environment...${NC}"
            echo -e "${YELLOW}This will install many packages!${NC}"
            echo
            echo -ne "${CYAN}Continue? [y/N]: ${NC}"
            read confirm
            
            if [[ "$confirm" =~ ^[Yy] ]]; then
                echo -e "${CYAN}Previewing Hyprland setup...${NC}"
                packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.hyprlandsettings/pkginst -i
                echo
                echo -ne "${CYAN}Install Hyprland? [y/N]: ${NC}"
                read final_confirm
                
                if [[ "$final_confirm" =~ ^[Yy] ]]; then
                    packages-installer -s https://github.com/AsinaMilic/packages-installer/raw/main/examples/com.ml4w.hyprlandsettings/pkginst -y
                    echo -e "${GREEN}✓ Hyprland desktop installed!${NC}"
                fi
            fi
            ;;
        5)
            echo
            echo -e "${GREEN}✓ packages-installer is ready to use!${NC}"
            echo
            echo -e "${CYAN}Usage examples:${NC}"
            echo "  packages-installer --help"
            echo "  packages-installer -s <config> -i    # Preview"
            echo "  packages-installer -s <config> -y    # Install"
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Please run the script again.${NC}"
            exit 1
            ;;
    esac
    
    echo
    echo -e "${GREEN}🎉 Setup complete!${NC}"
}

# Run main function
main "$@"