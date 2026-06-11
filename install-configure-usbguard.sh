#!/usr/bin/env bash
set -euo pipefail

RULES_FILE="/etc/usbguard/rules.conf"
DAEMON_CONF="/etc/usbguard/usbguard-daemon.conf"
BACKUP_DIR="/root/usbguard-backup-$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    echo "Run it with: sudo $0"
    exit 1
fi

echo "[1/7] Installing USBGuard..."
dnf install -y usbguard

echo "[2/7] Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

if [[ -f "$RULES_FILE" ]]; then
    cp -a "$RULES_FILE" "$BACKUP_DIR/rules.conf.bak"
fi

if [[ -f "$DAEMON_CONF" ]]; then
    cp -a "$DAEMON_CONF" "$BACKUP_DIR/usbguard-daemon.conf.bak"
fi

echo "[3/7] Generating allow policy for currently connected USB devices..."
usbguard generate-policy --no-hashes > "$RULES_FILE"

chmod 600 "$RULES_FILE"
chown root:root "$RULES_FILE"

echo "[4/7] Configuring USBGuard daemon..."

set_config_value() {
    local key="$1"
    local value="$2"
    local file="$3"

    if grep -qE "^[#[:space:]]*${key}=" "$file"; then
        sed -i -E "s|^[#[:space:]]*${key}=.*|${key}=${value}|" "$file"
    else
        echo "${key}=${value}" >> "$file"
    fi
}

set_config_value "RuleFile" "$RULES_FILE" "$DAEMON_CONF"
set_config_value "ImplicitPolicyTarget" "block" "$DAEMON_CONF"
set_config_value "PresentDevicePolicy" "apply-policy" "$DAEMON_CONF"
set_config_value "PresentControllerPolicy" "keep" "$DAEMON_CONF"
set_config_value "InsertedDevicePolicy" "apply-policy" "$DAEMON_CONF"

echo "[5/7] Enabling USBGuard..."
systemctl enable usbguard

echo "[6/7] Starting/restarting USBGuard..."
systemctl restart usbguard

echo "[7/7] Verifying status..."
systemctl --no-pager --full status usbguard || true

echo
echo "USBGuard installation and configuration completed."
echo
echo "Current policy file:"
echo "  $RULES_FILE"
echo
echo "Backup directory:"
echo "  $BACKUP_DIR"
echo
echo "Currently known devices:"
usbguard list-devices || true
echo
echo "Active rules:"
usbguard list-rules || true
