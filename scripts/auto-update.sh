#!/usr/bin/env bash
# auto-update.sh — called by cron every 10 minutes
# Pulls the repo and reinstalls requirements if they changed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REQ="$REPO_DIR/requirements.txt"

# Hash requirements.txt before pull
if [ -f "$REQ" ]; then
    HASH_BEFORE="$(sha256sum "$REQ" | cut -d' ' -f1)"
else
    HASH_BEFORE=""
fi

# Pull
git -C "$REPO_DIR" pull --ff-only --quiet

# Hash requirements.txt after pull
if [ -f "$REQ" ]; then
    HASH_AFTER="$(sha256sum "$REQ" | cut -d' ' -f1)"
else
    HASH_AFTER=""
fi

# Reinstall if changed
if [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
    echo "[$(date)] requirements.txt changed — reinstalling..."
    "$REPO_DIR/venv/bin/pip" install -r "$REQ" --quiet
    echo "[$(date)] pip install complete"
fi
