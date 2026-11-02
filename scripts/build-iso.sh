#!/usr/bin/env bash
# IncelOS Local Build Script
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root: sudo ./scripts/build-iso.sh"
  exit 1
fi

echo "[+] Starting IncelOS Build Process..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ARCHISO_PROFILE="$PROJECT_ROOT/archiso"
BUILD_WORK_DIR="/tmp/incelos-work"
OUT_DIR="$PROJECT_ROOT/out"

mkdir -p "$OUT_DIR"
rm -rf "$BUILD_WORK_DIR"

echo "[+] Profile directory: $ARCHISO_PROFILE"
echo "[+] Output directory:  $OUT_DIR"

mkarchiso -v -w "$BUILD_WORK_DIR" -o "$OUT_DIR" "$ARCHISO_PROFILE"

echo "[✓] IncelOS ISO built successfully!"
ls -lh "$OUT_DIR"/*.iso
