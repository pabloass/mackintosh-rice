#!/usr/bin/env bash
set -euo pipefail
url='https://github.com/samuelngs/apple-emoji-ttf/releases/download/macos-26-20260722-484daf4e/AppleColorEmoji-Linux.ttf'
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
curl -fL --retry 2 "$url" -o "$tmp"
fc-scan --format '%{family}' "$tmp" | grep -Fq 'Apple Color Emoji' || { echo 'Invalid emoji font.' >&2; exit 1; }
install -Dm644 "$tmp" "$HOME/.local/share/fonts/apple-emoji/AppleColorEmoji-Linux.ttf"
mkdir -p "$HOME/.config/fontconfig/conf.d"
install -m 644 "$(dirname "$0")/fontconfig-apple-emoji.conf" "$HOME/.config/fontconfig/conf.d/75-apple-emoji.conf"
fc-cache -f "$HOME/.local/share/fonts/apple-emoji"
