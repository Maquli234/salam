#!/usr/bin/env bash
# Replace the old vulnerable container with the patched one.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root: sudo ./deploy.sh"; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "[1/4] Removing the old vulnerable container and image"
docker rm -f tidewater >/dev/null 2>&1 || true
docker rmi -f tidewater-web:latest >/dev/null 2>&1 || true

echo "[2/4] Building the patched image (pulling a fresh base image)"
docker compose build --pull

echo "[3/4] Starting"
docker compose up -d
sleep 5
docker ps --filter name=tidewater --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

echo "[4/4] Running the retest"
./verify-fixed.sh
