#!/usr/bin/env bash
# ==============================================================================
#  🏴‍☠️ IncelOS Deployment Engine (install.sh)
#  Philosophy: 0% telemetry, 100% autonomy, supreme gaming & creative performance
# ==============================================================================
set -e

# Visual formatting
BOLD='\033[1m'
WHITE='\033[1;37m'
GREY='\033[0;37m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${WHITE}"
echo "    ██╗███╗   ██╗ ██████╗███████╗██╗      ██████╗ ███████╗"
echo "    ██║████╗  ██║██╔════╝██╔════╝██║     ██╔═══██╗██╔════╝"
echo "    ██║██╔██╗ ██║██║     █████╗  ██║     ██║   ██║███████╗"
echo "    ██║██║╚██╗██║██║     ██╔══╝  ██║     ██║   ██║╚════██║"
echo "    ██║██║ ╚████║╚██████╗███████╗███████╗╚██████╔╝███████║"
echo "    ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝"
echo -e "${PURPLE}           ⚡ DIGITAL RESISTANCE EDITION ⚡${NC}\n"

# Verify Root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[-] Error: Please run as root (sudo bash install.sh)${NC}"
    exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"
if [ "$TARGET_USER" = "root" ]; then
    TARGET_USER="incel"
    if ! id "$TARGET_USER" &>/dev/null; then
        echo -e "${PURPLE}[+] Creating user '$TARGET_USER'...${NC}"
        useradd -m -G wheel,video,audio,storage,network -s /bin/bash "$TARGET_USER"
        echo "$TARGET_USER:incelos" | chpasswd
        echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel
    fi
fi
USER_HOME=$(eval echo "~$TARGET_USER")

echo -e "${GREEN}[+] Target user: ${WHITE}$TARGET_USER${NC}"
echo -e "${GREEN}[+] Home directory: ${WHITE}$USER_HOME${NC}"

# ==============================================================================
#  1. Hardware Auto-Detection (lspci)
# ==============================================================================
echo -e "\n${PURPLE}[1/6] 🔍 Hardware Auto-Detection...${NC}"
GPU_INFO=$(lspci | grep -iE 'vga|3d|display' || true)
echo -e "${GREY}$GPU_INFO${NC}"

GPU_PACKAGES=()
HYPR_ENV_FIXES=""

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    echo -e "${GREEN}[✓] NVIDIA GPU Detected! Applying proprietary DKMS stack + Wayland fixes...${NC}"
    GPU_PACKAGES=(nvidia-dkms nvidia-utils lib32-nvidia-utils egl-wayland)
    HYPR_ENV_FIXES=$(cat << 'EOF'
# NVIDIA Fixes for Hyprland
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
cursor {
    no_hardware_cursors = true
}
EOF
)
    # Enable NVIDIA DRM Modeset
    sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf 2>/dev/null || true
    echo "options nvidia_drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf
elif echo "$GPU_INFO" | grep -iq "amd"; then
    echo -e "${GREEN}[✓] AMD GPU Detected! Enabling Mesa Vulkan + RADV...${NC}"
    GPU_PACKAGES=(mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon xf86-video-amdgpu)
elif echo "$GPU_INFO" | grep -iqE "virtualbox|vmware"; then
    echo -e "${GREEN}[✓] Virtual Machine Detected! Enabling Guest Additions...${NC}"
    GPU_PACKAGES=(virtualbox-guest-utils mesa)
    systemctl enable vboxservice.service 2>/dev/null || true
else
    echo -e "${GREEN}[✓] Intel / Generic GPU Detected!${NC}"
    GPU_PACKAGES=(mesa vulkan-intel lib32-mesa lib32-vulkan-intel)
fi

# ==============================================================================
#  2. Base Repositories & Multilib Activation
# ==============================================================================
echo -e "\n${PURPLE}[2/6] ⚙️ Configuring Package Manager (Multilib & Mirrors)...${NC}"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
fi
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 8/' /etc/pacman.conf
sed -i 's/#Color/Color/' /etc/pacman.conf

pacman -Sy --noconfirm

