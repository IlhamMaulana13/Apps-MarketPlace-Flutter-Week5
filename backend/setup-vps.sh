#!/bin/bash
# Jalankan sekali saja di VPS untuk setup awal
set -e

PROJECT_DIR="/root/Project-UAS-E-Money/backend"
SERVICE_NAME="backend-galon"
SERVICE_FILE="$PROJECT_DIR/backend-galon.service"

echo "=== Setup Backend Galon ==="

# Build pertama kali
echo "[1/4] Build binary..."
cd "$PROJECT_DIR"
go build -o app .

# Pasang service
echo "[2/4] Install systemd service..."
cp "$SERVICE_FILE" /etc/systemd/system/"$SERVICE_NAME".service
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

# Beri izin eksekusi deploy script
chmod +x "$PROJECT_DIR/deploy.sh"

# Jalankan
echo "[3/4] Start service..."
systemctl start "$SERVICE_NAME"
sleep 2

# Status
echo "[4/4] Status:"
systemctl status "$SERVICE_NAME" --no-pager

echo ""
echo "Setup selesai!"
echo "Untuk deploy selanjutnya cukup jalankan:"
echo "  cd $PROJECT_DIR && ./deploy.sh"
