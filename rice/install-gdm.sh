#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
backup=${1:?backup directory required}
command -v update-alternatives >/dev/null
resource="$root/third_party/macw1y/gdm/gnome-shell-theme.gresource"
[ -f "$resource" ] || { echo 'GDM resource missing' >&2; exit 1; }
mkdir -p "$backup/gdm"
update-alternatives --query gdm-theme.gresource > "$backup/gdm/alternatives.txt" 2>/dev/null || true
sudo mkdir -p /usr/share/gnome-shell/theme/mackintosh-rice
sudo install -m 644 "$resource" /usr/share/gnome-shell/theme/mackintosh-rice/gnome-shell-theme.gresource
sudo update-alternatives --install /usr/share/gnome-shell/gdm-theme.gresource gdm-theme.gresource /usr/share/gnome-shell/theme/mackintosh-rice/gnome-shell-theme.gresource 90
sudo update-alternatives --set gdm-theme.gresource /usr/share/gnome-shell/theme/mackintosh-rice/gnome-shell-theme.gresource
printf '%s\n' 'GDM theme installed. It takes effect at the next login; GDM was not restarted.'
