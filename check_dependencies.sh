#!/bin/bash

# Dependency Check Script for Network Switcher
# This script checks if all required dependencies are installed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Network Switcher Dependency Checker ===${NC}\n"

ALL_OK=true

# Function to check command availability
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $2 is installed"
        if [ ! -z "$3" ]; then
            VERSION=$($3 2>&1)
            echo -e "  ${BLUE}Version:${NC} $VERSION"
        fi
        return 0
    else
        echo -e "${RED}✗${NC} $2 is NOT installed"
        if [ ! -z "$4" ]; then
            echo -e "  ${YELLOW}Install:${NC} $4"
        fi
        ALL_OK=false
        return 1
    fi
}

# Function to check Python module
check_python_module() {
    if python3 -c "import $1" 2>/dev/null; then
        VERSION=$(python3 -c "import $1; print($1.__version__ if hasattr($1, '__version__') else 'installed')" 2>/dev/null)
        echo -e "${GREEN}✓${NC} Python module '$1' is installed (version: $VERSION)"
        return 0
    else
        echo -e "${RED}✗${NC} Python module '$1' is NOT installed"
        echo -e "  ${YELLOW}Install:${NC} pip3 install --user $2"
        ALL_OK=false
        return 1
    fi
}

echo -e "${BLUE}Checking System Requirements...${NC}\n"

# Check OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${GREEN}✓${NC} Operating System: Linux"
else
    echo -e "${RED}✗${NC} Operating System: $OSTYPE (Linux required)"
    ALL_OK=false
fi

# Check Python
echo ""
check_command "python3" "Python 3" "python3 --version" "sudo apt-get install python3"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 6 ]; then
        echo -e "${GREEN}✓${NC} Python version is compatible (>= 3.6)"
    else
        echo -e "${RED}✗${NC} Python version $PYTHON_VERSION is too old (need >= 3.6)"
        ALL_OK=false
    fi
fi

# Check pip
echo ""
check_command "pip3" "pip3" "pip3 --version" "sudo apt-get install python3-pip"

# Check NetworkManager
echo ""
check_command "nmcli" "NetworkManager (nmcli)" "nmcli --version" "sudo apt-get install network-manager"

# Check systemd (optional)
echo ""
if check_command "systemctl" "systemd" "systemctl --version"; then
    echo -e "  ${BLUE}Note:${NC} systemd is available for service management"
else
    echo -e "  ${YELLOW}Note:${NC} systemd not available. Service features will be limited."
fi

# Check display server
echo ""
if [ ! -z "$DISPLAY" ] || [ ! -z "$WAYLAND_DISPLAY" ]; then
    echo -e "${GREEN}✓${NC} Display server detected"
    if [ ! -z "$DISPLAY" ]; then
        echo -e "  ${BLUE}X11 Display:${NC} $DISPLAY"
    fi
    if [ ! -z "$WAYLAND_DISPLAY" ]; then
        echo -e "  ${BLUE}Wayland Display:${NC} $WAYLAND_DISPLAY"
    fi
else
    echo -e "${YELLOW}⚠${NC} No display server detected"
    echo -e "  ${YELLOW}Note:${NC} The tray icon may not work in headless environments"
fi

# Check Python modules
echo -e "\n${BLUE}Checking Python Dependencies...${NC}\n"

check_python_module "pystray" "pystray"
check_python_module "PIL" "Pillow"

# Check for network icon
echo -e "\n${BLUE}Checking Application Files...${NC}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/network_switcher.py" ]; then
    echo -e "${GREEN}✓${NC} network_switcher.py found"
    if [ -x "$SCRIPT_DIR/network_switcher.py" ]; then
        echo -e "${GREEN}✓${NC} network_switcher.py is executable"
    else
        echo -e "${YELLOW}⚠${NC} network_switcher.py is not executable"
        echo -e "  ${YELLOW}Fix:${NC} chmod +x $SCRIPT_DIR/network_switcher.py"
    fi
else
    echo -e "${RED}✗${NC} network_switcher.py NOT found"
    ALL_OK=false
fi

if [ -f "$SCRIPT_DIR/network_icon.png" ]; then
    echo -e "${GREEN}✓${NC} network_icon.png found"
else
    echo -e "${YELLOW}⚠${NC} network_icon.png NOT found"
    echo -e "  ${YELLOW}Note:${NC} The app will use a default blue icon"
    echo -e "  ${YELLOW}Generate:${NC} python3 create_icon.py"
fi

if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    echo -e "${GREEN}✓${NC} requirements.txt found"
else
    echo -e "${YELLOW}⚠${NC} requirements.txt NOT found"
fi

# Check desktop environment tray support
echo -e "\n${BLUE}Checking Desktop Environment...${NC}\n"

if [ ! -z "$XDG_CURRENT_DESKTOP" ]; then
    echo -e "${BLUE}Desktop Environment:${NC} $XDG_CURRENT_DESKTOP"
    
    case "$XDG_CURRENT_DESKTOP" in
        *GNOME*)
            echo -e "${YELLOW}⚠${NC} GNOME detected"
            echo -e "  ${YELLOW}Note:${NC} You may need the AppIndicator extension for tray icons"
            echo -e "  ${YELLOW}Install:${NC} https://extensions.gnome.org/extension/615/appindicator-support/"
            ;;
        *KDE*|*XFCE*|*MATE*|*Cinnamon*)
            echo -e "${GREEN}✓${NC} Desktop environment typically supports system tray icons"
            ;;
        *)
            echo -e "${YELLOW}⚠${NC} Unknown desktop environment. Tray support may vary."
            ;;
    esac
else
    echo -e "${YELLOW}⚠${NC} Desktop environment not detected"
fi

# Summary
echo -e "\n${BLUE}=== Summary ===${NC}\n"

if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}✓ All required dependencies are installed!${NC}"
    echo -e "\nYou can install Network Switcher with:"
    echo -e "  ${BLUE}./install.sh${NC}"
    echo -e "\nOr run it manually:"
    echo -e "  ${BLUE}./network_switcher.py${NC}"
    exit 0
else
    echo -e "${RED}✗ Some dependencies are missing.${NC}"
    echo -e "\n${YELLOW}Quick fix for Ubuntu/Debian:${NC}"
    echo -e "  sudo apt-get update"
    echo -e "  sudo apt-get install python3 python3-pip network-manager"
    echo -e "  pip3 install --user pystray Pillow"
    echo -e "\n${YELLOW}Quick fix for Fedora/RHEL:${NC}"
    echo -e "  sudo dnf install python3 python3-pip NetworkManager"
    echo -e "  pip3 install --user pystray Pillow"
    echo -e "\n${YELLOW}Quick fix for Arch Linux:${NC}"
    echo -e "  sudo pacman -S python python-pip networkmanager"
    echo -e "  pip3 install --user pystray Pillow"
    exit 1
fi
