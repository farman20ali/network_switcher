#!/bin/bash

# Network Switcher Installation Script
# This script installs the Network Switcher tray application
# With AUTOMATIC dependency installation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="network_switcher"
SERVICE_NAME="network-switcher.service"

# Detect if running with sudo
if [ "$EUID" -eq 0 ]; then
    SUDO=""
    REAL_USER=$SUDO_USER
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    SUDO="sudo"
    REAL_USER=$USER
    REAL_HOME=$HOME
fi

echo -e "${GREEN}=== Network Switcher Installation ===${NC}\n"

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

# Function to print info messages
info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
        DISTRO_VERSION=$DISTRIB_RELEASE
    else
        DISTRO="unknown"
    fi
    echo "$DISTRO"
}

# Install system dependencies automatically
install_system_dependencies() {
    local distro=$1
    info "Detected distribution: $distro"
    
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            info "Installing dependencies via apt..."
            $SUDO apt-get update -qq
            $SUDO apt-get install -y python3 python3-pip network-manager || {
                error "Failed to install system dependencies"
                return 1
            }
            ;;
        fedora|rhel|centos)
            info "Installing dependencies via dnf/yum..."
            $SUDO dnf install -y python3 python3-pip NetworkManager || \
            $SUDO yum install -y python3 python3-pip NetworkManager || {
                error "Failed to install system dependencies"
                return 1
            }
            ;;
        arch|manjaro)
            info "Installing dependencies via pacman..."
            $SUDO pacman -S --noconfirm python python-pip networkmanager || {
                error "Failed to install system dependencies"
                return 1
            }
            ;;
        opensuse*)
            info "Installing dependencies via zypper..."
            $SUDO zypper install -y python3 python3-pip NetworkManager || {
                error "Failed to install system dependencies"
                return 1
            }
            ;;
        *)
            warning "Unknown distribution. Please install manually:"
            echo "  - Python 3"
            echo "  - pip3"
            echo "  - NetworkManager"
            return 1
            ;;
    esac
    return 0
}

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    error "This application only works on Linux systems."
    exit 1
fi
success "Operating system check passed"

# Detect distribution
DISTRO=$(detect_distro)

# Check for required system tools
echo -e "\n${GREEN}Checking system dependencies...${NC}"

MISSING_TOOLS=()
AUTO_INSTALL=false

# Check for NetworkManager (nmcli)
if ! command -v nmcli &> /dev/null; then
    MISSING_TOOLS+=("network-manager")
    AUTO_INSTALL=true
fi

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    MISSING_TOOLS+=("python3")
    AUTO_INSTALL=true
fi

# Check for pip3
if ! command -v pip3 &> /dev/null; then
    MISSING_TOOLS+=("python3-pip")
    AUTO_INSTALL=true
fi

# Automatically install missing dependencies
if [ "$AUTO_INSTALL" = true ]; then
    warning "Some dependencies are missing: ${MISSING_TOOLS[*]}"
    echo -e "${BLUE}Attempting automatic installation...${NC}\n"
    
    if install_system_dependencies "$DISTRO"; then
        success "System dependencies installed successfully!"
    else
        error "Automatic installation failed. Please install manually:"
        echo "  Ubuntu/Debian: sudo apt-get install python3 python3-pip network-manager"
        echo "  Fedora/RHEL:   sudo dnf install python3 python3-pip NetworkManager"
        echo "  Arch Linux:    sudo pacman -S python python-pip networkmanager"
        exit 1
    fi
else
    success "All system dependencies are already installed"
fi

# Check for systemctl (systemd)
if ! command -v systemctl &> /dev/null; then
    warning "systemctl not found. Service installation will be skipped."
    SYSTEMCTL_AVAILABLE=false
else
    SYSTEMCTL_AVAILABLE=true
    success "systemd is available"
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 6 ]; }; then
    error "Python 3.6 or higher is required. Found: Python $PYTHON_VERSION"
    exit 1
fi
success "Python version check passed (v$PYTHON_VERSION)"