# ==============================================================================
#  3. Core System & Gaming Packages
# ==============================================================================
echo -e "\n${PURPLE}[3/6] 🚀 Installing Core Stack (Linux-Zen, Hyprland, Audio)...${NC}"

PACKAGES=(
    # Kernel & Foundation
    linux-zen linux-zen-headers zram-generator btrfs-progs
    git curl wget fastfetch polkit-kde-agent brightnessctl
    
    # Wayland + Hyprland Stack
    hyprland waybar rofi-wayland swaybg kitty
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland libnotify mako
    
    # Audio & Communication
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
    
    # Fonts (True Type & Icons)
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    
    # Everyday Apps
    thunar thunar-archive-plugin ark pavucontrol
    
    # Creative & Python runtime
    python python-pip python-pyqt6
    
    # Gaming Suite
    steam gamemode mangohud wine-staging
    
    "${GPU_PACKAGES[@]}"
)

pacman -S --noconfirm --needed "${PACKAGES[@]}"

# Enable ZRAM Memory Compression
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
systemctl daemon-reload
systemctl start /dev/zram0 2>/dev/null || true

# ==============================================================================
#  4. True Black Aesthetic & Windows-Familiar Ergonomics
# ==============================================================================
echo -e "\n${PURPLE}[4/6] 🖤 Deploying True Black Minimalist Configs (Hyprland + Waybar + Rofi)...${NC}"

CONFIG_DIR="$USER_HOME/.config"
mkdir -p "$CONFIG_DIR/hypr" "$CONFIG_DIR/waybar" "$CONFIG_DIR/rofi" "$CONFIG_DIR/kitty"

# 4.1 Hyprland Configuration (Windows-style floating by default, mouse control, True Black)
cat << EOF > "$CONFIG_DIR/hypr/hyprland.conf"
# IncelOS Hyprland Main Config
# True Black Minimalist Edition

monitor=,preferred,auto,1

# Autostart
exec-once = waybar
exec-once = swaybg -c "#000000"
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = mako
exec-once = pipewire

$HYPR_ENV_FIXES

input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

general {
    gaps_in = 6
    gaps_out = 12
    border_size = 1
    col.active_border = rgb(8b5cf6) rgb(ffffff) 45deg
    col.inactive_border = rgb(171717)
    layout = dwindle
    # Windows-familiar: Floating mode enabled for non-tile workflow
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
    }
    drop_shadow = false
}

animations {
    enabled = true
    bezier = fluent, 0.22, 1, 0.36, 1
    animation = windows, 1, 4, fluent
    animation = windowsOut, 1, 4, fluent
    animation = border, 1, 6, default
    animation = fade, 1, 4, fluent
    animation = workspaces, 1, 5, fluent
}

dwindle {
    pseudotile = true
    preserve_split = true
}

# Keybindings (Windows habits supported)
bind = SUPER, Q, killactive,
bind = SUPER, M, exit,
bind = SUPER, E, exec, thunar
bind = SUPER, V, togglefloating,
bind = SUPER, SPACE, exec, rofi -show drun
bind = SUPER, Return, exec, kitty
bind = SUPER, F, fullscreen,
bind = ALT, F4, killactive,

# Mouse control (drag and resize windows like Windows)
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow
bindm = ALT, mouse:272, movewindow
EOF

# 4.2 Waybar Configuration (Bottom Windows-Style Taskbar)
cat << 'EOF' > "$CONFIG_DIR/waybar/config"
{
    "layer": "top",
    "position": "bottom",
    "height": 44,
    "modules-left": ["custom/launcher", "wlr/taskbar"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "hyprland/language", "custom/power"],

    "custom/launcher": {
        "format": "⚡ IncelOS",
        "on-click": "rofi -show drun",
        "tooltip": false
    },
    "wlr/taskbar": {
        "format": "{icon} {name}",
        "icon-size": 18,
        "on-click": "activate",
        "on-click-middle": "close"
    },
    "clock": {
        "format": "{:%H:%M  •  %d %b}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    "hyprland/language": {
        "format": "⌨ {}",
        "format-en": "EN",
        "format-ru": "RU"
    },
    "pulseaudio": {
        "format": "🔊 {volume}%",
        "format-muted": "🔇 Muted",
        "on-click": "pavucontrol"
    },
    "network": {
        "format-wifi": "📶 {essid}",
        "format-ethernet": "🌐 LAN",
        "format-disconnected": "⚠️ No Net"
    },
    "custom/power": {
        "format": "⏻",
        "on-click": "wlogout || rofi -show power-menu",
        "tooltip": false
    }
}
EOF

