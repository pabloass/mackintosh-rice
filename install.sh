#!/usr/bin/env bash
# Mackintosh Rice beta: local MacShell fork + settings. Run as the desktop user.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
with_grub=0; with_gdm=0; with_geo=0; with_emoji=0; with_genie=0; with_themes=1; check=0
usage() {
  cat <<'HELP'
Usage: ./install.sh [--grub] [--gdm] [--geolocation] [--apple-emoji] [--genie] [--no-themes] [--check]

Installs the MacShell fork and desktop settings for the current user.
Requires Hyprland 0.55+ (Lua config), Quickshell 0.3+ and Ubuntu/Debian.
--grub          Install the macW1Y GRUB theme (changes GRUB configuration).
--gdm           Install the macW1Y GDM theme (GNOME Shell 50 only).
--geolocation   Allow the weather widget to use GeoClue for this user.
--apple-emoji   Download Apple-style color emoji font (about 111 MB).
--genie         Build the beta Genie plugin (requires matching Hyprland 0.57.2 headers).
--no-themes     Skip downloading macW1Y icon and GTK themes.
--check         Check files and prerequisites without installing anything.
--help          Show this help.
GRUB/GDM are opt-in and are never restarted or changed without their flag.
Existing user settings are backed up. Log out to enter Hyprland afterwards.
HELP
}
for arg in "$@"; do
  case "$arg" in
    --grub) with_grub=1;; --gdm) with_gdm=1;; --geolocation) with_geo=1;; --apple-emoji) with_emoji=1;; --genie) with_genie=1;; --no-themes) with_themes=0;;
    --check) check=1;; -h|--help) usage; exit 0;; *) echo "Unknown option: $arg" >&2; exit 2;;
  esac
done
[ "$(id -u)" -ne 0 ] || { echo 'Run as the normal desktop user, not root.' >&2; exit 1; }
for f in install-upstream.sh MacShell/shell.qml MacLock/shell.qml rice/bin/macshell-dock-icons.py rice/hypr/mackintosh.lua; do
  [ -f "$root/$f" ] || { echo "Missing: $f" >&2; exit 1; }
done
for cmd in bash python3 curl git; do command -v "$cmd" >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }; done
if ((check)); then
  echo 'Source files OK.'
  for cmd in Hyprland qs hyprctl jq rsvg-convert; do command -v "$cmd" >/dev/null && echo "  $cmd: found" || echo "  $cmd: missing"; done
  echo 'No files changed.'; exit 0
fi
command -v Hyprland >/dev/null || { echo 'Install Hyprland 0.55+ first; see README.' >&2; exit 1; }
command -v qs >/dev/null || { echo 'Install Quickshell 0.3+ first; see README.' >&2; exit 1; }
command -v apt-get >/dev/null || { echo 'This beta installer currently supports Ubuntu/Debian.' >&2; exit 1; }
if ((with_genie)); then
  command -v pkg-config >/dev/null && [ "$(pkg-config --modversion hyprland 2>/dev/null || true)" = 0.57.2 ] || { echo "Genie requires Hyprland 0.57.2 development headers." >&2; exit 1; }
fi
if ((with_gdm)); then
  command -v gnome-shell >/dev/null && gnome-shell --version | grep -Eq '^GNOME Shell 50\.' || { echo 'Bundled GDM theme is compatible only with GNOME Shell 50.' >&2; exit 1; }
fi
if ((with_grub)); then command -v update-grub >/dev/null || { echo 'update-grub not found.' >&2; exit 1; }; fi
backup="$HOME/.local/share/mackintosh-rice/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
for d in macbar macdock macwidgets fastfetch kitty; do
  if [ -d "$HOME/.config/$d" ]; then cp -a "$HOME/.config/$d" "$backup/"; fi
done
if [ -f "$HOME/.config/hypr/hyprland.lua" ]; then cp -a "$HOME/.config/hypr/hyprland.lua" "$backup/hyprland.lua"; fi
sudo apt-get update
sudo apt-get install -y jq python3-gi python3-pil gir1.2-gtk-4.0 librsvg2-bin
if ((with_geo)); then sudo apt-get install -y geoclue-2.0; fi
# The upstream installer performs its own dependency checks and backups.
bash "$root/install-upstream.sh" --local --from-dir "$root" --no-start --no-auto-update
mkdir -p "$HOME/.config" "$HOME/.local/libexec" "$HOME/.local/bin"
install -m 755 "$root/rice/bin/macshell-dock-icons.py" "$HOME/.local/libexec/macshell-dock-icons.py"
install -m 755 "$root/rice/bin/macshell-geolocation.py" "$HOME/.local/libexec/macshell-geolocation.py"
install -m 755 "$root/rice/bin/macshell-genie-click" "$HOME/.local/bin/macshell-genie-click"
for name in macbar macdock macwidgets; do mkdir -p "$HOME/.config/$name"; install -m 644 "$root/rice/config/$name.json" "$HOME/.config/$name/settings.json"; done
mkdir -p "$HOME/.config/fastfetch" "$HOME/.config/kitty"
install -m 644 "$root/rice/config/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"
install -m 644 "$root/rice/config/kitty.conf" "$HOME/.config/kitty/kitty.conf"
install -m 644 "$root/rice/config/pinned.json" "$HOME/.config/macdock/pinned.json"
if [ -f "$HOME/.config/hypr/hyprland.lua" ]; then
  install -m 644 "$root/rice/hypr/mackintosh.lua" "$HOME/.config/hypr/mackintosh.lua"
  if ! grep -Fq 'require("mackintosh")' "$HOME/.config/hypr/hyprland.lua"; then printf '\n-- Mackintosh Rice shortcuts\nrequire("mackintosh")\n' >> "$HOME/.config/hypr/hyprland.lua"; fi
fi
if ((with_geo)); then
  mkdir -p "$HOME/.local/share/applications"
  cat > "$HOME/.local/share/applications/macshell-weather.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=MacShell Weather
Exec=$HOME/.local/libexec/macshell-geolocation.py
NoDisplay=true
DESKTOP
  sudo mkdir -p /etc/geoclue/conf.d
  printf '[macshell-weather]\nallowed=true\nsystem=false\nusers=%s\n' "$(id -u)" | sudo tee /etc/geoclue/conf.d/90-macshell-weather.conf >/dev/null
  command -v gsettings >/dev/null && gsettings set org.gnome.system.location enabled true || true
fi
if ((with_genie)); then bash "$root/rice/install-genie.sh" "$backup"; fi
if ((with_themes)); then bash "$root/rice/install-themes.sh" "$backup"; fi
if ((with_emoji)); then bash "$root/rice/install-emoji.sh"; fi
if ((with_grub)); then bash "$root/rice/install-grub.sh" "$backup"; fi
if ((with_gdm)); then bash "$root/rice/install-gdm.sh" "$backup"; fi
printf '\nInstalled. User backup: %s\n' "$backup"
printf 'Log out and choose Hyprland on the login screen. GNOME remains available.\n'