# Check for display server
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    warning "No display server detected. The tray icon may not work in headless environments."
fi

# Install Python dependencies
echo -e "\n${GREEN}Installing Python dependencies...${NC}"
if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    if pip3 install --user -r "$SCRIPT_DIR/requirements.txt"; then
        success "Python dependencies installed successfully"
    else
        error "Failed to install Python dependencies"
        echo -e "${YELLOW}Try running manually:${NC} pip3 install --user pystray Pillow"
        exit 1
    fi
else
    warning "requirements.txt not found. Installing packages manually..."
    if pip3 install --user pystray Pillow; then
        success "Python dependencies installed successfully"
    else
        error "Failed to install Python dependencies"
        exit 1
    fi
fi

# Make the Python script executable
chmod +x "$SCRIPT_DIR/network_switcher.py"
success "Made network_switcher.py executable"

# Check for network icon
if [ ! -f "$SCRIPT_DIR/network_icon.png" ]; then
    warning "network_icon.png not found. The app will use a default blue icon."
    echo "  You can add your own 64x64 PNG icon to: $SCRIPT_DIR/network_icon.png"
fi

# Install systemd service
if [ "$SYSTEMCTL_AVAILABLE" = true ]; then
    echo -e "\n${GREEN}Installing systemd service...${NC}"
    
    # Create systemd user directory if it doesn't exist
    mkdir -p "$HOME/.config/systemd/user/"
    
    # Copy service file and update paths
    SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME"
    
    # Create service file with absolute paths
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Network Switcher Tray Application
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
Environment=XAUTHORITY=%h/.Xauthority
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus
Environment=XDG_RUNTIME_DIR=/run/user/%U
ExecStart=$SCRIPT_DIR/network_switcher.py
Restart=always

[Install]
WantedBy=graphical-session.target
EOF
    
    success "Service file created at $SERVICE_FILE"
    
    # Reload systemd daemon
    systemctl --user daemon-reload
    success "Systemd daemon reloaded"
    
    # Ask user if they want to enable and start the service
    echo -e "\n${YELLOW}Do you want to enable and start the service now? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        systemctl --user enable "$SERVICE_NAME"
        success "Service enabled (will start on login)"
        
        systemctl --user start "$SERVICE_NAME"
        success "Service started"
        
        echo -e "\n${GREEN}Service status:${NC}"
        systemctl --user status "$SERVICE_NAME" --no-pager || true
    else
        echo -e "${YELLOW}Service installed but not enabled. You can enable it later with:${NC}"
        echo "  systemctl --user enable $SERVICE_NAME"
        echo "  systemctl --user start $SERVICE_NAME"
    fi
else
    warning "Systemd not available. Service installation skipped."
fi

# Installation summary
echo -e "\n${GREEN}=== Installation Complete ===${NC}\n"
echo "Network Switcher has been installed successfully!"
echo -e "\n${GREEN}Installation Directory:${NC} $SCRIPT_DIR"

if [ "$SYSTEMCTL_AVAILABLE" = true ]; then
    echo -e "\n${GREEN}Useful Commands:${NC}"
    echo "  Start service:   systemctl --user start $SERVICE_NAME"
    echo "  Stop service:    systemctl --user stop $SERVICE_NAME"
    echo "  Service status:  systemctl --user status $SERVICE_NAME"
    echo "  View logs:       journalctl --user -u $SERVICE_NAME -f"
    echo "  Enable on boot:  systemctl --user enable $SERVICE_NAME"
    echo "  Disable:         systemctl --user disable $SERVICE_NAME"
fi

echo -e "\n${GREEN}Manual Run:${NC}"
echo "  $SCRIPT_DIR/network_switcher.py"

echo -e "\n${GREEN}Uninstall:${NC}"
echo "  $SCRIPT_DIR/uninstall.sh"

echo -e "\n${YELLOW}Note:${NC} You may need to log out and log back in for the tray icon to appear."
echo -e "      If the icon doesn't appear, check if your desktop environment supports system tray icons.\n"
