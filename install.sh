#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  OpenCode × Termux — cool installer
#  https://github.com/JackRipper-ID/opencode-termux
#
#  Memasang OpenCode V2 di Termux (Android aarch64) lewat
#  proot-distro Debian + installer resmi OpenCode, lalu
#  menyiapkan launcher + pairing ke OpenCode Mobile (Play Store).
# ─────────────────────────────────────────────────────────────
set -euo pipefail

APP_VERSION="1.2.0"
DISTRO="${OPENCODE_DISTRO:-debian}"
TARGET_VERSION="${OPENCODE_VERSION:-}"
CONFIG_DIR="$HOME/.config/opencode"
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
LAUNCHER="$BIN_DIR/opencode"
PAIRER="$BIN_DIR/opencode-pair"
LOG_DIR="${TMPDIR:-${PREFIX:-/tmp}/tmp}/opencode-termux"
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/JackRipper-ID/opencode-termux/main}"

# ── warna (diisi setelah argumen diparse) ────────────────────
setup_colors() {
  if [ "${NO_COLOR:-0}" = "1" ] || [ ! -t 1 ]; then
    C1=""; C2=""; DIM=""; BOLD=""; RED=""; GREEN=""; YELLOW=""; NC=""
  else
    C1=$'\033[38;5;51m'
    C2=$'\033[38;5;45m'
    DIM=$'\033[2m'
    BOLD=$'\033[1m'
    RED=$'\033[38;5;203m'
    GREEN=$'\033[38;5;114m'
    YELLOW=$'\033[38;5;221m'
    NC=$'\033[0m'
  fi
}

SPIN='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
STEP=0
TOTAL=7

# ── output helpers ───────────────────────────────────────────
banner() {
  local lines=(
    '   ██████╗  ██████╗ '
    '  ██╔═══██╗██╔════╝ '
    '  ██║   ██║██║      '
    '  ██║   ██║██║      '
    '  ╚██████╔╝╚██████╗ '
    '   ╚═════╝  ╚═════╝ '
  )
  local glow=("$C1" "$C1" "$C2" "$C2" "$C2" "$DIM")
  printf '\n'
  local i
  for i in "${!lines[@]}"; do
    printf '  %s%s%s\n' "${glow[$i]}" "${lines[$i]}" "$NC"
  done
  printf '  %sOPENCODE%s %s·%s %sTERMUX%s\n' "$BOLD" "$NC" "$C2" "$NC" "$BOLD" "$NC"
  printf '  %scool installer v%s%s\n\n' "$DIM" "$APP_VERSION" "$NC"
}

step() {
  STEP=$((STEP + 1))
  printf '\n%s[%d/%d]%s %s%s%s\n' "$DIM" "$STEP" "$TOTAL" "$NC" "$BOLD" "$*" "$NC"
}

ok()   { printf '  %s✔%s %s\n' "$GREEN" "$NC" "$*"; }
warn() { printf '  %s▲%s %s\n' "$YELLOW" "$NC" "$*"; }
die()  { printf '  %s✖%s %s\n' "$RED" "$NC" "$*" >&2; exit 1; }

# run <label> <command...>
run() {
  local label="$1"; shift
  mkdir -p "$LOG_DIR"
  local log; log="$(mktemp "$LOG_DIR/step.XXXXXX")"

  "$@" >"$log" 2>&1 &
  local pid=$!
  local i=0

  if [ -t 1 ]; then
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r  %s%s%s %s\033[K' "$C2" "${SPIN:i%10:1}" "$NC" "$label"
      i=$((i + 1))
      sleep 0.08
    done
  fi

  local rc=0
  wait "$pid" || rc=$?

  if [ "$rc" -eq 0 ]; then
    printf '\r  %s✔%s %s\033[K\n' "$GREEN" "$NC" "$label"
    rm -f "$log"
  else
    printf '\r  %s✖%s %s\033[K\n' "$RED" "$NC" "$label"
    printf '    %s--- 20 baris terakhir ---%s\n' "$DIM" "$NC"
    tail -n 20 "$log" | sed 's/^/    /'
    die "Langkah gagal. Log lengkap: $log"
  fi
}

# ── langkah-langkah ──────────────────────────────────────────
check_env() {
  step "Memeriksa lingkungan"
  [ -n "${PREFIX:-}" ] && [ -d "${PREFIX:-}" ] || die "Script ini harus dijalankan di Termux."
  case "$(uname -m)" in
    aarch64|arm64) ;;
    *) die "Arsitektur $(uname -m) belum didukung. Butuh aarch64 (ARM64)." ;;
  esac
  command -v pkg >/dev/null 2>&1 || die "Perintah 'pkg' tidak ditemukan. Ini bukan Termux?"

  local free_mb="?"
  if command -v df >/dev/null 2>&1; then
    free_mb="$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 { print int($4 / 1024) }')"
    [ -n "$free_mb" ] || free_mb="?"
    if [ "$free_mb" != "?" ] && [ "$free_mb" -lt 1500 ]; then
      die "Ruang kosong ${free_mb} MB. Butuh minimal ±1.5 GB."
    fi
  fi

  ok "Termux · aarch64 · ${free_mb} MB free"
  if [ -z "${TERMUX_VERSION:-}" ]; then
    warn "TERMUX_VERSION tidak terdeteksi — pakai Termux dari F-Droid/GitHub, bukan Play Store."
  fi
}

