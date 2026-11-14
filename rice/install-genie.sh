#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
backup=${1:?backup directory required}
command -v make >/dev/null; command -v pkg-config >/dev/null
pkg-config --exists hyprland || { echo 'Hyprland development headers (hyprland.pc) are required; use the exact version of the compositor.' >&2; exit 1; }
version=$(pkg-config --modversion hyprland)
[ "$version" = 0.57.2 ] || { echo "This beta Genie plugin targets Hyprland 0.57.2; headers report $version." >&2; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp -a "$root/third_party/hyprglass/." "$tmp/"
make -C "$tmp" -j2
[ -s "$tmp/hyprglass.so" ] || { echo 'Plugin build failed.' >&2; exit 1; }
mkdir -p "$HOME/.local/share/macshell-plugins"
[ ! -f "$HOME/.local/share/macshell-plugins/hyprglass.so" ] || cp -a "$HOME/.local/share/macshell-plugins/hyprglass.so" "$backup/hyprglass.so"
install -m 755 "$tmp/hyprglass.so" "$HOME/.local/share/macshell-plugins/hyprglass.so"
