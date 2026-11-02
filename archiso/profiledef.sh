#!/usr/bin/env bash
# IncelOS archiso profile definition

iso_name="incelos"
iso_label="INCELOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="IncelOS Project <https://github.com/incelos/incelos>"
iso_application="IncelOS Live & Installation System"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x86_64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x86_64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/incelos-welcome"]="0:0:755"
  ["/usr/local/bin/incelos-welcome-launch"]="0:0:755"
  ["/usr/local/bin/incelos-apply"]="0:0:755"
  ["/etc/systemd/system/incelos-welcome.service"]="0:0:644"
)
