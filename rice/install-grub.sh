#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
backup=${1:?backup directory required}
command -v update-grub >/dev/null
[ -f /etc/default/grub ] || { echo 'GRUB configuration not found.' >&2; exit 1; }
mkdir -p "$backup/grub"
sudo cp -a /etc/default/grub "$backup/grub/default-grub"
if [ -f /etc/default/grub.d/99-mackintosh-rice.cfg ]; then sudo cp -a /etc/default/grub.d/99-mackintosh-rice.cfg "$backup/grub/previous-rice.cfg"; fi
sudo mkdir -p /boot/grub/themes/mackintosh-rice /etc/default/grub.d
sudo cp -a "$root/third_party/macw1y/grub/apple-mac/." /boot/grub/themes/mackintosh-rice/
printf '%s\n' 'GRUB_THEME="/boot/grub/themes/mackintosh-rice/theme.txt"' | sudo tee /etc/default/grub.d/99-mackintosh-rice.cfg >/dev/null
if ! sudo update-grub; then
  echo 'GRUB update failed; restoring previous setting.' >&2
  if [ -f "$backup/grub/previous-rice.cfg" ]; then sudo cp -a "$backup/grub/previous-rice.cfg" /etc/default/grub.d/99-mackintosh-rice.cfg; else sudo rm -f /etc/default/grub.d/99-mackintosh-rice.cfg; fi
  sudo update-grub || true
  exit 1
fi
