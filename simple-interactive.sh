#!/bin/bash

# Simple Interactive Installer - Test Version
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Simple Interactive Test ===${NC}"

# Function to get user choice
get_choice() {
    local max="$1"
    local choice
    
    while true; do
        echo -ne "${CYAN}Enter your choice (0-$max): ${NC}"
        read choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "$max" ]; then
            echo "$choice"
            return 0
        else
            echo -e "${RED}Invalid choice. Please enter a number between 0 and $max.${NC}"
        fi
    done
}

# Show menu
echo -e "\n${YELLOW}=== Choose Your Setup ===${NC}"
echo -e "${BLUE}1)${NC} Basic tools (git, curl, vim)"
echo -e "${BLUE}2)${NC} Development tools (build-essential, nodejs)"
echo -e "${BLUE}3)${NC} System tools (htop, tree)"
echo -e "${BLUE}0)${NC} Skip"

choice=$(get_choice 3)

echo ""
case $choice in
    1)
        echo -e "${GREEN}[SUCCESS]${NC} Selected basic tools!"
        echo "Would install: git, curl, vim"
        ;;
    2)
        echo -e "${GREEN}[SUCCESS]${NC} Selected development tools!"
        echo "Would install: build-essential, nodejs, npm"
        ;;
    3)
        echo -e "${GREEN}[SUCCESS]${NC} Selected system tools!"
        echo "Would install: htop, tree, neofetch"
        ;;
    0)
        echo -e "${YELLOW}[WARNING]${NC} Skipped selection"
        ;;
esac

echo -e "\n${CYAN}Continue with more options? [y/N]:${NC}"
read continue_choice

if [[ "$continue_choice" =~ ^[Yy] ]]; then
    echo -e "${GREEN}Great! This is where we'd continue with more categories...${NC}"
else
    echo -e "${YELLOW}Test completed. The script is working!${NC}"
fi

echo -e "\n${BLUE}Test finished successfully!${NC}"