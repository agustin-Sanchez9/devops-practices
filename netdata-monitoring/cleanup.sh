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

info "Starting Netdata cleanup..."

# Stop Netdata service first
info "Stopping Netdata service..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop netdata 2>/dev/null || systemctl stop netdata.service 2>/dev/null || true
    systemctl disable netdata 2>/dev/null || systemctl disable netdata.service 2>/dev/null || true
elif command -v service >/dev/null 2>&1; then
    service netdata stop 2>/dev/null || true
fi

# Try to find and run the official Netdata uninstaller
UNINSTALLER=""
for path in /opt/netdata/usr/libexec/netdata-uninstaller.sh \
            /usr/libexec/netdata-uninstaller.sh \
            /opt/netdata/netdata-uninstaller.sh; do
    if [ -f "$path" ]; then
        UNINSTALLER="$path"
        break
    fi
done

if [ -n "$UNINSTALLER" ]; then
    info "Found official uninstaller at: $UNINSTALLER"
    bash "$UNINSTALLER" --yes --force 2>/dev/null || warn "Uninstaller script exited with errors"
else
    warn "Official uninstaller not found. Attempting package manager removal..."
fi

# Also try package manager removal for native package installs
if command -v apt-get >/dev/null 2>&1; then
    info "Removing Netdata via apt..."
    apt-get remove --purge -y netdata netdata-core netdata-web 2>/dev/null || true
    apt-get autoremove -y 2>/dev/null || true
fi

if command -v dnf >/dev/null 2>&1; then
    info "Removing Netdata via dnf..."
    dnf remove -y netdata 2>/dev/null || true
fi

if command -v yum >/dev/null 2>&1; then
    info "Removing Netdata via yum..."
    yum remove -y netdata 2>/dev/null || true
fi

if command -v pacman >/dev/null 2>&1; then
    info "Removing Netdata via pacman..."
    pacman -Rns netdata 2>/dev/null || true
fi

# Clean up remaining files and directories
info "Removing remaining Netdata files..."
rm -rf /opt/netdata
rm -rf /etc/netdata
rm -rf /var/cache/netdata
rm -rf /var/lib/netdata
rm -rf /var/log/netdata
rm -rf /usr/share/netdata
rm -rf /usr/lib/netdata

# Remove Netdata user if it exists
if id -u netdata >/dev/null 2>&1; then
    info "Removing netdata user..."
    userdel netdata 2>/dev/null || true
fi

# Remove any firewall rules added by setup
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
    info "Closing port 19999 in firewalld..."
    firewall-cmd --permanent --remove-port=19999/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
fi

if command -v ufw >/dev/null 2>&1; then
    info "Closing port 19999 in ufw..."
    ufw delete allow 19999/tcp 2>/dev/null || true
fi

info "Netdata cleanup complete."
