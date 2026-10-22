# تثبيت الحزمة في برامج الوكلاء

شغّل `List-Programs.cmd` لعرض الاكتشاف، ثم `Install-All.cmd` للتثبيت في البرامج المدعومة المكتشفة. لا يشغّل هذان الملفان أي نموذج أو طلب API. كل برنامج يحصل على نسخة احتياطية مستقلة. التثبيت في البرامج المختلفة ليس معاملة واحدة؛ إذا فشل هدف، يُذكر الخطأ وتبقى النتائج الناجحة مع نسخها الاحتياطية.

```powershell
.\install-all.ps1 -List
.\install-all.ps1 -WhatIf
.\install-all.ps1
# اختيار صريح، حتى لو لم يكتشف المثبّت برنامجًا:
.\install-all.ps1 -Targets zcode,codex,claude,cursor,gemini,copilot,hermes
# اختر صيغة OpenCode الملائمة لنسختك:
.\install-all.ps1 -Targets opencode-v1
.\install-all.ps1 -Targets opencode-v2
# الاكتشاف التلقائي يفترض صيغة v1، ويمكن تغييرها:
.\install-all.ps1 -OpenCodeVersion v2
```

المجلد وحده، خصوصًا مجلد skills، لا يكفي لإثبات تثبيت البرنامج. الاكتشاف يعتمد على أمر البرنامج أو ملفات إعداد/وكلاء معروفة أو تثبيت سطح مكتب/إضافة معروفة. هذا فحص مؤشرات وجود، وليس تأكيد إصدار البرنامج أو دعم حسابك. لا يغيّر المثبّت إعدادات ميزات معطلة أو صلاحيات عامة؛ تحتاج تفعيل دعم الوكلاء من البرنامج عند الضرورة.

| البرنامج | مسار المستخدم الافتراضي | الصيغة والاستخدام |
|---|---|---|
| ZCode | `~/.zcode/agents/*.md` | أدوات صريحة وmaxTurns؛ فعّل الوكلاء من Settings > Subagents وابدأ محادثة جديدة. |
| Codex الحالي | `~/.codex/agents/*.toml` | ملفات مستقلة مع name/description/developer_instructions؛ اطلب التفويض إلى الدور بالاسم. الإصدارات القديمة قد تتطلب التحديث. |
| Claude Code | `~/.claude/agents/*.md` | أدوات صريحة وmaxTurns؛ اطلب استخدام الدور وابدأ محادثة جديدة إذا لم يظهر. |
| Cursor | `~/.cursor/agents/*.md` | readonly للأدوار الثلاثة؛ اقرأ `~/.cursor/tauri-pack-guide.md` في المحادثة الرئيسية لتفعيل قواعد التنسيق. |
| OpenCode v1 | `~/.config/opencode/agents/*.md` | permission بصيغة v1، mode: subagent. |
| OpenCode v2 | نفس المسار | permissions بصيغة v2، mode: subagent؛ لا تثبت الصيغتين في المسار نفسه. |
| Gemini CLI | `~/.gemini/agents/*.md` | kind: local وأدوات مصفوفة؛ استخدم `/agents reload` ثم `/agents list`. وجود Antigravity لا يعني وجود Gemini CLI. |
| VS Code / Copilot الحديث | `~/.copilot/agents/*.agent.md` | user-level agents؛ تحقق من Agent Customizations ومن الأدوات المتاحة. اقرأ دليل التنسيق يدويًا في المحادثة الرئيسية. |
| Hermes | `~/.hermes/tauri-pack/roles/*.md` | مكتبة تعليمات لـdelegate_task، وليست تسجيلًا لوكلاء مسماة. اقرأ `~/.hermes/tauri-pack-guide.md` واطلب تمرير نص الدور كاملًا عند التفويض. |

يدعم المثبّت CODEX_HOME وCLAUDE_CONFIG_DIR وXDG_CONFIG_HOME وHERMES_HOME عندما تكون محددة. يمكن استخدام `install.ps1 -Harness <name> -DestinationRoot <path>` لمسار مخصص. لا يقرأ مفاتيح API أو ملفات تسجيل الدخول.

تعريفات الأدوار الأخرى تُبنى من النسخة الأساسية عبر `build-profiles.ps1`. التعليمات المشتركة مضمنة في كل تعريف لتقليل الاعتماد على اختلاف حقن ملفات التعليمات بين البرامج. الـmodel/effort يرثان إعدادات المحادثة؛ لا نفرض نموذجًا جديدًا.

صلاحيات القراءة فقط تختلف بين البرامج. ZCode/Claude/Gemini يحددون قائمة أدوات؛ Cursor يستخدم readonly؛ Codex يحدد sandbox_mode وقد تتقدم عليه خيارات صلاحيات المحادثة الحية؛ Copilot يعتمد على الأدوات التي يتيحها البرنامج. Hermes يرث أدوات الوكيل الرئيسي، لذا منع الكتابة في المكتبة تعليمة وليس قيدًا تقنيًا مستقلًا. تحقق من إعدادات البرنامج إذا كنت تحتاج منعًا صارمًا.

Antigravity أو أي برنامج غير موجود في الجدول لا يُثبّت فيه شيء تلقائيًا. أضف محوّلًا بعد التحقق من صيغة البرنامج؛ لا تنسخ تعريفات ZCode إليه عشوائيًا. تثبيت الملفات لا يثبت أنها حُمّلت أو أن جميع الأدوات متاحة؛ نفّذ SMOKE-TESTS.md في كل برنامج تستخدمه.

## مصادر الصيغ

- [Codex custom agents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Claude Code](https://code.claude.com/docs/en/sub-agents)
- [Cursor](https://cursor.com/docs/subagents)
- [OpenCode v1](https://dev.opencode.ai/docs/agents/)، [v2](https://dev.opencode.ai/v2/docs/agents/)
- [Gemini CLI](https://geminicli.com/docs/core/subagents/)
- [VS Code custom agents](https://code.visualstudio.com/docs/agent-customization/custom-agents)
- [Hermes delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation/)
