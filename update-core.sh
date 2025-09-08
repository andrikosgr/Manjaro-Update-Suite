#!/usr/bin/env bash
set -euo pipefail

LOGDIR="$HOME/update-logs"
mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOGFILE="$LOGDIR/update-$STAMP.log"

have_cmd() { command -v "$1" >/dev/null 2>&1; }
log() { echo "[$(date +%F' '%T)] $*" | tee -a "$LOGFILE"; }
run() { log "+ $*"; "$@" >>"$LOGFILE" 2>&1; }
notify() { have_cmd notify-send && notify-send "Update" "$1" || true; }

choose_aur_helper() {
  for h in yay paru pikaur trizen; do
    if have_cmd "$h"; then echo "$h"; return 0; fi
  done
  return 1
}

ensure_no_lock() {
  local lock="/var/lib/pacman/db.lck"
  if [[ -e "$lock" ]]; then
    log "Pacman lock found: $lock"
    sleep 5
    if [[ -e "$lock" ]]; then
      if pgrep -fa "pacman|pamac|yay|paru" >/dev/null; then
        log "Active package manager detected. Aborting."
        exit 1
      fi
      log "Removing stale lock."
      sudo rm -f "$lock"
    fi
  fi
}

disk_summary() {
  log "Disk usage before:"
  df -h | tee -a "$LOGFILE"
}

kernel_info() {
  CURRENT_KERNEL=$(uname -r)
  log "Current kernel: $CURRENT_KERNEL"
  have_cmd mhwd-kernel && run mhwd-kernel -li || true

  zenity --info \
    --title="Kernel Info" \
    --text="🧠 Current kernel: $CURRENT_KERNEL" \
    --width=400
}

check_kernel_update() {
  log "Checking for kernel updates..."
  if have_cmd mhwd-kernel; then
    CURRENT_KERNEL=$(uname -r)
    AVAILABLE_KERNELS=$(mhwd-kernel -l | awk '/linux/ {print $2}' | sort -u)

    SELECTED_KERNEL=$(echo "$AVAILABLE_KERNELS" | zenity --list \
      --title="Kernel Manager" \
      --text="Current kernel: $CURRENT_KERNEL\n\nSelect a kernel to install:" \
      --column="Available Kernels" \
      --width=500 --height=300 2>/dev/null)

    if [[ $? -ne 0 ]]; then
      log "Kernel selection dialog canceled."
      zenity --info --text="Kernel selection canceled. No changes made." --width=400
      return 0
    fi

    if [[ -n "$SELECTED_KERNEL" ]]; then
      zenity --question --text="Install kernel $SELECTED_KERNEL?" --width=400 && \
      run sudo mhwd-kernel -i "$SELECTED_KERNEL" rmc && \
      zenity --info --text="✅ Kernel $SELECTED_KERNEL installed successfully." --width=400
    else
      log "No kernel selected."
      zenity --info --text="No kernel selected. Skipping kernel update." --width=400
    fi
  fi
}

do_backup() {
  [[ "${DO_BACKUP:-0}" == "1" ]] || return 0
  if have_cmd timeshift; then
    log "Creating Timeshift snapshot"
    run sudo timeshift --create --comments "pre-update $STAMP" --yes
  elif have_cmd snapper; then
    log "Creating Snapper snapshot"
    run sudo snapper create --description "pre-update $STAMP"
  else
    log "No backup tool found. Skipping."
  fi
}

refresh_mirrors() {
  [[ "${DO_REFRESH_MIRRORS:-1}" == "1" ]] || return 0
  have_cmd pacman-mirrors && run sudo pacman-mirrors --fasttrack || true
}

refresh_keys() {
  [[ "${DO_REFRESH_KEYS:-0}" == "1" ]] || return 0
  have_cmd pacman-key && run sudo pacman-key --refresh-keys || true
}

repo_update() {
  [[ "${DO_REPO_UPDATE:-1}" == "1" ]] || return 0
  ensure_no_lock
  run sudo pacman -Sy --needed archlinux-keyring manjaro-keyring
  run sudo pacman -Syyu
}

aur_update() {
  [[ "${DO_AUR_UPDATE:-1}" == "1" ]] || return 0
  local helper
  if helper="$(choose_aur_helper)"; then
    log "Using AUR helper: $helper"
    run "$helper" -Syu
  else
    log "No AUR helper found. Skipping AUR update."
  fi
}

cleanup_cache() {
  [[ "${DO_CLEAN_CACHE:-1}" == "1" ]] || return 0
  have_cmd paccache && run paccache -rk3 && run paccache -ruk3 || true
}

cleanup_orphans() {
  [[ "${DO_REMOVE_ORPHANS:-1}" == "1" ]] || return 0
  if mapfile -t orphans < <(pacman -Qtdq 2>/dev/null) && [[ ${#orphans[@]} -gt 0 ]]; then
    run sudo pacman -Rns --noconfirm "${orphans[@]}"
  fi
  if helper="$(choose_aur_helper)" 2>/dev/null; then
    run "$helper" -Yc
  fi
}

summary_after() {
  log "Disk usage after:"
  df -h | tee -a "$LOGFILE"
}

disk_summary
kernel_info
check_kernel_update
do_backup
refresh_mirrors
refresh_keys
repo_update
aur_update
cleanup_cache
cleanup_orphans
summary_after

log "✅ Update complete."
notify "✅ System update completed"
echo "Log saved to: $LOGFILE"
