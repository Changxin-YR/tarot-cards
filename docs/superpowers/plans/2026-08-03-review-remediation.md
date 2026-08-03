# Review Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复已核实的代码、体验与应用内合规问题，同时保留正确的 API 22、离线边界、返回导航和系统启动窗口。

**Architecture:** `Index` 继续编排应用流程；纯布局决策进入 `ResponsiveLayout`，协议判断进入 `ComplianceService`，Preferences 仍由 repository/service 层访问，日志统一经 `AppLogger` 脱敏。新增合规 UI 与公共导航组件降低 `Index` 的继续增长，不重写抽牌领域逻辑。

**Tech Stack:** HarmonyOS Stage、ArkTS/ArkUI、Preferences、hilog、Hypium、Python 静态回归脚本、Hvigor。

---

### Task 1: 建立审查整改静态红灯门禁

**Files:**
- Create: `scripts/test_review_remediation.py`
- Modify: `scripts/check-standard.ps1`

- [ ] **Step 1: 写失败测试**

测试读取 `DesignTokens.ets`、`Index.ets`、`EntryAbility.ets`、`string.json`、`module.json5`，断言：不存在旧 `GOLD` 令牌；洗牌和选择计数使用 `$r`；心情 `ForEach` 有 key；不存在空 `catch`；存在 `ResponsiveLayout`、`ComplianceGate`、页面 transition 与 `launchType: "singleton"`；API 22 未变化。

- [ ] **Step 2: 验证红灯**

Run: `python scripts/test_review_remediation.py`
Expected: FAIL，首个失败点为旧 `GOLD` 令牌或缺少新模块。

- [ ] **Step 3: 接入标准门禁**

在 `check-standard.ps1` 中执行脚本并在非零退出码时抛出 `Review remediation regression check failed`。

### Task 2: 协议与响应式纯逻辑测试先行

**Files:**
- Create: `entry/src/ohosTest/ets/test/ComplianceService.test.ets`
- Create: `entry/src/ohosTest/ets/test/ResponsiveLayout.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`
- Create: `entry/src/main/ets/services/ComplianceService.ets`
- Create: `entry/src/main/ets/common/ResponsiveLayout.ets`

- [ ] **Step 1: 写协议失败测试**

```ts
expect(ComplianceService.requiresAcceptance('')).assertTrue();
expect(ComplianceService.requiresAcceptance('2026-08-03-v1')).assertFalse();
expect(ComplianceService.requiresAcceptance('older')).assertTrue();
```

- [ ] **Step 2: 写响应式失败测试**

```ts
expect(ResponsiveLayout.catalogColumns(359)).assertEqual(2);
expect(ResponsiveLayout.catalogColumns(599)).assertEqual(3);
expect(ResponsiveLayout.catalogColumns(600)).assertEqual(4);
expect(ResponsiveLayout.selectionColumns(600)).assertEqual(5);
```

- [ ] **Step 3: 验证红灯**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode ohosTest`
Expected: FAIL，模块尚不存在。

- [ ] **Step 4: 最小实现**

`ComplianceService` 暴露固定 `CURRENT_VERSION = '2026-08-03-v1'` 和 `requiresAcceptance(acceptedVersion)`；`ResponsiveLayout` 暴露 `catalogColumns(width)`、`selectionColumns(width)` 及生成 ArkUI `columnsTemplate` 的纯函数。

- [ ] **Step 5: 验证绿灯编译**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode ohosTest`
Expected: `BUILD SUCCESSFUL`。

### Task 3: 持久化协议版本

**Files:**
- Modify: `entry/src/main/ets/repositories/AppDataRepository.ets`
- Modify: `entry/src/main/ets/repositories/LocalAppStore.ets`
- Modify: `entry/src/main/ets/services/AppDataService.ets`
- Modify: `entry/src/ohosTest/ets/test/AppDataService.test.ets`

- [ ] **Step 1: 扩展内存仓库失败测试**

为 `StoredAppData` 增加 `acceptedTermsVersion`，为 repository 增加 `saveAcceptedTermsVersion(value)`；测试 `acceptCurrentTerms()` 仅在 repository 保存成功后返回当前版本，保存失败时 reject。

- [ ] **Step 2: 验证红灯编译**

Run: ohosTest 构建；Expected: FAIL，接口方法缺失。

- [ ] **Step 3: 最小持久化实现**

Preferences key 使用 `acceptedTermsVersion`；`clearAll()` 同时清除该值，因此清空全部数据后会重新显示确认页。`AppDataService.acceptCurrentTerms()` 通过现有队列串行保存。

- [ ] **Step 4: 验证绿灯编译**

Run: ohosTest 构建；Expected: `BUILD SUCCESSFUL`。

### Task 4: 日志、异常与配置清理

