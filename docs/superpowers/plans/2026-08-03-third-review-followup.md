# 第三轮审查遗留可修复项 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复第三轮审查中仍能由当前代码证明的无障碍、输入反馈、资源文本和列表稳定 key 缺口，同时不改变经 API 22 验证的产品与发布边界。

**Architecture:** `Index.ets` 继续只负责编排页面状态，字符串资源承载新的可见与无障碍文本。Python 静态回归脚本验证 ArkUI 源码的关键契约，并由现有 HarmonyOS 构建进行类型检查。

**Tech Stack:** HarmonyOS Stage、ArkTS/ArkUI、JSON 字符串资源、Python `unittest`、Hvigor。

---

### Task 1: 审查遗留项回归契约

**Files:**
- Modify: `scripts/test_review_remediation.py`
- Test: `scripts/test_review_remediation.py`

- [x] **Step 1: 写入失败回归断言**

```python
def test_remaining_review_items_are_covered(self) -> None:
    self.assertIn("question_limit_reached", self.index)
    self.assertIn("question_quote", self.index)
    self.assertIn("accessibilityText($r('app.string.card_image_accessibility'", self.index)
```

- [x] **Step 2: 运行回归并确认失败**

Run: `python scripts/test_review_remediation.py`

Expected: FAIL，缺少输入上限提示、资源化引号文本和牌面描述的当前实现。

- [x] **Step 3: 为稳定 key 写入失败回归断言**

```python
self.assertRegex(self.index, r'ForEach\(SCENE_OPTIONS\.slice\(0, 3\),[\s\S]*?item\[1\]')
```

- [x] **Step 4: 再次运行并确认失败**

Run: `python scripts/test_review_remediation.py`

Expected: FAIL，静态选项列表尚未提供显式 key。

> 旧兼容 `history: string[]` 没有可持久化的唯一标识；直接以文本或索引作为 key 都不能同时解决重复项和删除后的稳定性，因此将其保留为后续数据迁移任务，而不是在本次快速修复中加入伪稳定 key。

### Task 2: 最小 ArkUI 与资源修复

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `scripts/test_review_remediation.py`
- Test: `scripts/test_review_remediation.py`

- [x] **Step 1: 实现资源化输入反馈和引号文本**

```ts
Text(this.question.length >= 300
  ? $r('app.string.question_limit_reached')
  : $r('app.string.question_length_counter', this.question.length))
Text($r('app.string.question_quote', this.question))
```

- [x] **Step 2: 为牌面与牌背添加资源化无障碍描述**

```ts
.accessibilityText($r('app.string.card_image_accessibility', this.cardById(cardId).nameZhCn))
.accessibilityText($r('app.string.card_back_accessibility'))
```

- [x] **Step 3: 为审查列出的列表提供稳定 key**

```ts
}, (item: [Resource, ReadingScene]): string => item[1])
}, (item: [string, Resource]): string => item[0])
```

- [x] **Step 4: 运行聚焦回归并确认通过**

Run: `python scripts/test_review_remediation.py`

Expected: PASS，所有审查遗留静态契约成立。

- [x] **Step 5: 运行完整门禁与构建**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1`，随后 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug`。

Expected: 标准门禁、debug HAP 和 `entry@ohosTest` HAP 均通过。
