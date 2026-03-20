#!/usr/bin/env bash
# setup.sh — run once after initial clone
# Sets up Python venv, sources aliases, and schedules auto-updates via cron.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Repo dir: $REPO_DIR"

# 1. Create Python venv if not present
if [ ! -d "$REPO_DIR/venv" ]; then
    echo "==> Creating Python venv..."
    python3 -m venv "$REPO_DIR/venv"
fi

# 2. Install requirements if present
if [ -f "$REPO_DIR/requirements.txt" ]; then
    echo "==> Installing requirements..."
    "$REPO_DIR/venv/bin/pip" install -r "$REPO_DIR/requirements.txt" --quiet
fi

# 3. Add source line to ~/.bashrc (idempotent)
SOURCE_LINE="[ -f \"$REPO_DIR/scripts/aliases.sh\" ] && source \"$REPO_DIR/scripts/aliases.sh\""
if ! grep -qF "aliases.sh" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# OTO-labs aliases" >> "$HOME/.bashrc"
    echo "$SOURCE_LINE" >> "$HOME/.bashrc"
    echo "==> Added alias source line to ~/.bashrc"
else
    echo "==> Alias source line already present in ~/.bashrc (skipping)"
fi

# 4. Install cron job (idempotent)
CRON_JOB="*/10 * * * * $REPO_DIR/scripts/auto-update.sh >> /tmp/oto-labs-update.log 2>&1"
if ! crontab -l 2>/dev/null | grep -qF "auto-update.sh"; then
    ( crontab -l 2>/dev/null || true; echo "$CRON_JOB" ) | crontab -
    echo "==> Installed cron job (runs every 10 minutes)"
else
    echo "==> Cron job already present (skipping)"
fi

echo ""
echo "✅ Setup complete! Run: source ~/.bashrc"
