#!/bin/bash

# Network Switcher Uninstallation Script
# This script removes the Network Switcher tray application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="network-switcher.service"
SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME"

echo -e "${YELLOW}=== Network Switcher Uninstallation ===${NC}\n"

# Function to print error messages
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

# Function to print success messages
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning messages
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Ask for confirmation
echo -e "${YELLOW}This will remove the Network Switcher service and configuration.${NC}"
echo -e "${YELLOW}The script files in $SCRIPT_DIR will NOT be deleted.${NC}"
echo -e "\n${RED}Do you want to continue? (y/n)${NC}"
read -r response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Check if systemctl is available
if command -v systemctl &> /dev/null; then
    SYSTEMCTL_AVAILABLE=true
else
    SYSTEMCTL_AVAILABLE=false
    warning "systemctl not found. Service removal will be skipped."
fi

# Stop and disable the service
if [ "$SYSTEMCTL_AVAILABLE" = true ] && [ -f "$SERVICE_FILE" ]; then
    echo -e "\n${GREEN}Stopping and disabling service...${NC}"
    
    # Check if service is running
    if systemctl --user is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl --user stop "$SERVICE_NAME" || warning "Failed to stop service (it may not be running)"
        success "Service stopped"
    else
        warning "Service is not running"
    fi
    
    # Check if service is enabled
    if systemctl --user is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl --user disable "$SERVICE_NAME" || warning "Failed to disable service"
        success "Service disabled"
    else
        warning "Service was not enabled"
    fi
    
    # Remove service file
    if rm -f "$SERVICE_FILE"; then
        success "Service file removed: $SERVICE_FILE"
    else
        error "Failed to remove service file: $SERVICE_FILE"
    fi
    
    # Reload systemd daemon
    systemctl --user daemon-reload
    success "Systemd daemon reloaded"
else
    if [ "$SYSTEMCTL_AVAILABLE" = false ]; then
        warning "Systemctl not available. Skipping service removal."
    else
        warning "Service file not found: $SERVICE_FILE"
    fi
fi

# Remove desktop entry if exists
DESKTOP_FILE="$HOME/.config/autostart/network_switcher.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    rm -f "$DESKTOP_FILE"
    success "Desktop autostart entry removed"
fi

# Optional: Ask if user wants to remove Python dependencies
echo -e "\n${YELLOW}Do you want to uninstall Python dependencies (pystray, Pillow)? (y/n)${NC}"
echo -e "${YELLOW}Note: These packages might be used by other applications.${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    if pip3 uninstall -y pystray Pillow 2>/dev/null; then
        success "Python dependencies uninstalled"
    else
        warning "Failed to uninstall Python dependencies (they may not be installed)"
    fi
else
    echo "Python dependencies kept."
fi

# Uninstallation summary
echo -e "\n${GREEN}=== Uninstallation Complete ===${NC}\n"
echo "Network Switcher has been uninstalled successfully!"
echo -e "\n${YELLOW}The application files in $SCRIPT_DIR have been kept.${NC}"
echo "If you want to completely remove the application, manually delete:"
echo "  rm -rf $SCRIPT_DIR"
echo -e "\n${GREEN}To reinstall, run:${NC}"
echo "  $SCRIPT_DIR/install.sh"
echo ""
