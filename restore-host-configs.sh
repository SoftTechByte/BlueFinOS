#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/backups/host"
LOG_FILE="$BACKUP_DIR/host-restore.log"

echo "==> Restoring Bluefin OS host configurations..." | tee -a "$LOG_FILE"

# 1. Reinstall layered packages
echo "Reinstalling layered packages..." | tee -a "$LOG_FILE"
# We extract just the package names from the rpm-ostree status output
PACKAGES=$(grep '^\s\+.*' "$BACKUP_DIR/layered-packages.txt" | awk '{print $1}')
if [[ -n "$PACKAGES" ]]; then
    echo "Installing: $PACKAGES" | tee -a "$LOG_FILE"
    rpm-ostree install $PACKAGES
    echo "Packages installed. A reboot will be required to apply them." | tee -a "$LOG_FILE"
else
    echo "No layered packages to install." | tee -a "$LOG_FILE"
fi

# 2. Restore all GNOME/Desktop settings
echo "Restoring dconf (desktop) settings..." | tee -a "$LOG_FILE"
if [[ -f "$BACKUP_DIR/gnome-settings.dconf" ]]; then
    dconf load / < "$BACKUP_DIR/gnome-settings.dconf"
fi

# 3. Reminder for other restores
echo "==> Reminder: Manually restore any custom /etc files you backed up." | tee -a "$LOG_FILE"
echo "==> Reminder: Review systemd-user-services.txt to re-enable your custom services." | tee -a "$LOG_FILE"

echo "==> Host configuration restore complete ✅"
echo "==> IMPORTANT: Reboot now to apply layered packages before continuing with other restores."
