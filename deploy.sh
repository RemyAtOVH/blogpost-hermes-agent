#!/usr/bin/env bash
#
# deploy.sh — bootstrap Hermes Agent on a fresh Debian instance, over SSH.
# Shared by both deployment paths of this repo: OVHcloud VPS (vps/) and
# Public Cloud instance (public-cloud/).
# Companion to the blog post "Votre agent IA ne devrait pas s'endormir quand
# vous fermez votre laptop".
#
# Usage:
#   ./deploy.sh debian@$(terraform output -raw vps_ip)
#
# Steps:
#   1. prerequisites            (git, curl, xz-utils, libatomic1)
#   2. official Hermes install  (~2 min: pinned Python, Node.js, ripgrep, ffmpeg, Chromium)
#   3. hermes model             (interactive — pick your provider/model)
#   4. hermes gateway setup     (interactive — paste your Telegram BotFather token)
#   5. systemd boot service     (hermes gateway install --system)
#
# Prefer Signal over Telegram? Read SIGNAL.md first, then redo steps 4–5 by hand.

set -euo pipefail

TARGET="${1:?usage: ./deploy.sh <user@host>}"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

step "1/5 — prerequisites"
# On a fresh instance, cloud-init / unattended-upgrades may still hold the apt lock.
# libatomic1: Node.js needs it, and the non-interactive installer won't install it.
ssh -t "$TARGET" '
  if command -v cloud-init >/dev/null; then cloud-init status --wait >/dev/null || true; fi
  sudo apt-get -o DPkg::Lock::Timeout=300 update -y &&
  sudo apt-get -o DPkg::Lock::Timeout=300 install -y git curl xz-utils libatomic1'

step "2/5 — official Hermes installer (~2 minutes)"
# --non-interactive: skip the installer's own setup wizard and gateway service
# (a user-scope unit) — steps 3–5 handle both, with a system-scope unit.
# --skip-computer-use: the desktop-control tool needs X11, absent on a headless server.
ssh -t "$TARGET" 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive --skip-computer-use'

step "3/5 — choose your model provider (interactive)"
ssh -t "$TARGET" 'export PATH="$HOME/.local/bin:$PATH"; hermes model'

step "4/5 — configure the messaging gateway (interactive)"
printf '    When asked how the gateway should run, pick "Skip service install for now":\n    step 5 installs it as a boot-time system service instead.\n'
ssh -t "$TARGET" 'export PATH="$HOME/.local/bin:$PATH"; hermes gateway setup'

step "5/5 — install the gateway as a boot-time systemd service"
# sudo resets HOME to /root: pass HERMES_HOME so hermes uses your install, not
# root's. Then hand back any file root wrote (Python caches) to your user.
ssh -t "$TARGET" 'sudo env HERMES_HOME="$HOME/.hermes" "$HOME/.local/bin/hermes" gateway install --system &&
  sudo chown -R "$(id -u):$(id -g)" "$HOME/.hermes"'

cat <<EOF

Done. Open Telegram and say hi to your agent.

Useful:
  ssh -t $TARGET 'export PATH="\$HOME/.local/bin:\$PATH"; hermes doctor'
  ssh -t $TARGET 'systemctl list-units | grep -i hermes'
  ssh -t $TARGET 'export PATH="\$HOME/.local/bin:\$PATH"; hermes update'

Next: security checklist in README.md (allowlists, firewall, scoped tokens).
EOF
