# 损坏本地数据恢复与队列日志 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让本地存储已经打开、但记录解码失败的用户能够在确认后清空本机数据并重新进入首次合规流程，同时保证记录队列错误不会被静默丢弃。

**Architecture:** `Index.ets` 保留页面状态和原生确认对话框，`ComplianceGate` 仅以回调显示恢复入口，持久化仍经 `AppDataService → ReadingRecordService → AppDataRepository`。不把数据解码错误改为静默空数据，避免损坏内容覆盖或伪装成正常记录。

**Tech Stack:** HarmonyOS Stage、ArkTS/ArkUI、Preferences、Python `unittest` 静态回归、Hvigor。

---

### Task 1: 恢复入口的失败回归

**Files:**
- Modify: `scripts/test_review_remediation.py`
- Test: `scripts/test_review_remediation.py`

- [x] **Step 1: 写入损坏数据恢复的失败断言**

```python
def test_corrupted_storage_has_a_confirmed_recovery_path(self) -> None:
    self.assertIn('onRecover: () => void', self.compliance_gate)
    self.assertIn("$r('app.string.recover_local_data_action')", self.compliance_gate)
    self.assertIn('private recoverFromInitializationFailure()', self.index)
    self.assertIn('await this.appDataService.clearAll()', self.index)
```

- [x] **Step 2: 写入队列日志的失败断言**

```python
self.assertIn("AppLogger.error('ReadingRecordService', 'queuedOperation', error)", self.reading_records)
```

- [x] **Step 3: 运行回归并确认失败**

Run: `python scripts/test_review_remediation.py`

Expected: FAIL，当前合规页没有恢复回调，记录队列 catch 也没有日志。

### Task 2: 最小恢复实现与日志

**Files:**
- Modify: `entry/src/main/ets/components/ComplianceGate.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/services/ReadingRecordService.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `scripts/test_review_remediation.py`
- Test: `scripts/test_review_remediation.py`

- [x] **Step 1: 给合规页增加仅在存储错误时显示的恢复入口**

```ts
if (this.storageError) {
  Button($r('app.string.recover_local_data_action'))
    .height(48)
    .onClick(this.onRecover)
}
```

- [x] **Step 2: 在页面层二次确认并清空损坏数据**

```ts
private async recoverFromInitializationFailure(): Promise<void> {
  await this.appDataService.clearAll();
  this.appDataReady = true;
  this.complianceRequired = true;
  this.showCompliance = true;
  this.storageError = false;
}
```

- [x] **Step 3: 记录队列失败但保持队列可继续时写入脱敏日志**

```ts
(error: Error): void => {
  AppLogger.error('ReadingRecordService', 'queuedOperation', error);
}
```

- [x] **Step 4: 运行聚焦回归并确认通过**

Run: `python scripts/test_review_remediation.py`

Expected: PASS，恢复回调、确认、状态复位和队列日志契约均存在。

- [x] **Step 5: 运行完整门禁与两类 HAP 构建**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1`，随后分别构建 debug 与 `entry@ohosTest` HAP。

Expected: 标准门禁、ArkTS 类型检查和两类 HAP 均通过。
