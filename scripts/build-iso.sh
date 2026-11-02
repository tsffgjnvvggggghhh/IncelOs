#!/usr/bin/env bash
# IncelOS Automated ISO Builder
set -e

echo "[+] Initializing Pacman Keyring & Dependencies..."
pacman-key --init || true
pacman-key --populate archlinux || true
pacman -Sy --noconfirm --needed archiso git sed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_PROFILE="/tmp/incelos-profile"
WORK_DIR="/tmp/incelos-work"
OUT_DIR="$PROJECT_ROOT/out"

mkdir -p "$OUT_DIR"
rm -rf "$BUILD_PROFILE" "$WORK_DIR"

echo "[+] Copying official releng profile from archiso..."
cp -r /usr/share/archiso/configs/releng "$BUILD_PROFILE"

echo "[+] Applying IncelOS branding and packages..."
# Append IncelOS packages
if [ -f "$PROJECT_ROOT/archiso/packages.x86_64" ]; then
    echo "[+] Merging packages.x86_64..."
    cat "$PROJECT_ROOT/archiso/packages.x86_64" >> "$BUILD_PROFILE/packages.x86_64"
    sort -u "$BUILD_PROFILE/packages.x86_64" -o "$BUILD_PROFILE/packages.x86_64"
fi

# Overlay airootfs files
if [ -d "$PROJECT_ROOT/archiso/airootfs" ]; then
    echo "[+] Overlaying IncelOS airootfs..."
    cp -rf "$PROJECT_ROOT/archiso/airootfs/"* "$BUILD_PROFILE/airootfs/"
fi

# Customize profiledef.sh metadata
sed -i 's/iso_name="archlinux"/iso_name="incelos"/g' "$BUILD_PROFILE/profiledef.sh"
sed -i 's/iso_label="ARCH_/iso_label="INCELOS_/g' "$BUILD_PROFILE/profiledef.sh"

# Add custom permissions safely
cat << 'EOF' >> "$BUILD_PROFILE/profiledef.sh"
file_permissions+=(
  ["/usr/local/bin/incelos-welcome-launch"]="0:0:755"
  ["/usr/local/bin/incelos-apply"]="0:0:755"
  ["/etc/systemd/system/incelos-welcome.service"]="0:0:644"
)
EOF

echo "[+] Executing mkarchiso..."
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$BUILD_PROFILE"

echo "[✓] IncelOS ISO built successfully!"
ls -lh "$OUT_DIR"/*.iso
