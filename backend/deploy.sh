#!/bin/bash
set -e

PROJECT_DIR="/root/Project-UAS-E-Money/backend"
SERVICE_NAME="backend-galon"

echo "=== [1/4] Git Pull ==="
cd "$PROJECT_DIR"
git pull

echo "=== [2/4] Build ==="
go build -o app .
echo "Build sukses"

echo "=== [3/4] Restart Service ==="
systemctl restart "$SERVICE_NAME"
sleep 1
systemctl status "$SERVICE_NAME" --no-pager

echo "=== [4/4] Live Logs (Ctrl+C untuk keluar) ==="
journalctl -u "$SERVICE_NAME" -f
