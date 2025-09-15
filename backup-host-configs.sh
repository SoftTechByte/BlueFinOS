#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/backups/host"
mkdir -p "$BACKUP_DIR"

echo "==> Backing up Bluefin OS host configurations..."

# 1. Save the list of layered packages
echo "Saving layered package list..."
rpm-ostree status > "$BACKUP_DIR/layered-packages.txt"

# 2. Save all GNOME/Desktop settings
echo "Saving dconf (desktop) settings..."
dconf dump / > "$BACKUP_DIR/gnome-settings.dconf"

# 3. Save a list of custom user services
echo "Saving list of custom systemd user services..."
ls -1 ~/.config/systemd/user/* > "$BACKUP_DIR/systemd-user-services.txt" 2>/dev/null || true

# 4. Reminder for manual /etc backups
echo "==> Reminder: If you have custom configurations in /etc (like fstab), back them up manually."

echo "==> Host configuration backup complete ✅"