install_deps() {
  step "Memasang dependensi"
  run "pkg update" pkg update -y
  run "pkg install proot-distro curl tar" pkg install -y proot-distro curl tar
  ok "proot-distro, curl, tar siap"
}

setup_distro() {
  step "Menyiapkan ${DISTRO} (proot)"
  local rootfs="${PREFIX}/var/lib/proot-distro/installed-rootfs/${DISTRO}"
  if [ -d "$rootfs" ]; then
    ok "rootfs ${DISTRO} sudah ada"
  else
    run "mengunduh rootfs ${DISTRO}" proot-distro install "$DISTRO"
  fi
  run "apt update" proot-distro login "$DISTRO" -- bash -lc 'apt-get update -y'
  run "memasang curl & ca-certificates" \
    proot-distro login "$DISTRO" -- bash -lc \
    'DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates tar'
}

install_opencode() {
  step "Memasang OpenCode"
  local cmd='curl -fsSL https://opencode.ai/v2/install | bash'
  if [ -n "$TARGET_VERSION" ]; then
    cmd="curl -fsSL https://opencode.ai/v2/install | bash -s -- --version ${TARGET_VERSION}"
  fi
  run "mengunduh & memasang OpenCode" \
    proot-distro login "$DISTRO" -- bash -lc "$cmd"

  local v
  v="$(proot-distro login "$DISTRO" -- bash -lc 'export PATH="$HOME/.opencode/bin:$PATH"; opencode --version' 2>/dev/null | tail -n 1 || true)"
  if [ -n "$v" ]; then
    ok "OpenCode ${v} terpasang"
  else
    warn "Terpasang, tapi versi tidak bisa dibaca."
  fi
}

write_launcher() {
  step "Membuat launcher"
  mkdir -p "$(dirname "$LAUNCHER")"
  cat > "$LAUNCHER" <<'LAUNCHER_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# OpenCode × Termux launcher — dibuat oleh opencode-termux
set -euo pipefail

DISTRO="${OPENCODE_DISTRO:-debian}"
WORKDIR="$(pwd)"
CFG="$HOME/.config/opencode"

mkdir -p "$CFG"

exec proot-distro login "$DISTRO" \
  --bind "$WORKDIR:/workspace" \
  --bind "$CFG:/root/.config/opencode" \
  -- bash -lc 'cd /workspace 2>/dev/null || cd /root; export PATH="$HOME/.opencode/bin:$PATH"; exec opencode "$@"' opencode "$@"
LAUNCHER_EOF
  chmod 755 "$LAUNCHER"
  ok "launcher: $LAUNCHER"
}

write_pairer() {
  step "Menyiapkan pairing OpenCode Mobile"
  cat > "$PAIRER" <<'PAIRER_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Pair OpenCode × Termux dengan OpenCode Mobile (Play Store).
#   opencode-pair            -> link/QR lewat OpenTunnel (bisa dari jaringan mana pun)
#   opencode-pair --local    -> pairing lewat Wi-Fi yang sama
set -euo pipefail

DISTRO="${OPENCODE_DISTRO:-debian}"
WORKDIR="$(pwd)"
CFG="$HOME/.config/opencode"
MODE="${1:---remote}"

mkdir -p "$CFG"

if [ "$MODE" = "--local" ]; then
  PAIR_CMD='opencode service set hostname 0.0.0.0 && opencode pair'
  MODE_LABEL='Wi-Fi lokal'
else
  PAIR_CMD='opencode pair --remote --yes'
  MODE_LABEL='OpenTunnel (jaringan mana pun)'
fi

printf '\n  Mode pairing: %s\n' "$MODE_LABEL"
printf '  Biarkan terminal ini tetap terbuka selama aplikasi terhubung.\n'
printf '  Tekan Ctrl+C untuk berhenti.\n\n'

exec proot-distro login "$DISTRO" \
  --bind "$WORKDIR:/workspace" \
  --bind "$CFG:/root/.config/opencode" \
  -- bash -lc "cd /workspace 2>/dev/null || cd /root; export PATH=\"\$HOME/.opencode/bin:\$PATH\"; $PAIR_CMD; printf '\n  Server tetap hidup. Tekan Ctrl+C untuk berhenti.\n\n'; while true; do sleep 3600; done"
PAIRER_EOF
  chmod 755 "$PAIRER"
  ok "pairing: $PAIRER"
}

