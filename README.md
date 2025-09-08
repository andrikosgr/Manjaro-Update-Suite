# 📦 Manjaro Update Suite
[![Release](https://img.shields.io/github/v/release/andrikosgr/Manjaro-Update-Suite?label=Latest%20Release)](https://github.com/andrikosgr/Manjaro-Update-Suite/releases)



A GUI-powered, future-proof system updater for Manjaro and Arch-based Linux distributions.  
Built with Bash and Zenity, this tool gives you full control over system maintenance—without needing to touch the terminal.

---

## 🧙‍♂️ Features

```bash
# Manjaro Update Suite Menu

1) Refresh Mirrors
2) Refresh Keyrings
3) Update Official Repos
4) Update AUR Packages
5) Kernel Check & Install
6) Create Backup (Timeshift/Snapper)
7) Clean Cache & Remove Orphans
8) View Live Log
9) Exit
```

---

## 🚀 One-Line Installer

```bash
curl -sSL https://raw.githubusercontent.com/andrikosgr/Manjaro-Update-Suite/main/update-gui.sh | bash
```

> ⚠️ Requires: `zenity`, `yay` or `paru`, `paccache`, and optionally `timeshift` or `snapper`.

---

## 🖥️ Desktop Launcher

To add a clickable launcher to your app menu:

```bash
cp update-gui.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications
```

Then search for **Update Control Panel** in your menu.

---

## 📂 File Overview

| File                  | Description                                      |
|-----------------------|--------------------------------------------------|
| `update-core.sh`      | Main update logic with smart fallbacks           |
| `update-gui.sh`       | Zenity GUI wrapper with user options             |
| `update-gui.desktop`  | App launcher for desktop environments            |

---

## 🧪 Demo Output

```console
andreas@manjaro:~$ ./update-gui.sh
🧙‍♂️ Launching Update Control Panel...

Choose your options:
[✓] Refresh mirrors
[✓] Update AUR
[✓] Kernel check
[✓] Create backup
[✓] Clean cache

✅ Update complete!
Log saved to: ~/update-logs/update-20250908-0148.log
```

---

## 🧠 Requirements

- Manjaro or Arch-based distro  
- Bash  
- Zenity (`sudo pacman -S zenity`)  
- AUR helper like `yay` or `paru`  
- Optional: Timeshift or Snapper for backups

---

## 🛠️ Customization

You can tweak the behavior by editing `update-core.sh`:
- Change default kernel target (`linux-lts`, `linux515`, etc.)
- Add more cleanup routines
- Integrate Flatpak or Snap updates

---

## 📜 License

MIT License — free to use, modify, and share.

---

## ✅ Suggested Commit Messages

| File                  | Commit Message                                               |
|-----------------------|--------------------------------------------------------------|
| `update-core.sh`      | Add core update logic with kernel, backup, and cleanup support |
| `update-gui.sh`       | Add Zenity GUI wrapper with user options and live log viewer |
| `update-gui.desktop`  | Add desktop launcher for Update Control Panel                |
| `README.md`           | Create README with bash-style menu and installer instructions |
| `.gitignore`          | Ignore .vs folder to prevent permission errors in Visual Studio |
