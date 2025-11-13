#!/bin/bash

# Build script for Network Switcher .deb package
# This script automatically generates all debian/* files and builds the package

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Building Network Switcher .deb Package ===${NC}\n"

# Get version from Python script (extract directly without executing)
VERSION=$(grep -oP '__version__\s*=\s*["'"'"']\K[^"'"'"']+' network_switcher.py 2>/dev/null || echo "1.0.0")

# If version extraction failed, use default
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTHOR="${DEBFULLNAME:-Network Switcher Team}"
EMAIL="${DEBEMAIL:-maintainer@example.com}"

echo -e "${BLUE}Version: $VERSION${NC}"
echo -e "${BLUE}Maintainer: $AUTHOR <$EMAIL>${NC}"

# Check if we're on a Debian-based system
if ! command -v dpkg-buildpackage &> /dev/null; then
    echo -e "${RED}❌ dpkg-buildpackage is not installed${NC}"
    echo ""
    echo "Install build tools:"
    echo "  sudo apt-get install build-essential debhelper dh-python"
    exit 1
fi

echo -e "${GREEN}✓ Debian build tools are installed${NC}"

# Check if we're in the right directory
if [ ! -f "network_switcher.py" ]; then
    echo -e "${RED}❌ network_switcher.py not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo -e "${GREEN}✓ Project files found${NC}"

# Install build dependencies
echo ""
echo -e "${BLUE}Installing build dependencies...${NC}"

# First, install basic Debian build tools
echo "Installing Debian build essentials..."
if ! sudo apt-get update -qq; then
    echo -e "${YELLOW}⚠ apt update had warnings, continuing...${NC}"
fi

# Install debhelper and related tools
DEBIAN_PKGS="build-essential debhelper dh-python python3-all python3-setuptools python3-pip python3-pil"
echo "Installing: $DEBIAN_PKGS"
if sudo apt-get install -y $DEBIAN_PKGS; then
    echo -e "${GREEN}✓ Debian build tools installed${NC}"
else
    echo -e "${RED}❌ Failed to install Debian build tools${NC}"
    exit 1
fi

# Handle python3-pystray (may not be in repos, install via pip as fallback)
echo ""
echo "Checking for python3-pystray..."
if apt-cache show python3-pystray &>/dev/null; then
    echo "python3-pystray found in repositories, installing..."
    sudo apt-get install -y python3-pystray || true
else
    echo -e "${YELLOW}⚠ python3-pystray not in apt repositories${NC}"
    echo "Installing pystray via pip3..."
    if sudo pip3 install pystray>=0.19.4; then
        echo -e "${GREEN}✓ pystray installed via pip3${NC}"
    else
        echo -e "${RED}❌ Failed to install pystray${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ All build dependencies installed${NC}"

# Clean previous builds
echo ""
echo -e "${BLUE}Cleaning previous builds...${NC}"
rm -rf debian/network-switcher debian/.debhelper debian/files debian/*.substvars debian/debhelper-build-stamp
rm -f ../*.deb ../*.build* ../*.changes ../*.dsc 2>/dev/null || true

# Create debian directory
echo -e "${BLUE}Creating debian directory structure...${NC}"
mkdir -p debian

# Generate debian/control
echo -e "${BLUE}Generating debian/control...${NC}"

# Detect debhelper version available on system
DEBHELPER_VERSION=$(dpkg -l debhelper 2>/dev/null | grep '^ii' | awk '{print $3}' | cut -d. -f1 || echo "12")
if [ "$DEBHELPER_VERSION" -ge 13 ]; then
    DEBHELPER_COMPAT="debhelper-compat (= 13)"
    COMPAT_LEVEL="13"
else
    DEBHELPER_COMPAT="debhelper (>= 9)"
    COMPAT_LEVEL="12"
fi

echo "Using debhelper compat level: $COMPAT_LEVEL"

cat > debian/control << EOF
Source: network-switcher
Section: net
Priority: optional
Maintainer: $AUTHOR <$EMAIL>
Build-Depends: $DEBHELPER_COMPAT,
               dh-python,
               python3-all,
               python3-setuptools,
               python3-pil
Standards-Version: 4.6.0
Homepage: https://github.com/farman20ali/network_switcher
Vcs-Browser: https://github.com/farman20ali/network_switcher
Vcs-Git: https://github.com/farman20ali/network_switcher.git

Package: network-switcher
Architecture: all
Depends: \${python3:Depends},
         \${misc:Depends},
         python3 (>= 3.6),
         python3-pil,
         python3-gi,
         python3-pip,
         network-manager,
         gir1.2-ayatanaappindicator3-0.1 | gir1.2-appindicator3-0.1,
         libayatana-appindicator3-1
Description: Quick network mode switcher for Linux
 Network Switcher is a lightweight system tray application that allows you to
 quickly switch between different network modes (Wi-Fi, Wired, Both, Hotspot)
 using NetworkManager.
 .
 Features:
  - Switch between Wi-Fi and Wired connections
  - Enable both connections simultaneously
  - Turn on hotspot mode
  - Disable all connections
  - Real-time connection status display
  - System tray integration
  - systemd service support
EOF

# Generate debian/rules
echo -e "${BLUE}Generating debian/rules...${NC}"
cat > debian/rules << 'EOF'
#!/usr/bin/make -f

%:
	dh $@

override_dh_auto_build:
	# No build needed - pure Python script

override_dh_auto_install:
	# Install the main script
	install -D -m 755 network_switcher.py debian/network-switcher/usr/bin/network-switcher
	# Install the icon
	install -D -m 644 network_icon.png debian/network-switcher/usr/share/pixmaps/network-switcher.png
	# Install desktop file
	install -D -m 644 network_switcher.desktop debian/network-switcher/usr/share/applications/network-switcher.desktop
	# Install systemd service
	install -D -m 644 network-switcher.service debian/network-switcher/lib/systemd/user/network-switcher.service
	# Install requirements.txt
	install -D -m 644 requirements.txt debian/network-switcher/usr/share/doc/network-switcher/requirements.txt

override_dh_install:
	dh_install
	# Fix paths in installed files
	sed -i 's|/home/.*/network_switcher.py|/usr/bin/network-switcher|g' \
		debian/network-switcher/lib/systemd/user/network-switcher.service || true
	sed -i 's|/home/.*/network_icon.png|/usr/share/pixmaps/network-switcher.png|g' \
		debian/network-switcher/usr/share/applications/network-switcher.desktop || true
	sed -i 's|Exec=nohup.*|Exec=/usr/bin/network-switcher|g' \
		debian/network-switcher/usr/share/applications/network-switcher.desktop || true