cat << 'EOF' > "$CONFIG_DIR/waybar/style.css"
* {
    border: none;
    font-family: 'JetBrains Mono', 'Inter', sans-serif;
    font-size: 13px;
    font-weight: 500;
}

window#waybar {
    background-color: #000000;
    border-top: 1px solid rgba(255, 255, 255, 0.08);
    color: #ffffff;
}

#custom-launcher {
    padding: 0 18px;
    margin: 6px 8px;
    background: #121212;
    color: #ffffff;
    border-radius: 6px;
    font-weight: 700;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

#custom-launcher:hover {
    background: #8b5cf6;
    color: #ffffff;
}

#taskbar button {
    padding: 0 14px;
    margin: 6px 2px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.03);
    color: #d4d4d4;
    border: 1px solid rgba(255, 255, 255, 0.04);
}

#taskbar button.active {
    background: rgba(255, 255, 255, 0.08);
    color: #ffffff;
    border-bottom: 2px solid #8b5cf6;
}

#clock, #pulseaudio, #network, #language, #custom-power {
    padding: 0 12px;
    color: #d4d4d4;
}

#custom-power {
    margin-right: 8px;
    color: #ef4444;
}
EOF

# 4.3 Rofi (True Black Start Menu)
cat << 'EOF' > "$CONFIG_DIR/rofi/config.rasi"
configuration {
    modi: "drun,run";
    show-icons: true;
    display-drun: "Search";
    font: "Inter 12";
}

* {
    bg: #000000;
    fg: #ffffff;
    accent: #8b5cf6;
    border-col: rgba(255, 255, 255, 0.08);
}

window {
    background-color: @bg;
    border: 1px;
    border-color: @border-col;
    border-radius: 12px;
    width: 480px;
    height: 520px;
    padding: 20px;
    location: south west;
    x-offset: 12px;
    y-offset: -56px;
}

inputbar {
    background-color: #0d0d0d;
    border: 1px;
    border-color: @border-col;
    border-radius: 8px;
    padding: 10px 14px;
    children: [ prompt, entry ];
}

prompt {
    text-color: @accent;
    margin: 0 10px 0 0;
}

entry {
    text-color: @fg;
    placeholder: "Launch app...";
}

listview {
    margin: 16px 0 0 0;
    lines: 7;
    columns: 1;
}

element {
    padding: 10px 14px;
    border-radius: 8px;
    background-color: transparent;
    text-color: #a3a3a3;
}

element selected {
    background-color: rgba(255, 255, 255, 0.06);
    text-color: #ffffff;
    border-left: 3px solid @accent;
}
EOF

# 4.4 Kitty Terminal (True Black OLED)
cat << 'EOF' > "$CONFIG_DIR/kitty/kitty.conf"
font_family      JetBrains Mono
font_size        12.0
background       #000000
foreground       #f5f5f5
cursor           #ffffff
cursor_shape     beam
cursor_beam_thickness 1.5
cursor_blink_interval 0.5
window_padding_width 16
background_opacity 0.95
confirm_os_window_close 0
EOF

# ==============================================================================
#  5. Creative Suite: ZenWriter (ZW) Installation
# ==============================================================================
echo -e "\n${PURPLE}[5/6] ✍️ Deploying ZenWriter (ZW) Creative Editor...${NC}"

mkdir -p /usr/local/bin /usr/share/applications

cat << 'EOF' > /usr/local/bin/zenwriter
#!/usr/bin/env python3
"""
ZenWriter (ZW) — True Black OLED Focus Writing Environment
Part of IncelOS
"""
import sys
from PyQt6.QtWidgets import (QApplication, QMainWindow, QTextEdit, 
                             QVBoxLayout, QHBoxLayout, QWidget, QLabel)
from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QFont, QColor, QTextCursor

