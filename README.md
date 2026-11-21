<div align="center">

<img src="preview.svg" alt="OpenCode × Termux installer" width="860">

# OpenCode × Termux

**Install OpenCode V2 on Termux in one line — no fuss.**
Plus direct pairing with **OpenCode Mobile** from the Play Store.

[![Shell](https://img.shields.io/badge/shell-bash-00F5FF?style=flat-square&labelColor=0b0f14)](install.sh)
[![Platform](https://img.shields.io/badge/platform-Termux%20aarch64-00D0E8?style=flat-square&labelColor=0b0f14)](#requirements)
[![OpenCode](https://img.shields.io/badge/OpenCode-v2-00A3BF?style=flat-square&labelColor=0b0f14)](https://opencode.ai)
[![License](https://img.shields.io/badge/license-MIT-0086A8?style=flat-square&labelColor=0b0f14)](LICENSE)

</div>

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/JackRipper-ID/opencode-termux/main/install.sh | bash
```

Go straight to pairing as well:

```bash
curl -fsSL https://raw.githubusercontent.com/JackRipper-ID/opencode-termux/main/install.sh | bash -s -- --pair
```

The installer shows live progress, keeps long output out of your face, and stops with a clear message if a step fails.

---

## What it does

| # | Step | Details |
|---|---|---|
| 1 | Check environment | Confirms Termux, aarch64 and ~1.5 GB of free space |
| 2 | Install dependencies | `proot-distro`, `curl`, `tar` |
| 3 | Prepare Debian | proot rootfs + `apt update` |
| 4 | Install OpenCode | The **official** `opencode.ai/v2/install` inside Debian |
| 5 | Launcher | `opencode` → binds your project folder to `/workspace` automatically |
| 6 | Pairing | `opencode-pair` → QR + link for OpenCode Mobile |
| 7 | Config | `~/.config/opencode/opencode.json` (shared by host and proot) |

Nothing is repackaged. You get the official OpenCode `linux-arm64` build, run through proot because OpenCode does not ship a native Android build yet.

---

## Usage

### TUI in Termux

```bash
cd ~/project
opencode
```

The folder you run `opencode` from is bound to `/workspace` inside proot, so the agent sees your project — not the Termux root filesystem.

### OpenCode Mobile (Play Store)

1. Install **OpenCode** from the Play Store — package `ai.opencode.mobilecode`.
2. In Termux, run:

   ```bash
   opencode-pair
   ```

   A QR code and a one-time link appear (valid for 5 minutes).
3. Scan the QR or paste the link into the app. Your Termux sessions show up on your phone.

Prefer the same Wi-Fi only (no tunnel)?

```bash
opencode-pair --local
```

> Keep the `opencode-pair` terminal open while your phone is connected — the server runs inside proot and dies with the session.

### Stop Android from killing the server

```bash
termux-wake-lock
```

---

## Requirements

- Termux from [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub releases](https://github.com/termux/termux-app/releases) — **not** the outdated Play Store build
- **aarch64 / ARM64** Android device
- ~1.5 GB of free space
- An internet connection

Check your architecture:

```bash
uname -m   # should print aarch64
```

---

## Installer options

```text
-h, --help             show this help
-v, --version <ver>    install a specific OpenCode version
    --distro <name>    proot distro (default: debian)
    --pair             run pairing right after install
    --uninstall        remove launcher + distro
    --no-color         disable colors
    --dry-run          check the environment only
```

Examples:

```bash
# a specific version
bash install.sh --version 2.0.6

# check first without changing anything
bash install.sh --dry-run

# a different distro
bash install.sh --distro ubuntu
```

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/JackRipper-ID/opencode-termux/main/uninstall.sh | bash
```

Removes the `opencode` and `opencode-pair` launchers and the proot rootfs. Your config in `~/.config/opencode` is intentionally left alone.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `This script must run inside Termux` | Run it in Termux, not inside proot or over SSH |
| `Architecture ... is not supported` | The device must be ARM64 (`uname -m` → `aarch64`) |
| Installer stops at a step | The full log path is printed at the end of the output |
| QR expired | Links are valid for 5 minutes — run `opencode-pair` again |
| Phone cannot connect | Make sure the pairing terminal is still open; try `opencode-pair --local` on the same Wi-Fi |
| Server dies when the screen turns off | `termux-wake-lock`, and disable battery optimization for Termux |
| `proot-distro` error during install | `pkg update && pkg install --reinstall proot-distro` |

---

## Layout

```text
opencode-termux/
├── install.sh      # installer + pairing
├── uninstall.sh    # cleanup
├── preview.svg     # README banner
└── LICENSE
```

---

<p align="center">
  <sub>Built by <a href="https://github.com/JackRipper-ID">JackRipper-ID</a> · AjralDEV</sub>
</p>

<div align="center">
<sub>Built for Termux. OpenCode is its own open source project — this repo is only an installer.</sub>
</div>
