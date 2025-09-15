#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "==> Starting Master Backup Run on $(date)"
echo "============================================================"

# Run the container and app state backup
echo "--- Running System State Backup ---"
/home/mayank/bin/backup-system-state.sh

# Run the host OS config backup
echo "--- Running Host Config Backup ---"
/home/mayank/bin/backup-host-configs.sh

echo "============================================================"
echo "==> Master Backup Run Complete"
echo "============================================================"
