#!/usr/bin/env bash
set -euo pipefail

CORE="$HOME/update-core.sh"
[[ -x "$CORE" ]] || { zenity --error --text="Core script not found:\n$CORE" --width=400; exit 1; }

# 🛑 Close Pamac GUI if running
if pgrep -x pamac-manager >/dev/null 2>&1; then
  zenity --question --title="Close Pamac GUI?" --text="Pamac is running. Close it?" --width=400
  [[ $? -eq 0 ]] && killall pamac-manager 2>/dev/null || true
fi

# 🧠 Detect current kernel and available options
CURRENT_KERNEL=$(uname -r)
AVAILABLE_KERNELS=$(mhwd-kernel -l | awk '/linux/ {print $2}' | sort -u | paste -sd '|' -)

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
  --width=500 --height=450
)" || exit 1

# 🔄 Convert Yes/No to 1/0
to_bool() { [[ "$1" == "Yes" ]] && echo 1 || echo 0; }

# 🧩 Parse form values
IFS="|" read -r \
  REFRESH_MIRRORS \
  REFRESH_KEYS \
  REPO_UPDATE \
  AUR_UPDATE \
  CLEAN_CACHE \
  REMOVE_ORPHANS \
  CREATE_BACKUP \
  INSTALL_KERNEL \
  SELECTED_KERNEL <<< "$CONF"

export DO_REFRESH_MIRRORS="$(to_bool "$REFRESH_MIRRORS")"
export DO_REFRESH_KEYS="$(to_bool "$REFRESH_KEYS")"
export DO_REPO_UPDATE="$(to_bool "$REPO_UPDATE")"
export DO_AUR_UPDATE="$(to_bool "$AUR_UPDATE")"
export DO_CLEAN_CACHE="$(to_bool "$CLEAN_CACHE")"
export DO_REMOVE_ORPHANS="$(to_bool "$REMOVE_ORPHANS")"
export DO_BACKUP="$(to_bool "$CREATE_BACKUP")"

# 🛠️ Trigger kernel install if selected
if [[ "$INSTALL_KERNEL" == "Yes" && -n "$SELECTED_KERNEL" ]]; then
  zenity --question --text="Install kernel $SELECTED_KERNEL?" --width=400 && \
  sudo mhwd-kernel -i "$SELECTED_KERNEL" rmc && \
  zenity --info --text="✅ Kernel $SELECTED_KERNEL installed successfully." --width=400
else
  echo "Kernel update skipped."
fi

# 📦 Run core update script
LOGDIR="$HOME/update-logs"
mkdir -p "$LOGDIR"
"$CORE" &
CORE_PID=$!

# 🧾 Wait for log file to appear
for i in {1..40}; do
  LATEST="$(ls -1t "$LOGDIR"/update-*.log 2>/dev/null | head -n1 || true)"
  [[ -n "${LATEST:-}" ]] && break
  sleep 0.5
done

# 📺 Show live log
if [[ -n "${LATEST:-}" ]]; then
  tail -f "$LATEST" | zenity --text-info \
    --title="Live update log" \
    --width=900 --height=600 \
    --ok-label="Close" || true
else
  zenity --warning --text="Log file not found. Update running in background (PID $CORE_PID)." --width=400
fi

# ✅ Final log viewer prompt
wait $CORE_PID && \
zenity --question --text="✅ Update completed.\n\nDo you want to view the log file?" --width=400 && \
xdg-open "$LATEST" || \
zenity --info --text="✅ Update completed. Log viewer skipped." --width=400

# ❌ If update failed
[ $? -ne 0 ] && zenity --error --text="❌ Update failed. Please check your system logs." --width=400
