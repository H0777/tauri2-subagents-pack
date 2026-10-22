# Tauri 2 + Rust Subagents Pack for Windows 11

[![Tauri v2](https://img.shields.io/badge/Tauri-v2.0-blue.svg)](https://v2.tauri.app/)
[![Rust](https://img.shields.io/badge/Rust-2021%20%2F%202024-orange.svg)](https://www.rust-lang.org/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2011%20(MSVC)-0078D6.svg)](https://microsoft.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Multi-Harness](https://img.shields.io/badge/Supported-8%20AI%20Harnesses-purple.svg)](docs/MULTI-HARNESS.md)

[English](#english) | [العربية](#العربية)

---

<a name="english"></a>
## English Overview

A production-ready suite of **10 specialized AI subagents** and architectural rules designed for high-velocity, reliable **Tauri 2 + Rust** desktop development on **Windows 11**.

Includes pre-built profile generators and automatic installers for multiple AI coding tools and IDEs: **Claude Code, Cursor, GitHub Copilot, Codex, Gemini CLI, ZCode, OpenCode, and Hermes**.

---

### The 10 Subagents

| Role | Name | Scope & Responsibility | Mode |
|---|---|---|---|
| 📐 Architecture | `tauri-architect` | Boundaries, module layout, file ownership, and architectural planning | Read-Only |
| 🦀 Rust Backend | `tauri-rust` | Backend logic, state management, safe concurrency, and MSVC targeting | Implementation |
| 🎨 Frontend & IPC | `tauri-frontend` | UI frameworks, static export compatibility, and typed IPC bindings | Implementation |
| 🔌 IPC Contracts | `tauri-ipc` | Command/event/channel contracts, serialization, and error schemas | Read-Only |
| 🛡️ Security & ACL | `tauri-security` | Capabilities, permission files, scopes, CSP, and audit findings | Read-Only |
| 🪟 Windows OS | `tauri-windows` | WebView2 lifecycle, registry, shortcuts, single-instance, and OS events | Implementation |
| 🧩 Plugins | `tauri-plugins` | Official plugin registration, scoped filesystem, and permissions | Implementation |
| 🧪 Testing | `tauri-test` | Unit, IPC mocking, and Windows native integration tests | Implementation |
| ⚡ Performance | `tauri-perf` | Startup latency, WebView2 memory, and binary size optimization | Implementation |
| 📦 Packaging | `tauri-release` | NSIS/MSI installers, updater signing, and release preflight | Implementation |

---

### Supported AI Coding Harnesses

| Platform | Default Path | Format & Details |
|---|---|---|
| **Cursor** | `~/.cursor/agents/*.md` | Read-only enforcement for review roles; `tauri-pack-guide.md` integration |
| **Claude Code** | `~/.claude/agents/*.md` | Explicit tools & `maxTurns` allocation |
| **GitHub Copilot / VS Code** | `~/.copilot/agents/*.agent.md` | User-level custom agents & guidelines |
| **OpenAI Codex** | `~/.codex/agents/*.toml` | TOML schemas with developer instructions & sandbox mode |
| **Gemini CLI** | `~/.gemini/agents/*.md` | Local agents with arrays of permitted tools |
| **ZCode** | `~/.zcode/agents/*.md` | Native subagent definition with `AGENTS.md` context injection |
| **OpenCode** | `~/.config/opencode/agents/*.md` | Supports both v1 and v2 permission formats |
| **Hermes** | `~/.hermes/tauri-pack/roles/*.md` | Delegated prompt library for `delegate_task` |

---

### Quick Start by Operating System

Choose the installer matching your operating system:

#### 🪟 Windows (One-Click)
- Double-click **`Install.cmd`** in the root directory for an interactive installer with automatic tool discovery and installation.
- Or run **`installers/install-windows.cmd`** (or scan with `installers/list-programs.cmd`).
- *Or via PowerShell:*
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\validate.ps1
  powershell -ExecutionPolicy Bypass -File .\scripts\install-all.ps1
  ```

#### 🍏 macOS (One-Click or Terminal)
- **One-Click:** Run **`Install.sh`** from root or double-click **`installers/install-macos.command`** in Finder.
- *Or via Terminal:*
  ```bash
  bash Install.sh
  ```

#### 🐧 Linux (Terminal)
- In your terminal, run:
  ```bash
  bash Install.sh
  ```
  *(Platform-specific scripts are also available in `installers/`)*

#### Safety, Backups & Rollback
- **Non-destructive**: Automatically backs up original files with SHA256 checksums before applying any changes.
- **Idempotent**: Re-running does not duplicate content or touch unchanged files.
- **Easy Rollback**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\restore.ps1 -BackupPath 'C:\Users\YOUR_USERNAME\.zcode\backups\tauri-pack\BACKUP_ID'
  ```

---

<a name="العربية"></a>
## الوصف بالعربية

حزمة برمجية متكاملة تضم **10 وكلاء ذكاء اصطناعي متخصصين (Subagents)** وقواعد معمارية دقيقة لتطوير تطبيقات **Tauri 2 + Rust على نظام Windows 11**.

تدعم الحزمة التثبيت التلقائي والمباشر في 8 بيئات ذكاء اصطناعي مختلفة تشمل: **Cursor, Claude Code, GitHub Copilot, Codex, Gemini CLI, ZCode, OpenCode, و Hermes**.

---

### الوكلاء العشرة واختصاصاتهم

- **`tauri-architect`** *(قراءة فقط)*: فحص المعمارية، رسم حدود المهام وتوزيع مسؤوليات الملفات.
- **`tauri-rust`** *(تنفيذ)*: برمجة منطق Rust الخلفي، الأمان، وإدارة الحالة والتزامن.
- **`tauri-frontend`** *(تنفيذ)*: واجهة المستخدم وتكامل الـ IPC وضبط التصدير الثابت (Static Export).
- **`tauri-ipc`** *(قراءة فقط)*: تصميم عقود الاتصال (Commands / Events / Channels) وهياكل الأخطاء.
- **`tauri-security`** *(قراءة فقط)*: مراجعة الصلاحيات والـ Scopes وحماية مسارات النظام وCSP.
- **`tauri-windows`** *(تنفيذ)*: دورة حياة النظام، دعم WebView2، وتكامل سطح مكتب Windows 11.
- **`tauri-plugins`** *(تنفيذ)*: إدارة وتضمين إضافات Tauri 2 وتفعيل الصلاحيات المناسبة لها.
- **`tauri-test`** *(تنفيذ)*: كتابة اختبارات الوحدة، محاكاة الـ IPC واختبارات التكامل الفعلية.
- **`tauri-perf`** *(تنفيذ)*: قياس وتحسين سرعة الإقلاع، استهلاك الذاكرة وحجم الملف التنفيذي.
- **`tauri-release`** *(تنفيذ)*: بناء الحزم ومثبتات NSIS/MSI وتجهيز التوقيع والتحديث التلقائي.

---

### طريقة التثبيت حسب نظام التشغيل

اختر ملف التثبيت المخصص لنظامك:

#### 🪟 لمستخدمي Windows
- اضغط مرتين (Double Click) على **`Install.cmd`** في المجلد الرئيسي لتشغيل معالج التثبيت الذكي مع خيارات الفحص والتثبيت.
- أو يمكنك استخدام ملف **`installers/install-windows.cmd`** المباشر (أو فحص البرامج عبر `installers/list-programs.cmd`).
- *أو عبر PowerShell:*
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\validate.ps1
  powershell -ExecutionPolicy Bypass -File .\scripts\install-all.ps1
  ```

#### 🍏 لمستخدمي macOS
- **بضغطة زر:** شغّل **`Install.sh`** في الجذر أو اضغط مرتين على **`installers/install-macos.command`** في الـ Finder.
- *أو عبر الطرفية (Terminal):*
  ```bash
  bash Install.sh
  ```

#### 🐧 لمستخدمي Linux
- افتح الطرفية (Terminal) وشغّل:
  ```bash
  bash Install.sh
  ```

---

### هيكلية المجلدات المنظمة

```
tauri2-subagents-pack/
├── 📁 agents/            # تعريفات الوكلاء العشرة الأساسية لـ Tauri 2
├── 📁 profiles/          # ملفات التشكيلات المصدّرة للبيئات الأخرى (Cursor, Claude, Codex, إلخ)
├── 📁 docs/              # مجلد التوثيق والأدلة المتقدمة
│   ├── CHANGELOG.md
│   ├── INSTALL.txt
│   ├── LEGACY-AGENTS.md
│   ├── MULTI-HARNESS.md
│   ├── SMOKE-TESTS.md
│   └── VALIDATION.md
├── 📁 scripts/           # سكربتات التشغيل والتحقق وبناء التشكيلات
│   ├── build-profiles.ps1
│   ├── install-all.ps1
│   ├── install.ps1
│   ├── install.sh
│   ├── package-tools.ps1
│   ├── restore.ps1
│   ├── test-package.ps1
│   └── validate.ps1
├── 📁 installers/        # ملفات التثبيت الإضافية لأنظمة macOS و Linux
├── 📄 Install.cmd        # 🪟 المثبت الرئيسي لنظام ويندوز بنقرة واحدة
├── 📄 Install.sh         # 🍎/🐧 المثبت الرئيسي لأنظمة macOS / Linux
├── 📄 AGENTS.md          # القواعد المعمارية العامة للتطوير
├── 📄 LICENSE            # رخصة المشروع
└── 📄 README.md          # دليل الاستخدام
```

---

### الأمان والنسخ الاحتياطي
- يقوم المثبت تلقائياً بعمل نسخة احتياطية مشفرة بـ SHA256 لكل ملف يتم تعديله في المسار: `backups\tauri-pack\<id>`.
- التثبيت المتكرر آمن تماماً (Idempotent) ولا يكرر التعليمات.
- يمكنك إلغاء التثبيت واسترجاع ملفاتك السابقة في أي وقت عبر أمر:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore.ps1 -BackupPath 'C:\Users\YOUR-NAME\.zcode\backups\tauri-pack\BACKUP-ID'
```

---

### الوثائق والمراجع
- [تفاصيل البرامج المدعومة وصيغها (docs/MULTI-HARNESS.md)](docs/MULTI-HARNESS.md)
- [فحوصات التجربة والاختبار (docs/SMOKE-TESTS.md)](docs/SMOKE-TESTS.md)
- [معايير التحقق الأمني والمعماري (docs/VALIDATION.md)](docs/VALIDATION.md)
- [سجل التغييرات (docs/CHANGELOG.md)](docs/CHANGELOG.md)
- [توثيق Tauri 2 الرسمي](https://v2.tauri.app/)

---

### الترخيص
مرخص تحت رخصة [MIT](LICENSE).
