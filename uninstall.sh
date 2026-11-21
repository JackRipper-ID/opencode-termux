#!/usr/bin/env bash
# OpenCode × Termux — uninstaller
set -euo pipefail

DISTRO="${OPENCODE_DISTRO:-debian}"
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
CONFIG_DIR="$HOME/.config/opencode"

GREEN=$'\033[38;5;114m'
DIM=$'\033[2m'
NC=$'\033[0m'

printf '\n  %sOpenCode × Termux — uninstall%s\n\n' "$DIM" "$NC"

rm -f "$BIN_DIR/opencode" "$BIN_DIR/opencode-pair"
printf '  %s✔%s launcher dihapus\n' "$GREEN" "$NC"

if command -v proot-distro >/dev/null 2>&1; then
  proot-distro remove "$DISTRO" >/dev/null 2>&1 || true
  printf '  %s✔%s distro %s dihapus\n' "$GREEN" "$NC" "$DISTRO"
fi

printf '  %s·%s config dibiarkan: %s\n\n' "$DIM" "$NC" "$CONFIG_DIR/opencode.json"
printf '  Hapus juga config? %srm -rf %s%s\n\n' "$DIM" "$CONFIG_DIR" "$NC"
