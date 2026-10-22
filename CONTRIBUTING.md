# Contributing

Thank you for helping improve Tauri 2 Subagents Pack. Useful contributions include reproducible bug reports, real-world experience reports, documentation fixes, role improvements, and harness adapters.

## Report a problem

Use the issue templates and include:

- Pack version or commit.
- Operating system and harness name/version.
- Installation command or reproduction steps.
- Expected and actual behavior.
- Relevant sanitized logs.

Separate installation success, agent discovery, and actual task execution. Do not infer runtime compatibility from files merely existing on disk. Never include API keys, tokens, passwords, private source code, or customer data.

## Share an experience

Describe the task, roles used, harness version, checks performed, and limitations. Distinguish your own observations from assumptions. Do not claim speed or quality gains without explaining how they were measured. Obtain permission before sharing screenshots or results from private projects.

## Propose a change

1. Open an issue for substantial behavior or format changes.
2. Keep each pull request focused and explain its purpose.
3. State which files changed and which checks ran.
4. List checks you could not run; do not describe them as passing.
5. Keep role boundaries, shared instructions, and generated profiles consistent.

For a new harness adapter, document its format, default path, activation requirements, permission behavior, and version tested. Include a reproducible runtime smoke test. A role-prompt library must not be described as native named-agent registration.

## Verification

From the repository root on Windows, package validation can be invoked with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate.ps1
```

Consult `scripts/test-package.ps1` and `docs/SMOKE-TESTS.md` for further verification. Read scripts before running them. Package checks are not substitutes for harness runtime checks or application tests.

## بالعربية

المساهمة لا تتطلب كتابة كود: توثيق مشكلة، تجربة الحزمة داخل بيئة محددة، وتحسين التعليمات كلها مساهمات مفيدة. اذكر إصدار الحزمة والبرنامج ونظام التشغيل وخطوات التجربة والنتيجة. افصل بين نجاح التثبيت وظهور الوكلاء ونجاح المهمة الفعلية.

لا تنشر مفاتيح API أو بيانات العملاء أو ملفات خاصة، ولا تصف اختباراً بأنه ناجح إن لم تشغّله. عند تعديل الأدوار راعِ اتساق التعليمات المشتركة وملفات التوافق المولّدة.