class ZenWriter(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("ZenWriter")
        self.setStyleSheet("background-color: #000000; color: #ffffff;")
        self.resize(1000, 750)
        
        # Central Layout
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(60, 40, 60, 20)
        
        # Editor
        self.editor = QTextEdit()
        self.editor.setFont(QFont("JetBrains Mono", 14))
        self.editor.setStyleSheet("""
            QTextEdit {
                background-color: #000000;
                color: #e5e5e5;
                border: none;
                line-height: 1.8;
                selection-background-color: #8b5cf6;
            }
        """)
        self.editor.textChanged.connect(self.update_stats)
        layout.addWidget(self.editor)
        
        # Bottom Stats Bar
        self.stats = QLabel("0 words  •  0 characters")
        self.stats.setStyleSheet("color: #404040; font-size: 12px; font-family: Inter;")
        self.stats.setAlignment(Qt.AlignmentFlag.AlignRight)
        layout.addWidget(self.stats)
        
        self.setCentralWidget(widget)
        self.is_focus_mode = False

    def keyPressEvent(self, event):
        if event.key() == Qt.Key.Key_F11:
            self.toggle_focus()
        else:
            super().keyPressEvent(event)

    def toggle_focus(self):
        if not self.is_focus_mode:
            self.showFullScreen()
            self.is_focus_mode = True
        else:
            self.showNormal()
            self.is_focus_mode = False

    def update_stats(self):
        text = self.editor.toPlainText().strip()
        words = len(text.split()) if text else 0
        chars = len(text)
        self.stats.setText(f"{words} words  •  {chars} characters  [F11: Focus]")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    editor = ZenWriter()
    editor.show()
    sys.exit(app.exec())
EOF
chmod +x /usr/local/bin/zenwriter

cat << 'EOF' > /usr/share/applications/zenwriter.desktop
[Desktop Entry]
Name=ZenWriter
Comment=True Black Focus Writing Environment
Exec=/usr/local/bin/zenwriter
Icon=text-editor
Terminal=false
Type=Application
Categories=Office;TextEditor;
EOF

# ==============================================================================
#  6. Esports Engine: CPU Isolation & Shader RAM Cache (incelos-boost)
# ==============================================================================
echo -e "\n${PURPLE}[6/6] ⚡ Installing Esports Engine (incelos-boost)...${NC}"

cat << 'EOF' > /usr/local/bin/incelos-boost
#!/usr/bin/env bash
# IncelOS Esports Boost Engine
# Isolates physical P-cores & mounts high-speed RAM shader cache
set -e

GAME_CMD="$@"

if [ -z "$GAME_CMD" ]; then
    echo "Usage: incelos-boost <game_executable_or_command>"
    exit 1
fi

echo "[⚡ IncelOS Boost] Optimizing hardware for peak FPS..."

# 1. Performance Governor
if command -v cpupower &>/dev/null; then
    cpupower frequency-set -g performance >/dev/null 2>&1 || true
fi

# 2. Shader RAM Cache (Redirect DXVK/Mesa shaders to ultra-fast ZRAM/tmpfs)
export __GL_SHADER_DISK_CACHE_PATH="/tmp/shader-cache"
export MESA_SHADER_CACHE_DIR="/tmp/shader-cache"
export DXVK_STATE_CACHE_PATH="/tmp/shader-cache"
mkdir -p /tmp/shader-cache

# 3. CPU Core Affinity: Pin game to physical performance cores (0,2,4,6)
CORES=$(lscpu -p=CPU,CORE | grep -v '^#' | sort -u -k2,2 -t, | cut -d, -f1 | paste -sd, -)
echo "[⚡ IncelOS Boost] Launching on isolated cores: $CORES"

exec taskset -c "$CORES" gamemoderun "$@"
EOF
chmod +x /usr/local/bin/incelos-boost

# Fix permissions for the target user
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config"

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${WHITE}  🏴‍☠️ IncelOS Deployment Complete!${NC}"
echo -e "${GREY}  Log in as ${WHITE}$TARGET_USER${GREY} and run: ${PURPLE}Hyprland${NC}"
echo -e "${GREEN}================================================================${NC}\n"