**Files:**
- Create: `entry/src/main/ets/common/AppLogger.ets`
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/repositories/LocalAppStore.ets`
- Modify: `entry/src/main/ets/services/AppDataService.ets`
- Modify: `entry/src/main/ets/services/DrawService.ets`
- Modify: `entry/src/main/module.json5`

- [ ] **Step 1: 实现固定接口日志**

```ts
AppLogger.error('EntryAbility', 'loadContent', error);
```

日志正文仅包含固定 module/action 和 `error instanceof Error ? error.name : 'UnknownError'`，不包含 `message` 或业务值。

- [ ] **Step 2: 替换空捕获**

为加载、窗口配置、初始化、存储操作、退出和队列拒绝增加日志；保留现有 UI 回退和 reject 行为。

- [ ] **Step 3: 清理与配置**

删除 `DrawService.drawThree` 未使用变量；Ability 增加 `"launchType": "singleton"`；不修改 SDK 和 deviceTypes。

- [ ] **Step 4: 运行静态门禁**

Run: `python scripts/test_review_remediation.py`
Expected: 仍可能因后续令牌/UI 项失败，但不得再因空 catch、未使用变量或 launchType 失败。

### Task 5: 颜色语义、字符串资源与安全覆盖

**Files:**
- Modify: `entry/src/main/ets/common/DesignTokens.ets`
- Modify: `entry/src/main/resources/base/element/color.json`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/services/SafetyService.ets`
- Modify: `entry/src/ohosTest/ets/test/SafetyService.test.ets`

- [ ] **Step 1: 写安全红灯测试**

覆盖“想伤害自己”“要不要停药”“官司一定会赢吗”“现在该买哪只股票”，并断言普通情绪整理不命中。

- [ ] **Step 2: 验证红灯编译**

Run: ohosTest 构建；Expected: 新增断言至少一项失败（设备执行时验证）；静态编译通过。

- [ ] **Step 3: 迁移颜色令牌**

紫色主操作使用 `PRIMARY`/`PRIMARY_SOFT`/`TEXT_ON_PRIMARY`；暖金使用 `ACCENT_GOLD`；替换全部旧 `GOLD` 调用并更新资源颜色。

- [ ] **Step 4: 迁移 UI 文本**

使用 `$r('app.string.shuffle_progress', count)`、`$r('app.string.selected_count', selected, total)`、`$r('app.string.clarification_position', index)`、`$r('app.string.candidate_card_position', index)`；心情 `ForEach` key 使用内部值。

- [ ] **Step 5: 扩展安全词与提示**

增加自伤、伤害、停药、官司输赢和具体证券决策表达，提示继续保持专业求助和非确定性定位。

### Task 6: 合规 UI、政策文案与页面入口

**Files:**
- Create: `entry/src/main/ets/components/ComplianceGate.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Create: `docs/release/privacy-policy.md`
- Create: `docs/release/user-agreement.md`
- Create: `docs/release/appgallery-checklist.md`

- [ ] **Step 1: 增加资源与组件**

组件状态只控制当前展示“确认/隐私/协议”；输入为 `accept: () => void`、`decline: () => void`。按钮点击区域不小于 48vp，正文可滚动，卡片圆角不超过 8vp。

- [ ] **Step 2: 接入初始化与失败状态**

`Index` 从 `StoredAppData.acceptedTermsVersion` 计算 gate 状态；同意成功后关闭，失败时保留并显示 `storageError`；拒绝调用脱敏日志保护的退出方法。

- [ ] **Step 3: 设置页永久入口**

设置页按钮可重新打开隐私政策和用户协议，不改变已接受版本。

- [ ] **Step 4: 发布文档**

政策明确离线、本地保存、清除后果、无第三方共享和免责声明；清单将 HTTPS URL、签名、年龄分级和提审说明标为人工待办。

### Task 7: 响应式布局、过渡与低耦合拆分

**Files:**
- Create: `entry/src/main/ets/components/AppHeader.ets`
- Create: `entry/src/main/ets/components/BottomNavigation.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: 提取公共组件**

Header 接收标题、返回、更多菜单和记录入口回调；BottomNavigation 接收当前 root 与选择回调。保持 48vp 点击区、现有资源图标和安全区高度。

- [ ] **Step 2: 窗口宽度生命周期**

在窗口配置时读取 `windowRect.width`，注册 `windowSizeChange` 更新 `viewportWidth`，组件消失时注销；失败时使用 phone 回退宽度并记录日志。

- [ ] **Step 3: 动态网格**

牌库与候选牌 `.columnsTemplate(ResponsiveLayout.*Template(this.viewportWidth))`，保留稳定宽高比与间距。

- [ ] **Step 4: 统一过渡**

内部导航赋值集中到现有 `openPage/selectRoot/goBack`，在页面容器添加短时 `TransitionEffect.OPACITY` 与轻微 translate 动画；不改变导航栈。

### Task 8: 全量验证与项目记录

**Files:**
- Modify: `changes.md`
- Modify: `tasks.md`
- Do not modify: `design-qa.md`（除非本轮实际观察设备）

- [ ] **Step 1: 聚焦静态测试**

Run: `python scripts/test_review_remediation.py`
Expected: PASS。

- [ ] **Step 2: 标准门禁**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1`
Expected: exit 0；允许既有 2in1 warning，不允许新错误。

- [ ] **Step 3: debug 构建**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug`
Expected: `BUILD SUCCESSFUL`。

- [ ] **Step 4: ohosTest 构建**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode ohosTest`
Expected: `BUILD SUCCESSFUL`。

- [ ] **Step 5: 记录事实**

`changes.md` 只写实际通过的命令；`tasks.md` 在全部实现与验证完成后改为 `done`。未运行设备观察则不修改 `design-qa.md`。
