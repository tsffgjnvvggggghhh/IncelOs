# IncelOS ⚡

> **A refined, privacy-first, ultra-responsive Arch-based Linux distribution designed to surpass the modern desktop experience.**

---

## 🎯 Vision

**IncelOS** was born out of frustration with modern proprietary operating systems (Windows 11): intrusive telemetry, ads embedded in the Start menu, forced Microsoft accounts, sluggish background services, and inconsistent legacy UI elements.

IncelOS delivers a **pure, premium, matte-dark desktop experience** out of the box, powered by the lightning-fast **Arch Linux** foundation and modern **KDE Plasma 6 (Wayland)**.

---

## ✨ Key Features

- **🖤 Deep Matte Dark Aesthetics**: A cohesive, modern design system featuring deep slate grays, customizable vibrant accent colors, and silky-smooth hardware-accelerated blur effects.
- **🚀 Out-of-the-Box Setup Wizard (`incelos-welcome`)**: A modern initial setup assistant to configure your language, accent color, favorite browser, and gaming essentials on your first boot.
- **🛡️ Instant Rollbacks (Btrfs + Snapper)**: Automatic system snapshots before every update. If anything goes wrong, restore your system back in seconds right from the GRUB bootloader.
- **🎮 Gaming Ready**: Pre-tuned kernel (`linux-zen`), ZRAM memory compression enabled by default, PipeWire pro-audio stack, and 1-click installation for Steam, ProtonUp-Qt, Bottles, and Discord.
- **🎛️ 100% Customizable**: Unlike closed operating systems, you own your desktop. Every panel, animation curve, hotkey, and widget can be tweaked to your exact liking.
- **📦 Clean Package Ecosystem**: Complete access to the Arch User Repository (AUR) and Flatpak with a beautiful graphical store.

---

## 📁 Repository Structure

```text
├── .github/workflows/     # CI/CD: Automated ISO builds on GitHub
├── archiso/               # Custom Archiso profile definition
│   ├── packages.x86_64    # Base and GUI package manifest
│   ├── airootfs/          # System root overlay (/etc, /usr, skel)
│   └── profiledef.sh      # ISO branding and permissions
├── apps/
│   └── incelos-welcome/   # Interactive Python/Qt6 first-run setup assistant
├── branding/              # Wallpapers, SDDM login theme, Plymouth boot splash
├── calamares/             # Customized Calamares graphical OS installer
└── scripts/               # Local build & test scripts
```

---

## 🛠️ Building the ISO

### Requirements
- Arch Linux host (or Docker / ArchWSL)
- `archiso` package installed (`sudo pacman -S archiso`)
- At least 25 GB free disk space

### Local Build Command
```bash
sudo ./scripts/build-iso.sh
```

---

## 📜 License
IncelOS is open-source software licensed under the **GNU General Public License v3.0 (GPL-3.0)**.