write_config() {
  step "Menulis konfigurasi"
  mkdir -p "$CONFIG_DIR"
  if [ -f "$CONFIG_DIR/opencode.json" ]; then
    ok "config sudah ada — dilewati"
  else
    cat > "$CONFIG_DIR/opencode.json" <<'CONFIG_EOF'
{
  "$schema": "https://opencode.ai/config.json"
}
CONFIG_EOF
    ok "config: $CONFIG_DIR/opencode.json"
  fi
}

done_screen() {
  printf '\n'
  printf '  %s╭──────────────────────────────────────────╮%s\n' "$C2" "$NC"
  printf '  %s│%s  %sSIAP DIPAKAI%s                            %s│%s\n' "$C2" "$NC" "$BOLD" "$NC" "$C2" "$NC"
  printf '  %s╰──────────────────────────────────────────╯%s\n' "$C2" "$NC"
  printf '\n'
  printf '  %sTUI di Termux%s\n' "$BOLD" "$NC"
  printf '    %scd ~/project && opencode%s\n' "$DIM" "$NC"
  printf '\n'
  printf '  %sOpenCode Mobile (Play Store)%s\n' "$BOLD" "$NC"
  printf '    %s1.%s pasang %sOpenCode%s dari Play Store (ai.opencode.mobilecode)\n' "$C2" "$NC" "$DIM" "$NC"
  printf '    %s2.%s jalankan %sopencode-pair%s di Termux — muncul QR + link\n' "$C2" "$NC" "$DIM" "$NC"
  printf '    %s3.%s scan QR / tempel link di aplikasi\n' "$C2" "$NC"
  printf '    %s   satu Wi-Fi? pakai %sopencode-pair --local%s\n' "$DIM" "$NC" "$DIM"
  printf '\n'
  printf '  %sTips:%s %stermux-wake-lock%s biar Android tidak mematikan server.\n' "$BOLD" "$NC" "$DIM" "$NC"
  printf '  %sConfig:%s %s\n' "$DIM" "$NC" "$CONFIG_DIR/opencode.json"
  printf '  %sUninstall:%s curl -fsSL %s/uninstall.sh | bash\n' "$DIM" "$NC" "$REPO_RAW"
  printf '\n'
}

uninstall() {
  banner
  warn "Menghapus OpenCode × Termux"
  rm -f "$LAUNCHER" "$PAIRER"
  if command -v proot-distro >/dev/null 2>&1; then
    proot-distro remove "$DISTRO" >/dev/null 2>&1 || true
  fi
  ok "launcher, pairing, dan distro dihapus"
  printf '  %sConfig dibiarkan di %s%s\n\n' "$DIM" "$CONFIG_DIR" "$NC"
}

usage() {
  cat <<EOF
OpenCode × Termux installer v${APP_VERSION}

Usage: install.sh [options]

Options:
  -h, --help             tampilkan bantuan
  -v, --version <ver>    pasang versi OpenCode tertentu
      --distro <name>    distro proot (default: debian)
      --pair             langsung jalankan pairing setelah install
      --uninstall        hapus launcher + distro
      --no-color         tanpa warna
      --dry-run          hanya cek lingkungan

Contoh:
  curl -fsSL ${REPO_RAW}/install.sh | bash
  curl -fsSL ${REPO_RAW}/install.sh | bash -s -- --pair
  bash install.sh --version 2.0.6
EOF
}

main() {
  local dry_run=0
  local do_pair=0
  local do_uninstall=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--version) TARGET_VERSION="${2:-}"; shift 2 ;;
      --distro) DISTRO="${2:-debian}"; shift 2 ;;
      --pair) do_pair=1; shift ;;
      --uninstall) do_uninstall=1; shift ;;
      --no-color) NO_COLOR=1; shift ;;
      --dry-run) dry_run=1; shift ;;
      *) warn "Opsi tidak dikenal: $1"; shift ;;
    esac
  done

  setup_colors

  if [ "$do_uninstall" -eq 1 ]; then
    uninstall
    exit 0
  fi

  banner
  check_env
  if [ "$dry_run" -eq 1 ]; then
    ok "dry-run selesai — lingkungan siap."
    exit 0
  fi

  install_deps
  setup_distro
  install_opencode
  write_launcher
  write_pairer
  write_config
  done_screen

  if [ "$do_pair" -eq 1 ]; then
    exec "$PAIRER"
  fi
}

trap 'printf "\033[?25h"' EXIT
printf '\033[?25l'

main "$@"
