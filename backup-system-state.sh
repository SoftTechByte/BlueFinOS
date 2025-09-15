#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/backups"
TODAY=$(date +%F)
CONTAINER_TYPES_FILE="$BACKUP_DIR/container-types.txt"

echo "==> Starting State-Aware Container Backup for $TODAY..."
> "$CONTAINER_TYPES_FILE"

RUNNING_CONTAINERS=$(podman ps --format "{{.Names}}")
ALL_CONTAINERS=$(podman ps -a --format "{{.Names}}")

echo "==> Creating stateful snapshots and identifying container types..."
for container in $ALL_CONTAINERS; do
    SNAPSHOT_IMAGE="localhost/backup/${container}:${TODAY}"
    echo "Processing snapshot for '${container}'..."

    # --- NEW (More Robust): Identify container type by searching all labels ---
    CONTAINER_TYPE="unknown"
    # Get all labels in JSON format
    LABELS=$(podman inspect "$container" --format '{{json .Config.Labels}}')

    if echo "$LABELS" | grep -q "distrobox"; then
        CONTAINER_TYPE="distrobox"
    elif echo "$LABELS" | grep -q "toolbox"; then
        CONTAINER_TYPE="toolbox"
    fi

    echo "${container}:${CONTAINER_TYPE}" >> "$CONTAINER_TYPES_FILE"
    echo "  - Identified as type: ${CONTAINER_TYPE}"

    # The rest of the snapshot logic remains the same
    if echo "$RUNNING_CONTAINERS" | grep -q -w "$container"; then
        echo "  - Pausing, committing, and unpausing..."
        podman pause "$container"
        podman commit "$container" "$SNAPSHOT_IMAGE"
        podman unpause "$container"
    else
        echo "  - Committing stopped container."
        podman commit "$container" "$SNAPSHOT_IMAGE"
    fi
done

# --- The rest of the script remains the same ---
echo "==> Exporting application and image lists..."
podman images --format "{{.Repository}}:{{.Tag}}" > "$BACKUP_DIR/podman-images.txt"
flatpak list --app --columns=application > "$BACKUP_DIR/flatpak-list.txt"
if command -v brew &> /dev/null; then
    brew list > "$BACKUP_DIR/brew-packages.txt"
fi

echo "==> Cleaning up old backup images..."
OLD_SNAPSHOTS=$(podman images --filter "reference=localhost/backup/*" --format "{{.ID}} {{.CreatedAt}}" | awk -v d="7 days ago" '$2" "$3 < d' | awk '{print $1}')
if [[ -n "$OLD_SNAPSHOTS" ]]; then
    podman rmi -f $OLD_SNAPSHOTS
fi

echo "==> Automated Backup Complete ✅"
