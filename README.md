<!-- DevSponsors Badges -->
<p align="center">
  <a href="https://devsponsors.github.io"><img src="https://img.shields.io/badge/DevSponsors-Verified_OSS-6366f1?style=for-the-badge&logo=github" alt="DevSponsors Verified"></a>
  <a href="https://devsponsors.github.io"><img src="https://img.shields.io/badge/Sponsor-DevSponsors_Hub-emerald?style=for-the-badge&logo=github-sponsors" alt="DevSponsors Sponsor"></a>
  <a href="https://devsponsors.github.io/mediakit.html"><img src="https://img.shields.io/badge/Infrastructure-DevSponsors_Cloud-ec4899?style=for-the-badge&logo=server" alt="DevSponsors Cloud"></a>
</p>

# Persian Gravity (Antigravity-RTL) 🚀

Smart Right-to-Left (RTL) alignment and custom font patcher for the Antigravity AI-first development application and major IDEs (VS Code, Cursor, Trae, VSCodium, Windsurf).

> 🟢 **Tested and verified on:** `macOS 15.7.3 (Sequoia)` & `Antigravity v2.6.0` (with full success)

![Antigravity RTL Preview](./assets/preview.png)

---

### **In Memory of Saber Rastikerdar 🕯️**
> This project is dedicated to the memory of **Saber Rastikerdar** (the creator of beautiful libre fonts like Vazirmatn, Shabnam, Samim, Sahel, and Gandom), who beautified Persian typography across the web and digital platforms. May he rest in peace.

---

## 🌐 Multilingual READMEs
- [🇮🇷 نسخه فارسی (Persian)](./README-FA.md)
- [🇸🇦 اقرأ بالعربية (Arabic)](./README-AR.md)
- [🇮🇱 קרא בעברית (Hebrew)](./README-HE.md)

---

## 🛠️ Features
- **Antigravity App UI Auto-Patching**: Smart RTL alignment for the chat canvas, menus, and general panels.
- **Auto-Persistence Daemon Across Updates** 🔄: Seamlessly registers a background watcher service (`LaunchAgent` on macOS, `Scheduled Task` on Windows, and `systemd` user service on Linux). Whenever Antigravity updates and replaces its internal assets, the patch is automatically re-applied without manual intervention.
- **Automated Font Installation**: Downloads and installs the latest version of Vazirmatn (or other custom fonts) directly to the system Font Library.
- **IDE Configuration**: Automatically updates `settings.json` configurations to use Vazirmatn in Antigravity, VS Code, Cursor, Trae, VSCodium, and Windsurf.
- **Cross-Platform Support**: Custom scripts provided for macOS, Windows, and Linux.

---

## 🚀 One-Click Installation
To install the font and apply the patch automatically:
- **macOS**: Download and double-click [`setup_vazirmatn.command`](./setup_vazirmatn.command)
- **Windows**: Run [`setup_vazirmatn.ps1`](./setup_vazirmatn.ps1) with PowerShell
- **Linux**: Execute [`setup_vazirmatn_linux.sh`](./setup_vazirmatn_linux.sh)

---

## 📣 Demand Native RTL Support from Google

To make this patch obsolete and encourage Google to support RTL languages (Persian, Arabic, Hebrew) and quality fonts natively in Antigravity:

1. **Email the Team**: Send your feedback to `antigravity-support@google.com`.
2. **In-App Feedback**: Open Antigravity, press `Cmd + ,` (Mac) or `Ctrl + ,` (Windows/Linux), click **Feedback**, and submit your message.

Let's make RTL development a first-class citizen! 🚀

---

## 🔗 Related Projects
- **[claude-rtl-patcher](https://github.com/m4tinbeigi-official/claude-rtl-patcher)**: A similar tool to patch the official Claude Desktop app for RTL and Vazirmatn support.
