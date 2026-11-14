#!/usr/bin/env bash
set -euo pipefail
backup=${1:?backup directory required}
commit=84a8bdd25c19a640acf210168d67085e9dc05941
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
command -v git >/dev/null || { echo 'git is required for themes' >&2; exit 1; }
git init -q "$tmp/source"
git -C "$tmp/source" remote add origin https://github.com/w1nyear/macW1Y-GTK-Theme.git
git -C "$tmp/source" sparse-checkout init --cone
git -C "$tmp/source" sparse-checkout set icons/MacTahoe icons/MacTahoe-dark macW1Y-Dark
git -C "$tmp/source" -c protocol.version=2 fetch --quiet --depth=1 --filter=blob:none origin "$commit"
git -C "$tmp/source" checkout --quiet --detach FETCH_HEAD
mkdir -p "$HOME/.local/share/icons" "$HOME/.local/share/themes" "$backup/themes"
for name in MacTahoe MacTahoe-dark; do
  [ -d "$tmp/source/icons/$name" ] || { echo "Theme missing: $name" >&2; exit 1; }
  if [ -e "$HOME/.local/share/icons/$name" ]; then mv "$HOME/.local/share/icons/$name" "$backup/themes/$name"; fi
  cp -a "$tmp/source/icons/$name" "$HOME/.local/share/icons/$name"
done
if [ -e "$HOME/.local/share/themes/macW1Y-Dark" ]; then mv "$HOME/.local/share/themes/macW1Y-Dark" "$backup/themes/macW1Y-Dark"; fi
cp -a "$tmp/source/macW1Y-Dark" "$HOME/.local/share/themes/macW1Y-Dark"
mkdir -p "$HOME/.config/macshell"
envfile="$HOME/.config/macshell/env"
[ ! -e "$envfile" ] || cp -a "$envfile" "$backup/macshell-env"
touch "$envfile"
if grep -Eq '^[[:space:]]*(export[[:space:]]+)?QS_ICON_THEME=' "$envfile"; then
  sed -i -E 's/^[[:space:]]*(export[[:space:]]+)?QS_ICON_THEME=.*/export QS_ICON_THEME=MacTahoe-dark/' "$envfile"
else printf '\nexport QS_ICON_THEME=MacTahoe-dark\n' >> "$envfile"; fi
