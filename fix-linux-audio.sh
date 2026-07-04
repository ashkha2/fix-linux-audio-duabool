#!/bin/bash
# Fix: mute speakers, keep headset output.
set -euo pipefail

DEV="/dev/snd/hwC1D0"
CODEC="/sys/class/sound/hwC1D0"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run as sudo: sudo $0" >&2
  exit 1
fi

if [[ -n "${PKEXEC_UID:-}" ]]; then
  TARGET_USER="$(getent passwd "$PKEXEC_UID" | cut -d: -f1)"
  TARGET_UID="$PKEXEC_UID"
elif [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  TARGET_USER="$SUDO_USER"
  TARGET_UID="$(id -u "$TARGET_USER")"
else
  TARGET_USER="$(logname 2>/dev/null || echo "${USER:$TARGET_USER}")"
  TARGET_UID="$(id -u "$TARGET_USER")"
fi

RUNTIME_DIR="/run/user/${TARGET_UID}"

user_systemctl() {
  runuser -u "$TARGET_USER" -- \
    env XDG_RUNTIME_DIR="$RUNTIME_DIR" \
    systemctl --user "$@"
}

stop_audio() {
  [[ -d "$RUNTIME_DIR" ]] || return 0
  user_systemctl stop pipewire-pulse.service pipewire-pulse.socket 2>/dev/null || true
  user_systemctl stop wireplumber.service 2>/dev/null || true
  user_systemctl stop pipewire.service pipewire.socket 2>/dev/null || true
  sleep 2
}

start_audio() {
  [[ -d "$RUNTIME_DIR" ]] || return 0
  user_systemctl start pipewire.socket pipewire.service 2>/dev/null || true
  user_systemctl start wireplumber.service 2>/dev/null || true
  user_systemctl start pipewire-pulse.socket pipewire-pulse.service 2>/dev/null || true
}

apply_fix() {
  [[ -d "$CODEC" ]] && echo "0x18 0x03a19020" > "$CODEC/user_pin_configs"

  # Disable speaker pin, keep headphones active
  hda-verb "$DEV" 0x17 SET_PIN_WIDGET_CONTROL 0x00
  hda-verb "$DEV" 0x18 SET_PIN_WIDGET_CONTROL 0xc0
  hda-verb "$DEV" 0x18 SET_UNSOLICITED_ENABLE 0x82
}

stop_audio
apply_fix
start_audio
echo $TARGET_USER
echo "Done: Internal speakers are turned off."
