#!/bin/bash

# Quick GitHub Release Publishing Script
# This prepares your repository for creating a GitHub release

set -e

VERSION="1.0.0"
DEB_FILE="network-switcher_${VERSION}-1_all.deb"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       🚀 Network Switcher Release Publisher v${VERSION}           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if .deb exists
if [ ! -f "$DEB_FILE" ]; then
    echo -e "${RED}❌ $DEB_FILE not found!${NC}"
    echo ""
    echo "Build it first:"
    echo "  ./build-deb.sh"
    exit 1
fi

echo -e "${GREEN}✅ Found $DEB_FILE ($(du -h "$DEB_FILE" | cut -f1))${NC}"
echo ""

# Check if git is clean
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
    echo ""
    echo "Commit them first:"
    echo "  git add -A"
    echo "  git commit -m 'Release v${VERSION}'"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if tag exists
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Tag v${VERSION} already exists${NC}"
    echo ""
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting old tag..."
        git tag -d "v${VERSION}"
        git push origin ":refs/tags/v${VERSION}" 2>/dev/null || true
    else
        exit 1
    fi
fi

# Create git tag
echo -e "${BLUE}📌 Creating git tag v${VERSION}...${NC}"
git tag -a "v${VERSION}" -m "Release version ${VERSION} - Network Switcher .deb package"

echo -e "${BLUE}📤 Pushing tag to GitHub...${NC}"
if git push origin "v${VERSION}"; then
    echo ""
    echo -e "${GREEN}✅ Tag pushed successfully!${NC}"
else
    echo ""
    echo -e "${RED}❌ Failed to push tag${NC}"
    echo "Make sure you have push access to the repository"
    exit 1
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ TAG CREATED SUCCESSFULLY!                    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📋 Next steps to create GitHub Release:${NC}"
echo ""
echo "1. 🌐 Go to GitHub Releases:"
echo "   ${BLUE}https://github.com/farman20ali/network_switcher/releases/new${NC}"
echo ""
echo "2. 📌 Choose tag:"
echo "   Select: ${GREEN}v${VERSION}${NC}"
echo ""
echo "3. ✏️  Fill in release details:"
echo "   Title: ${GREEN}Network Switcher v${VERSION}${NC}"
echo "   Description: (See below)"
echo ""
echo "4. 📎 Upload the .deb file:"
echo "   ${GREEN}${DEB_FILE}${NC}"
echo ""
echo "5. 🎉 Click 'Publish release'"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📝 SUGGESTED RELEASE NOTES:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat << 'EOF'

# Network Switcher v1.0.0

A lightweight Linux system tray application to quickly switch between network modes (Wi-Fi, Wired, Both, Hotspot).

## ✨ Features

- 🖥️ System tray icon with intuitive menu
- 📶 Support for Wi-Fi, Wired, Both, and Hotspot modes
- 📊 Real-time connection status display
- 🔄 Automatic connection detection
- ⚙️ systemd service integration
- 🎨 Professional 256x256 icon with gradient effects

## 📦 Installation (Ubuntu/Debian)

Download the .deb package and install:

```bash
wget https://github.com/farman20ali/network_switcher/releases/download/v1.0.0/network-switcher_1.0.0-1_all.deb
sudo dpkg -i network-switcher_1.0.0-1_all.deb
```

Then choose one of these options to start the service:

**Option 1: Start immediately** ⚡
```bash
systemctl --user daemon-reload && systemctl --user enable --now network-switcher.service
```

**Option 2: Wait for next login** 🔄 (automatic)
Just logout and login - the service will auto-enable!

**Option 3: Start manually later** 🔧
```bash
systemctl --user start network-switcher.service
```

## 📋 Requirements

- Ubuntu 20.04+ / Debian 10+
- Python 3.6+
- NetworkManager
- Dependencies are auto-installed

## 🔧 Verify Installation

```bash
systemctl --user status network-switcher.service
```

The tray icon should appear in your system tray!

## 📖 Full Documentation

- [README.md](https://github.com/farman20ali/network_switcher/blob/master/README.md)
- [Installation Guide](https://github.com/farman20ali/network_switcher/blob/master/INSTALL.md)
- [Auto-Enable Feature](https://github.com/farman20ali/network_switcher/blob/master/AUTO_ENABLE_FEATURE.md)

## 🗑️ Uninstall

```bash
systemctl --user stop network-switcher.service
systemctl --user disable network-switcher.service
sudo apt remove network-switcher
```

## 📊 What's Included

- System tray application
- Professional icon (256x256)
- systemd user service
- Auto-enable on login script
- Comprehensive logging

## 🐛 Known Issues

None currently reported.

## 📞 Support

If you encounter issues:
- Check the [Installation Guide](https://github.com/farman20ali/network_switcher/blob/master/INSTALL.md)
- View logs: `journalctl --user -u network-switcher.service -f`
- Open an issue: [GitHub Issues](https://github.com/farman20ali/network_switcher/issues)

---

**Package Details:**
- Version: 1.0.0-1
- Architecture: all (platform independent)
- Size: 488KB
- License: MIT

EOF
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${GREEN}🎉 Ready to publish!${NC}"
echo ""
echo "After creating the release on GitHub, users can install with:"
echo ""
echo -e "${BLUE}  wget https://github.com/farman20ali/network_switcher/releases/download/v${VERSION}/network-switcher_${VERSION}-1_all.deb${NC}"
echo -e "${BLUE}  sudo dpkg -i network-switcher_${VERSION}-1_all.deb${NC}"
echo ""