override_dh_auto_test:
	# Skip tests for now

override_dh_usrlocal:
	# Don't warn about /usr/local
EOF

chmod +x debian/rules

# Generate debian/changelog
echo -e "${BLUE}Generating debian/changelog...${NC}"
cat > debian/changelog << EOF
network-switcher ($VERSION-1) unstable; urgency=medium

  * Version $VERSION release
  * Features:
    - System tray network mode switcher
    - Support for Wi-Fi, Wired, Both, and Hotspot modes
    - Real-time connection status display
    - systemd service integration
    - Automatic dependency installation
  * Improvements:
    - Comprehensive documentation
    - Automated installation scripts
    - Multiple package formats (snap, deb)

 -- $AUTHOR <$EMAIL>  $(date -R)
EOF

# Generate debian/compat
echo -e "${BLUE}Generating debian/compat...${NC}"
echo "$COMPAT_LEVEL" > debian/compat

# Generate debian/copyright
echo -e "${BLUE}Generating debian/copyright...${NC}"
cat > debian/copyright << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: network-switcher
Upstream-Contact: https://github.com/farman20ali/network_switcher
Source: https://github.com/farman20ali/network_switcher

Files: *
Copyright: $(date +%Y) Network Switcher Contributors
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
EOF

echo -e "${GREEN}✓ All debian/* files generated${NC}"

# Generate debian/postinst to install pystray after package installation
echo -e "${BLUE}Generating debian/postinst...${NC}"
cat > debian/postinst << 'EOF'
#!/bin/bash
set -e

# Install pystray via pip if not already installed
if ! python3 -c "import pystray" 2>/dev/null; then
    echo "Installing pystray via pip3..."
    pip3 install --system pystray>=0.19.4 2>/dev/null || pip3 install pystray>=0.19.4
fi

# Create a helper script in /etc/profile.d/ to auto-enable on first login
cat > /etc/profile.d/network-switcher-setup.sh << 'PROFILE_EOF'
# Network Switcher Auto-Setup
# This script runs once on first login after package installation

if [ -f /usr/lib/systemd/user/network-switcher.service ]; then
    # Check if service is already enabled/setup
    if ! systemctl --user is-enabled network-switcher.service >/dev/null 2>&1; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📦 Network Switcher - First Time Setup"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "� Enabling Network Switcher service..."
        
        systemctl --user daemon-reload 2>/dev/null
        systemctl --user enable network-switcher.service 2>/dev/null
        systemctl --user start network-switcher.service 2>/dev/null
        
        if systemctl --user is-active network-switcher.service >/dev/null 2>&1; then
            echo "✅ Network Switcher started successfully!"
            echo "✨ The tray icon should appear in your system tray"
        else
            echo "⚠️  Service enabled but not started yet"
            echo "💡 Try: systemctl --user start network-switcher.service"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Remove this script after first run
        sudo rm -f /etc/profile.d/network-switcher-setup.sh 2>/dev/null || true
    fi
fi
PROFILE_EOF

