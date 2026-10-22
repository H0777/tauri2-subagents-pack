# 🦀 Tauri 2 Subagents Pack (v2.0.0)

[![GitHub Repo](https://img.shields.io/badge/GitHub-tauri2--subagents--pack-181717?logo=github)](https://github.com/H0777/tauri2-subagents-pack)
[![Tauri v2](https://img.shields.io/badge/Tauri-v2.0-blue.svg)](https://v2.tauri.app/)
[![Rust](https://img.shields.io/badge/Rust-2021%20%2F%202024-orange.svg)](https://www.rust-lang.org/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2011%20(MSVC)-0078D6.svg)](https://microsoft.com)
[![Tests](https://img.shields.io/badge/Tests-57%2F57%20Passing-brightgreen.svg)](scripts/test-package.ps1)
[![Supported AI Tools](https://img.shields.io/badge/AI%20Harnesses-8%20Supported-purple.svg)](docs/MULTI-HARNESS.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](#english) | [العربية](#العربية)

---

<a name="english"></a>
## English Overview

**Tauri 2 Subagents Pack** is a production-grade suite of **10 specialized AI subagents**, strict architectural rules, and cross-platform automation designed for building high-performance, secure desktop applications with **Tauri 2 + Rust** on **Windows 11** (MSVC).

The pack equips your AI coding environment with a full virtual desktop development team, pre-configured with bounded roles, read-only safety guards, typed IPC contracts, and automated backups.

### 🌟 Key Features

- **10 Specialized Roles**: Dedicated subagents covering Architecture, Rust Backend, Frontend IPC, Security & ACL, Windows OS Lifecycle, Plugins, Testing, Performance, and Packaging.
- **Broad AI Ecosystem Support**: Ready-to-use profiles for **Cursor, Claude Code, GitHub Copilot, OpenAI Codex, Gemini CLI, ZCode, OpenCode, and Hermes**.
- **1-Click Interactive Installer**: Fast setup on Windows via `Install.cmd` (or `Install.sh` on macOS/Linux) with automated environment detection.
- **Zero-Risk & Idempotent**: Automatic SHA-256 pre-write backups with non-destructive merge and single-command rollback.
- **Verified Quality**: Comes with a built-in test suite passing **57/57** automated architectural and lifecycle checks.

---

### 👥 The 10 Subagents

| Role | Name | Scope & Responsibility | Permissions |
|---|---|---|---|
| 📐 **Architecture** | `tauri-architect` | Boundaries, module layout, file ownership, and architectural planning | `Read-Only` |
| 🦀 **Rust Backend** | `tauri-rust` | Backend commands, state management, safe concurrency, and MSVC targeting | `Implementation` |
| 🎨 **Frontend & IPC** | `tauri-frontend` | UI frameworks (Vite, React, Svelte, Vue), static export compatibility, and typed IPC | `Implementation` |
| 🔌 **IPC Contracts** | `tauri-ipc` | Command/event/channel signatures, serialization, and error schemas | `Read-Only` |
| 🛡️ **Security & ACL** | `tauri-security` | Capabilities, permission files, scopes, CSP, and audit findings | `Read-Only` |
| 🪟 **Windows OS** | `tauri-windows` | WebView2 lifecycle, registry, shortcuts, single-instance, and OS events | `Implementation` |
| 🧩 **Plugins** | `tauri-plugins` | Official plugin registration, scoped filesystem, and permissions | `Implementation` |
| 🧪 **Testing** | `tauri-test` | Unit tests, IPC mocking, and Windows native integration tests | `Implementation` |
| ⚡ **Performance** | `tauri-perf` | Startup latency, WebView2 memory footprint, and binary size optimization | `Implementation` |
| 📦 **Packaging** | `tauri-release` | NSIS/MSI installers, updater signing, and release preflight | `Implementation` |

---

### 💻 Supported AI Coding Tools

| Platform | Location | Profile Notes |
|---|---|---|
| **Cursor** | `~/.cursor/agents/*.md` | Native subagents; read-only role protection; `tauri-pack-guide.md` integration |
| **Claude Code** | `~/.claude/agents/*.md` | Structured subagent definitions with tool allocations and `maxTurns` |
| **GitHub Copilot** | `~/.copilot/agents/*.agent.md` | User-level custom agents for VS Code Copilot |
| **OpenAI Codex** | `~/.codex/agents/*.toml` | TOML schemas with developer instructions & sandbox mode |
| **Gemini CLI** | `~/.gemini/agents/*.md` | Local agents with arrays of permitted tools |
| **ZCode** | `~/.zcode/agents/*.md` | Native subagent definition with `AGENTS.md` context injection |
| **OpenCode** | `~/.config/opencode/agents/*.md` | Supports both v1 and v2 permission formats |
| **Hermes** | `~/.hermes/tauri-pack/roles/*.md` | Delegated prompt library for `delegate_task` |

---

### 🚀 Quick Start & Installation

#### 🪟 Windows (1-Click)
Double-click **`Install.cmd`** in the root directory:
```text
===================================================================
   Tauri 2 + Rust Subagents Pack (v2.0.0) - Installer
===================================================================

  [1] Install for all detected AI coding tools (Recommended)
  [2] Scan and list detected AI coding tools
  [3] Exit

Select an option [1-3, Default=1]:
```
- Option `1` automatically detects installed AI tools and installs the pack with backups.
- Option `2` lists all discovered coding environments.
- *Or run via PowerShell:*
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\install-all.ps1
  ```

#### 🍏 macOS & 🐧 Linux
Run the universal launcher in your terminal:
```bash
bash Install.sh
```
*(Platform-specific scripts are also located in [📁 `installers/`](installers/))*

#### 🔄 Rollback & Restoration
Every installation creates an isolated, SHA-256 verified backup before modifying any files. To revert:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore.ps1 -BackupPath 'C:\Users\YOUR_USERNAME\.zcode\backups\tauri-pack\BACKUP_ID'
```

---

### 📁 Project Structure

```text
tauri2-subagents-pack/
├── 📁 agents/            # Ten canonical Tauri 2 subagent definitions
├── 📁 profiles/          # Exported profiles for Cursor, Claude, Copilot, Codex, etc.
├── 📁 docs/              # Comprehensive technical documentation & guides
│   ├── CHANGELOG.md      # Version history and release notes
│   ├── INSTALL.txt       # Plain-text quick installation summary
│   ├── LEGACY-AGENTS.md  # Upgrade rules from previous legacy agents
│   ├── MULTI-HARNESS.md  # Detailed harness specs, paths, and limitations
│   ├── SMOKE-TESTS.md    # Post-installation verification checklists
│   └── VALIDATION.md     # Security rules and architectural guarantees
├── 📁 installers/        # Standalone platform launchers (Windows, macOS, Linux)
│   ├── install-windows.cmd
│   ├── install-macos.command
│   ├── install-macos.sh
│   ├── install-linux.sh
│   └── list-programs.cmd
├── 📁 scripts/           # Core automation, build, and validation scripts
│   ├── build-profiles.ps1
│   ├── install-all.ps1
│   ├── install.ps1
│   ├── install.sh
│   ├── package-tools.ps1
│   ├── restore.ps1
│   ├── test-package.ps1
│   ├── validate.ps1
│   ├── verify-formats.py
│   └── SHA256SUMS.json
├── 📄 Install.cmd        # 🪟 Unified Windows 1-click installer
├── 📄 Install.sh         # 🍎/🐧 Universal macOS & Linux installer
├── 📄 AGENTS.md          # Core Tauri 2 + Rust architectural rules
├── 📄 README.md          # Project documentation (Bilingual)
└── 📄 LICENSE            # MIT License
```

---

### 💡 How to Use the Subagents

Once installed in your AI coding tool (such as **Cursor**, **Claude Code**, or **ZCode**), delegate tasks using subagent handles in chat:

```text
User: @tauri-architect review the proposed module boundaries for the file downloader feature.
User: @tauri-ipc define the IPC command and error schema for downloading chunks.
User: @tauri-rust implement the Rust command in src-tauri/src/download.rs with safe concurrency.
User: @tauri-security review capabilities and permissions for local file writes.
```

---

<a name="العربية"></a>
## الوصف بالعربية

**حزمة وكلاء Tauri 2 (Tauri 2 Subagents Pack)** هي حزمة برمجية متكاملة واحترافية تضم **10 وكلاء ذكاء اصطناعي متخصصين (Subagents)**، وقواعد معمارية دقيقة، ومثبتات آلية متعددة المنصات مصممة لبناء تطبيقات سطح مكتب فائقة الأداء والأمان باستخدام **Tauri 2 + Rust على نظام Windows 11**.

تقوم الحزمة بتجهيز بيئة الذكاء الاصطناعي التي تستخدمها بفريق برمجي متكامل وموزع المهام؛ حيث يمتلك كل وكيل اختصاصاً محدداً بحدود واضحة وصلاحيات أمان صارمة (قراءة فقط للمراجعين، وتنفيذ للمبرمجين).

---

### 🌟 أبرز المميزات

1. **10 وكلاء متخصصين**: تغطية معمارية شاملة تشمل (المعمارية، المنطق الخلفي في Rust، واجهة المستخدم وIPC، عقود الاتصال، تدقيق الأمان وACL، دورة حياة نظام Windows 11، الإضافات، الاختبارات، قياس الأداء، وتجهيز حزم التثبيت NSIS/MSI).
2. **دعم 8 بيئات ذكاء اصطناعي مختلفة**: تشمل **Cursor, Claude Code, GitHub Copilot, OpenAI Codex, Gemini CLI, ZCode, OpenCode, و Hermes**.
3. **مثبت ذكي بنقرة واحدة (`Install.cmd`)**: يكتشف تلقائياً بيئات العمل المثبتة في جهازك ويقوم بالتثبيت دون الحاجة لأي إعدادات معقدة.
4. **أمان تام مع نسخ احتياطي واسترجاع فوري**: يقوم بحفظ نسخة مشفرة بـ SHA-256 قبل كتابة أي ملف مع إمكانية التراجع الكامل في أي لحظة عبر `restore.ps1`.
5. **جودة وموثوقية عالية**: مرفق مع الحزمة نظام اختبارات ذاتي تجاوز **57 فحصاً معمارياً بنجاح 100%**.

---

### 👥 تفاصيل الوكلاء العشرة واختصاصاتهم

| الوكيل | الاسم البرمجي | الدور والمسؤولية | نوع الصلاحية |
|---|---|---|---|
| 📐 **المعمارية** | `tauri-architect` | رسم حدود المهام، تخطيط المعمارية، وتوزيع مسؤوليات الملفات | `قراءة فقط` |
| 🦀 **منطق Rust الخلفي** | `tauri-rust` | كتابة كود Rust، إدارة الحالة (State)، والتزامن الآمن لنظام Windows | `تنفيذ وكتابة` |
| 🎨 **الواجهة و IPC** | `tauri-frontend` | ربط واجهة المستخدم (Vite, React, Vue, Svelte) مع Tauri والاتصال المكتوب | `تنفيذ وكتابة` |
| 🔌 **عقود الاتصال** | `tauri-ipc` | تصميم عقود Commands و Events و Channels وهياكل الأخطاء الموحدة | `قراءة فقط` |
| 🛡️ **الأمان والصلاحيات** | `tauri-security` | تدقيق الصلاحيات والـ Scopes والـ CSP وحماية مسارات النظام الحساسة | `قراءة فقط` |
| 🪟 **تكامل Windows 11** | `tauri-windows` | إدارة دورة حياة WebView2، سجل النظام، صينية النظام (Tray)، واختصارات OS | `تنفيذ وكتابة` |
| 🧩 **الإضافات** | `tauri-plugins` | إدارة وتضمين إضافات Tauri 2 وتفعيل الصلاحيات المناسبة لها | `تنفيذ وكتابة` |
| 🧪 **الاختبارات** | `tauri-test` | كتابة اختبارات الوحدة، محاكاة الـ IPC، واختبارات التكامل على بيئة Windows | `تنفيذ وكتابة` |
| ⚡ **تحسين الأداء** | `tauri-perf` | تسريع وقت الإقلاع، تقليل استهلاك ذاكرة WebView2، وتقليص حجم الملف التنفيذي | `تنفيذ وكتابة` |
| 📦 **الحزم والتوزيع** | `tauri-release` | بناء مثبتات NSIS/MSI، توقيع التحديثات OTA، وفحص الجاهزية للإطلاق | `تنفيذ وكتابة` |

---

### 🚀 دليل التثبيت السريع

#### 🪟 لمستخدمي Windows (نقرة واحدة)
اضغط مرتين على ملف [**`Install.cmd`**](Install.cmd) في المجلد الرئيسي:
1. اختر الخيار `1` لتثبيت الحزمة تلقائياً في كل بيئات الذكاء الاصطناعي المكتشفة.
2. أو اختر `2` لفحص واستعراض البرامج المكتشفة في جهازك.
3. *أو يمكنك التثبيت عبر PowerShell:*
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\install-all.ps1
   ```

#### 🍏 لمستخدمي macOS و 🐧 Linux
شغّل السكربت الموحد عبر الطرفية:
```bash
bash Install.sh
```
*(توجد أيضاً ملفات تشغيل فردية داخل مجلد [📁 `installers/`](installers/))*

#### 🔄 التراجع واسترجاع النسخ السابقة (Rollback)
قبل أي تعديل، تُحفظ نسخة احتياطية مشفرة برقم معرف فريد. للتراجع عن أي تثبيت:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore.ps1 -BackupPath 'C:\Users\YOUR_USERNAME\.zcode\backups\tauri-pack\BACKUP_ID'
```

---

### 💬 كيفية استخدام الوكلاء أثناء البرمجة

بعد إتمام التثبيت، يمكنك استدعاء أي وكيل مباشرة داخل محادثة بيئة الذكاء الاصطناعي (مثل **Cursor** أو **Claude Code** أو **ZCode**) باستخدام اسمه:

```text
# مثال على توزيع المهام:
المستخدم: @tauri-architect راجع معمارية حفظ الملفات وحدود المهام.
المستخدم: @tauri-ipc صمم عقد الـ Command ونوع البيانات المرسلة ونموذج الخطأ.
المستخدم: @tauri-rust برمج دالة الـ Command في Rust مع معالجة التزامن.
المستخدم: @tauri-security راجع صلاحيات الـ capabilities ومسارات الملفات المسموح كتابتها.
```

---

### 📚 الوثائق والمراجع التفصيلية

- 📖 [شرح التوافق والبيئات المدعومة (`docs/MULTI-HARNESS.md`)](docs/MULTI-HARNESS.md)
- 🧪 [قائمة فحوصات واختبارات ما بعد التثبيت (`docs/SMOKE-TESTS.md`)](docs/SMOKE-TESTS.md)
- 🛡️ [معايير التحقق الأمني والمعماري (`docs/VALIDATION.md`)](docs/VALIDATION.md)
- 📜 [سجل التغييرات والتحديثات (`docs/CHANGELOG.md`)](docs/CHANGELOG.md)
- 🌐 [المستندات الرسمية لـ Tauri 2](https://v2.tauri.app/)

---

### ⚖️ الترخيص
هذا المشروع مرخص بموجب رخصة [MIT License](LICENSE).
