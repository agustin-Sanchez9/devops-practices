#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}WARN: $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error_exit "Please run as root (use sudo)"
fi

info "Starting Netdata installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    error_exit "Cannot detect operating system"
fi

# Install dependencies if needed
info "Installing dependencies..."
case "$OS" in
    ubuntu|debian)
        apt-get update -qq
        apt-get install -y -qq curl wget systemd 2>/dev/null || true
        ;;
    fedora|rhel|centos|rocky|almalinux)
        dnf install -y -q curl wget systemd 2>/dev/null || \
        yum install -y -q curl wget systemd 2>/dev/null || true
        ;;
    arch|manjaro)
        pacman -Sy --noconfirm curl wget systemd 2>/dev/null || true
        ;;
    *)
        warn "Unknown OS: $OS. Attempting generic install..."
        ;;
esac

# Install Netdata using official kickstart script
info "Installing Netdata via official installer..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://get.netdata.cloud/kickstart.sh -o /tmp/netdata-kickstart.sh
elif command -v wget >/dev/null 2>&1; then
    wget -q https://get.netdata.cloud/kickstart.sh -O /tmp/netdata-kickstart.sh
else
    error_exit "Neither curl nor wget is available. Please install one of them."
fi

bash /tmp/netdata-kickstart.sh --stable-channel --dont-wait --disable-telemetry || \
    error_exit "Netdata installation failed"

rm -f /tmp/netdata-kickstart.sh

# Find Netdata configuration directory
NETDATA_CONFIG_DIR=""
for dir in /etc/netdata /opt/netdata/etc/netdata; do
    if [ -d "$dir" ]; then
        NETDATA_CONFIG_DIR="$dir"
        break
    fi
done

# Open firewall port 19999 if firewalld or ufw is active
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
    info "Opening port 19999 in firewalld..."
    firewall-cmd --permanent --add-port=19999/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
fi

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    info "Opening port 19999 in ufw..."
    ufw allow 19999/tcp 2>/dev/null || true
fi

# Get IP address for dashboard URL
IP_ADDRESS=$(hostname -I | awk '{print $1}')
[ -z "$IP_ADDRESS" ] && IP_ADDRESS="localhost"

info "Netdata installation complete!"
echo ""
echo -e "${GREEN}Dashboard URL: http://${IP_ADDRESS}:19999${NC}"
echo -e "${GREEN}Local URL:     http://localhost:19999${NC}"
echo ""
echo "To test the dashboard, run: ./test_dashboard.sh"
echo "To remove Netdata, run:     ./cleanup.sh"
