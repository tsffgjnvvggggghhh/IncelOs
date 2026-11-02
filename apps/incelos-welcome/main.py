#!/usr/bin/env python3
"""
IncelOS Welcome & OOBE Wizard
Author: IncelOS Team
License: GPL-3.0
Description: Modern out-of-the-box first-run setup wizard for IncelOS.
"""

import sys
import os
import json
from pathlib import Path

# We import PySide6 when running under IncelOS / Linux
try:
    from PySide6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QPushButton, QStackedWidget, QLineEdit, QRadioButton,
        QCheckBox, QButtonGroup, QFrame, QGraphicsDropShadowEffect
    )
    from PySide6.QtCore import Qt, QSize, Signal
    from PySide6.QtGui import QColor, QFont, QIcon, QPainter, QBrush, QPen
    QT_AVAILABLE = True
except ImportError:
    QT_AVAILABLE = False


STYLESHEET = """
QMainWindow {
    background-color: #0f1013;
}

QWidget#CentralWidget {
    background-color: #0f1013;
    border-radius: 16px;
    border: 1px solid #232630;
}

QFrame#Sidebar {
    background-color: #14161b;
    border-right: 1px solid #1f222b;
    border-top-left-radius: 16px;
    border-bottom-left-radius: 16px;
}

QLabel {
    color: #e5e7eb;
    font-family: 'Segoe UI', 'Inter', -apple-system, sans-serif;
}

QLabel#Title {
    font-size: 24px;
    font-weight: 700;
    color: #ffffff;
}

QLabel#Subtitle {
    font-size: 14px;
    color: #9ca3af;
    margin-bottom: 12px;
}

QLabel#StepLabel {
    font-size: 13px;
    font-weight: 600;
    color: #6b7280;
    padding: 8px 16px;
    border-radius: 8px;
}

QLabel#StepLabelActive {
    font-size: 13px;
    font-weight: 700;
    color: #ffffff;
    background-color: #1e222d;
    padding: 8px 16px;
    border-radius: 8px;
}

QLineEdit {
    background-color: #181b22;
    border: 1px solid #282d3b;
    border-radius: 10px;
    padding: 12px 16px;
    font-size: 14px;
    color: #ffffff;
}

QLineEdit:focus {
    border: 1px solid #7c3aed;
    background-color: #1b1e27;
}

QFrame.Card {
    background-color: #171922;
    border: 1px solid #262a36;
    border-radius: 12px;
    padding: 12px;
}

QFrame.Card:hover {
    border: 1px solid #3d4357;
    background-color: #1b1e28;
}

QPushButton.Primary {
    background-color: #7c3aed;
    color: #ffffff;
    font-size: 14px;
    font-weight: 600;
    padding: 10px 24px;
    border-radius: 10px;
    border: none;
}

QPushButton.Primary:hover {
    background-color: #8b5cf6;
}

QPushButton.Secondary {
    background-color: #1e222d;
    color: #9ca3af;
    font-size: 14px;
    font-weight: 600;
    padding: 10px 20px;
    border-radius: 10px;
    border: 1px solid #2a2f3f;
}

QPushButton.Secondary:hover {
    background-color: #272c3b;
    color: #ffffff;
}

QCheckBox {
    color: #d1d5db;
    font-size: 14px;
    spacing: 10px;
}

QCheckBox::indicator {
    width: 18px;
    height: 18px;
    border-radius: 5px;
    border: 1px solid #374151;
    background-color: #181b22;
}

QCheckBox::indicator:checked {
    background-color: #7c3aed;
    border-color: #8b5cf6;
}
"""

class IncelOSWelcomeWizard:
    """Class representing the logic and configuration generator for IncelOS setup."""
    def __init__(self):
        self.config = {
            "username": "",
            "language": "ru_RU.UTF-8",
            "keyboard_layout": "us,ru",
            "keyboard_toggle": "grp:alt_shift_toggle",
            "accent_color": "#7c3aed", # Electric Violet
            "theme": "matte_dark",
            "browser": "brave",
            "install_gaming_pack": True,
            "install_dev_pack": False,
            "enable_snapper": True,
            "enable_zram": True
        }

    def save_configuration(self, target_path="/etc/incelos/first_boot.json"):
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        with open(target_path, "w", encoding="utf-8") as f:
            json.dump(self.config, f, indent=4)

    def generate_apply_script(self):
        """Generates bash commands executed by IncelOS to apply user choices."""
        commands = [
            "#!/bin/bash",
            "# IncelOS OOBE Configuration Applicator",
            "set -e",
            "",
            "# 1. Language & Keyboard Layout",
            f"localectl set-locale LANG={self.config['language']}",
            f"localectl set-x11-keymap {self.config['keyboard_layout']} pc105 \"\" {self.config['keyboard_toggle']}",
            "",
            "# 2. Accent Color in KDE Plasma 6",
            f"kwriteconfig6 --file kdeglobals --group General --key AccentColor \"{self.config['accent_color']}\"",
            "",
            "# 3. Browser selection",
        ]

        browser = self.config["browser"]
        if browser == "brave":
            commands.append("pacman -S --noconfirm brave-bin || flatpak install -y flathub com.brave.Browser")
        elif browser == "zen":
            commands.append("flatpak install -y flathub app.zen_browser.zen")
        elif browser == "firefox":
            commands.append("pacman -S --noconfirm firefox")

        if self.config["install_gaming_pack"]:
            commands.extend([
                "",
                "# 4. Gaming Pack Installation",
                "pacman -S --noconfirm steam gamemode mangohud wine-staging",
                "flatpak install -y flathub com.discordapp.Discord com.valvesoftware.SteamLink net.davidotek.pupgui2"
            ])

        if self.config["enable_snapper"]:
            commands.extend([
                "",
                "# 5. Snapper Btrfs Rollback Activation",
                "systemctl enable --now snapper-timeline.timer snapper-cleanup.timer"
            ])

        return "\n".join(commands)


def run_app():
    if not QT_AVAILABLE:
        print("[IncelOS] PySide6 is not installed on this host environment.")
        print("[IncelOS] A web preview has been prepared at preview.html for instant inspection!")
        return

    app = QApplication(sys.argv)
    app.setStyleSheet(STYLESHEET)
    # Qt GUI creation would follow here
    print("[IncelOS] Starting Qt6 Welcome Wizard...")

if __name__ == "__main__":
    wizard = IncelOSWelcomeWizard()
    print("IncelOS Welcome Wizard Logic Initialized.")
    print("Example Apply Script:")
    print(wizard.generate_apply_script())
