#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script as root."
    echo "Example: sudo $0"
    exit 1
fi

echo "[1/5] Stopping and disabling usbguard service..."
systemctl disable --now usbguard 2>/dev/null || true

echo "[2/5] Removing usbguard package..."
dnf remove -y usbguard || true

echo "[3/5] Removing USBGuard configuration and state directories..."
rm -rf /etc/usbguard
rm -rf /var/log/usbguard
rm -rf /var/lib/usbguard

echo "[4/5] Reloading systemd..."
systemctl daemon-reload

echo "[5/5] Verifying removal..."

if rpm -q usbguard >/dev/null 2>&1; then
    echo "WARNING: usbguard package still appears to be installed."
else
    echo "OK: usbguard package is not installed."
fi

if systemctl list-unit-files | grep -q '^usbguard\.service'; then
    echo "WARNING: usbguard systemd unit still exists."
else
    echo "OK: usbguard systemd unit is gone."
fi

for path in /etc/usbguard /var/log/usbguard /var/lib/usbguard; do
    if [[ -e "$path" ]]; then
        echo "WARNING: $path still exists."
    else
        echo "OK: $path removed."
    fi
done

echo
echo "USBGuard removal completed."