chmod +x /etc/profile.d/network-switcher-setup.sh

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Network Switcher Installed Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Choose one of these options:"
echo ""
echo "Option 1: Start immediately (recommended)"
echo "  systemctl --user daemon-reload && systemctl --user enable --now network-switcher.service"
echo ""
echo "Option 2: Wait for next login"
echo "  The service will auto-enable on your next login/logout"
echo ""
echo "🎯 Choose one of these options:"
echo ""
echo "Option 1: Start immediately (recommended)"
echo "  systemctl --user daemon-reload && systemctl --user enable --now network-switcher.service"
echo ""
echo "Option 2: Wait for next login"
echo "  The service will auto-enable on your next login/logout"
echo ""
echo "Option 3: Start manually later"
echo "  systemctl --user start network-switcher.service"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Troubleshooting:"
echo ""
echo "If installation failed with dependency errors, install missing packages:"
echo "  sudo apt-get install gir1.2-ayatanaappindicator3-0.1 python3-gi"
echo "  pip3 install pystray>=0.19.4"
echo ""
echo "Then try installing the package again:"
echo "  sudo dpkg -i network-switcher_1.0.0-1_all.deb"
echo ""
echo "To check service logs:"
echo "  journalctl --user -u network-switcher.service -f"
echo ""
echo "To check service status:"
echo "  systemctl --user status network-switcher.service"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

#DEBHELPER#

exit 0
EOF

chmod +x debian/postinst

# Generate debian/postrm to clean up on uninstall
echo -e "${BLUE}Generating debian/postrm...${NC}"
cat > debian/postrm << 'EOF'
#!/bin/bash
set -e

# Only run cleanup on complete removal (not on upgrade)
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    # Remove the profile.d setup script if it still exists
    rm -f /etc/profile.d/network-switcher-setup.sh 2>/dev/null || true
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Network Switcher Uninstalled"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 To stop and disable the user service, run:"
    echo "  systemctl --user stop network-switcher.service"
    echo "  systemctl --user disable network-switcher.service"
    echo "  systemctl --user daemon-reload"
    echo ""
    echo "📁 To remove configuration files:"
    echo "  rm -rf ~/.config/network-switcher/"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

#DEBHELPER#

exit 0
EOF

chmod +x debian/postrm

echo ""
echo -e "${BLUE}Building .deb package...${NC}"
echo "This may take a few minutes..."
echo ""

# Build the package
echo "Running dpkg-buildpackage..."
BUILD_LOG="/tmp/deb-build-$$.log"

if dpkg-buildpackage -us -uc -b 2>&1 | tee "$BUILD_LOG"; then
    BUILD_EXIT_CODE=${PIPESTATUS[0]}
else
    BUILD_EXIT_CODE=$?
fi

# Check if build actually succeeded
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ .deb build FAILED (exit code: $BUILD_EXIT_CODE)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Build log saved to: $BUILD_LOG${NC}"
    echo ""
    echo -e "${YELLOW}Common issues:${NC}"
    echo "  • Missing build dependencies (check Build-Depends in debian/control)"
    echo "  • Syntax errors in debian/rules"
    echo "  • File permission issues"
    echo ""
    echo -e "${YELLOW}To retry after fixing:${NC}"
    echo "  ./build-deb.sh"
    echo ""
    exit 1
fi

# Verify .deb file was created
DEB_FILE=$(ls -t ../*.deb 2>/dev/null | head -1)

if [ -z "$DEB_FILE" ] || [ ! -f "$DEB_FILE" ]; then
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ Build reported success but no .deb file found!${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Expected location: ../*.deb${NC}"
    echo -e "${YELLOW}Build log: $BUILD_LOG${NC}"
    echo ""
    exit 1
fi

# Success!
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ .deb package built successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}📦 Package: $DEB_FILE${NC}"
echo -e "${GREEN}📊 Size: $(du -h "$DEB_FILE" | cut -f1)${NC}"
echo ""

# Copy .deb to current directory for convenience
DEB_BASENAME=$(basename "$DEB_FILE")
cp "$DEB_FILE" "./$DEB_BASENAME"
echo -e "${GREEN}📋 Copied to: ./$DEB_BASENAME${NC}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📖 INSTALLATION INSTRUCTIONS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Step 1: Install the package${NC}"
echo "  sudo dpkg -i $DEB_BASENAME"
echo ""
echo -e "${YELLOW}Step 2: Start the service (run as your user, not root)${NC}"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now network-switcher.service"
echo ""
echo -e "${YELLOW}Or run separately:${NC}"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable network-switcher.service"
echo "  systemctl --user start network-switcher.service"
echo ""
echo -e "${GREEN}✨ The tray icon will appear in your system tray!${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Other useful commands:${NC}"
echo ""
echo -e "  Check service status:"
echo "    systemctl --user status network-switcher.service"
echo ""
echo -e "  View logs:"
echo "    journalctl --user -u network-switcher.service -f"
echo ""
echo -e "  If dependencies are missing:"
echo "    sudo apt-get install -f"
echo ""
echo -e "  To uninstall:"
echo "    systemctl --user stop network-switcher.service"
echo "    systemctl --user disable network-switcher.service"
echo "    sudo apt remove network-switcher"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Note: debian/ directory contains generated packaging files.${NC}"
echo -e "${GREEN}Edit build-deb.sh to modify the package configuration.${NC}"
echo ""

# Clean up build log if successful
rm -f "$BUILD_LOG"

exit 0
