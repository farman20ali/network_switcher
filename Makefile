# Makefile for Network Switcher

.PHONY: help install uninstall check clean test run deb all

help:
	@echo "════════════════════════════════════════════════════════════"
	@echo "  Network Switcher - Makefile Commands"
	@echo "════════════════════════════════════════════════════════════"
	@echo ""
	@echo "📦 Installation:"
	@echo "  make install         - Install Network Switcher"
	@echo "  make uninstall       - Uninstall Network Switcher"
	@echo "  make check           - Check dependencies"
	@echo ""
	@echo "🔧 Development:"
	@echo "  make run             - Run the application"
	@echo "  make icon            - Generate default icon"
	@echo "  make test-syntax     - Check Python syntax"
	@echo "  make version         - Show application version"
	@echo ""
	@echo "📦 Packaging:"
	@echo "  make deb             - Build .deb package"
	@echo "  make deb-test        - Build and test .deb package"
	@echo ""
	@echo "⚙️  Service Management:"
	@echo "  make service-start   - Start the systemd service"
	@echo "  make service-stop    - Stop the systemd service"
	@echo "  make service-restart - Restart the systemd service"
	@echo "  make service-status  - Check service status"
	@echo "  make service-enable  - Enable service (auto-start)"
	@echo "  make service-disable - Disable service"
	@echo "  make logs            - View service logs"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean           - Clean temporary files"
	@echo "  make clean-all       - Deep clean (includes packages)"
	@echo ""
	@echo "════════════════════════════════════════════════════════════"

install:
	@echo "Installing Network Switcher..."
	@./install.sh

uninstall:
	@echo "Uninstalling Network Switcher..."
	@./uninstall.sh

check:
	@echo "Checking dependencies..."
	@./check_dependencies.sh

run:
	@echo "Running Network Switcher..."
	@./network_switcher.py

icon:
	@echo "🎨 Generating default network icon..."
	@python3 create_icon.py
	@echo "✅ Icon created: network_icon.png"

deb:
	@echo "📦 Building .deb package..."
	@./build-deb.sh

deb-test: deb
	@echo ""
	@echo "🧪 Testing .deb package..."
	@if [ -f network-switcher_*.deb ]; then \
		echo "📋 Package info:"; \
		dpkg-deb --info network-switcher_*.deb; \
		echo ""; \
		echo "📂 Package contents:"; \
		dpkg-deb --contents network-switcher_*.deb | head -20; \
		echo ""; \
		echo "✅ Package ready for installation!"; \
		echo "   To install: sudo dpkg -i network-switcher_*.deb"; \
	else \
		echo "❌ No .deb package found"; \
		exit 1; \
	fi

service-start:
	@echo "🚀 Starting service..."
	@systemctl --user start network-switcher.service
	@echo "✅ Service started!"

service-stop:
	@echo "🛑 Stopping service..."
	@systemctl --user stop network-switcher.service
	@echo "✅ Service stopped!"

service-restart:
	@echo "🔄 Restarting service..."
	@systemctl --user restart network-switcher.service
	@echo "✅ Service restarted!"

service-status:
	@echo "📊 Service status:"
	@systemctl --user status network-switcher.service --no-pager || true

service-enable:
	@echo "⚡ Enabling service (auto-start on login)..."
	@systemctl --user enable network-switcher.service
	@echo "✅ Service enabled!"

service-disable:
	@echo "🔌 Disabling service..."
	@systemctl --user disable network-switcher.service
	@echo "✅ Service disabled!"

logs:
	@echo "📝 Viewing service logs (Ctrl+C to exit)..."
	@journalctl --user -u network-switcher.service -f

logs-recent:
	@echo "📝 Recent logs (last 50 lines):"
	@journalctl --user -u network-switcher.service -n 50 --no-pager

clean:
	@echo "🧹 Cleaning temporary files..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@rm -f nohup.out *.log
	@rm -rf build/ dist/ *.egg-info/
	@echo "✅ Clean complete!"

clean-all: clean
	@echo "🧹 Deep cleaning (removing packages and build artifacts)..."
	@rm -rf debian/network-switcher debian/.debhelper debian/files debian/*.substvars debian/tmp
	@rm -f ../*.deb ../*.build* ../*.changes ../*.dsc 2>/dev/null || true
	@rm -f network-switcher_*.deb
	@echo "✅ Deep clean complete!"

test-syntax:
	@echo "🔍 Checking Python syntax..."
	@python3 -m py_compile network_switcher.py
	@python3 -m py_compile create_icon.py
	@echo "✅ Syntax check passed!"

test-imports:
	@echo "🔍 Testing Python imports..."
	@python3 -c "import pystray; import PIL; print('✅ All required modules found')" || \
		echo "❌ Missing dependencies. Run: make check"

version:
	@python3 network_switcher.py --version

all: check deb
	@echo ""
	@echo "✅ Build complete!"
	@echo "📦 Package ready: network-switcher_*.deb"
