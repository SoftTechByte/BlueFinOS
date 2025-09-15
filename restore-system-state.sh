#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/backups"
LOG_FILE="$BACKUP_DIR/system-restore.log"
# NEW: Define the metadata file for container types
CONTAINER_TYPES_FILE="$BACKUP_DIR/container-types.txt"

# ... (script setup and logging as before) ...

# 1. Restore all Podman Images (no change)
# ...

# 2. Recreate containers from the latest snapshots (UPGRADED LOGIC)
echo "==> Recreating containers from latest snapshots using type metadata..." | tee -a "$LOG_FILE"

# NEW: Read container types into an associative array for easy lookup
declare -A C_TYPES
if [[ -f "$CONTAINER_TYPES_FILE" ]]; then
    while IFS=: read -r name type; do
        C_TYPES["$name"]="$type"
    done < "$CONTAINER_TYPES_FILE"
fi

LATEST_SNAPSHOTS=$(podman images --filter "reference=localhost/backup/*" --format "{{.Repository}}:{{.Tag}}" | sort -u)

for image in $LATEST_SNAPSHOTS; do
    CONTAINER_NAME=$(echo "$image" | awk -F'[:/]' '{print $(NF-1)}')
    # NEW: Look up the container's type
    TYPE=${C_TYPES[$CONTAINER_NAME]:-unknown}

    echo "Recreating '${CONTAINER_NAME}' (type: ${TYPE}) from snapshot '${image}'..." | tee -a "$LOG_FILE"

    # NEW: Use the correct command based on the identified type
    if [[ "$TYPE" == "toolbox" ]]; then
        toolbox create --image "$image" "$CONTAINER_NAME" 2>&1 | tee -a "$LOG_FILE"
    elif [[ "$TYPE" == "distrobox" ]]; then
        distrobox create --name "$CONTAINER_NAME" --image "$image" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "  - WARNING: Unknown container type for '${CONTAINER_NAME}'. Skipping automatic creation." | tee -a "$LOG_FILE"
    fi
done

# 3. Restore all Flatpak Apps (no change)
# ...

# 4. Restore all Homebrew Packages (no change)
# ...

echo "==> Automated System Restoration Complete ✅" | tee -a "$LOG_FILE"
