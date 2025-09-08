#!/usr/bin/env bash
set -euo pipefail

CORE="$HOME/update-core.sh"
[[ -x "$CORE" ]] || { zenity --error --text="Core script not found:\n$CORE"; exit 1; }

# 🛑 Close Pamac GUI if running
if pgrep -x pamac-manager >/dev/null 2>&1; then
  zenity --question --title="Close Pamac GUI?" --text="Pamac is running. Close it?"
  [[ $? -eq 0 ]] && killall pamac-manager 2>/dev/null || true
fi

# 🧙‍♂️ Show update options
CONF="$(zenity --forms \
  --title="Manjaro Update Control Panel" \
  --text="Current kernel: $CURRENT_KERNEL\n\nChoose your update options:" \
  --separator="|" \
  --add-combo="Refresh mirrors" --combo-values="Yes|No" \
  --add-combo="Refresh keys"    --combo-values="No|Yes" \
  --add-combo="Update repos"    --combo-values="Yes|No" \
  --add-combo="Update AUR"      --combo-values="Yes|No" \
  --add-combo="Clean cache"     --combo-values="Yes|No" \
  --add-combo="Remove orphans"  --combo-values="Yes|No" \
  --add-combo="Create backup"   --combo-values="No|Yes" \
  --add-combo="Install new kernel?" --combo-values="No|Yes" \
  --add-combo="Select kernel to install" --combo-values="$AVAILABLE_KERNELS" \
  --width=500 --height=400
)" || exit 1

to_bool() { [[ "$1" == "Yes" ]] && echo 1 || echo 0; }

export DO_REFRESH_MIRRORS="$(to_bool "$(cut -d'|' -f1 <<<"$CONF")")"
export DO_REFRESH_KEYS="$(to_bool "$(cut -d'|' -f2 <<<"$CONF")")"
export DO_REPO_UPDATE="$(to_bool "$(cut -d'|' -f3 <<<"$CONF")")"
export DO_AUR_UPDATE="$(to_bool "$(cut -d'|' -f4 <<<"$CONF")")"
export DO_CLEAN_CACHE="$(to_bool "$(cut -d'|' -f5 <<<"$CONF")")"
export DO_REMOVE_ORPHANS="$(to_bool "$(cut -d'|' -f6 <<<"$CONF")")"
export DO_BACKUP="$(to_bool "$(cut -d'|' -f7 <<<"$CONF")")"

LOGDIR="$HOME/update-logs"
mkdir -p "$LOGDIR"
"$CORE" &
CORE_PID=$!

for i in {1..40}; do
  LATEST="$(ls -1t "$LOGDIR"/update-*.log 2>/dev/null | head -n1 || true)"
  [[ -n "${LATEST:-}" ]] && break
  sleep 0.5
done

if [[ -n "${LATEST:-}" ]]; then
  tail -f "$LATEST" | zenity --text-info \
    --title="Live update log" \
    --width=900 --height=600 \
    --ok-label="Close" || true
else
  zenity --warning --text="Log file not found. Update running in background (PID $CORE_PID)." --width=400
fi

wait $CORE_PID && \
zenity --question --text="✅ Update completed.\n\nDo you want to view the log file?" --width=400 && \
xdg-open "$LOGFILE" || \
zenity --info --text="✅ Update completed. Log viewer skipped." --width=400

# If update failed
[ $? -ne 0 ] && zenity --error --text="❌ Update failed. Please check your system logs." --width=400
