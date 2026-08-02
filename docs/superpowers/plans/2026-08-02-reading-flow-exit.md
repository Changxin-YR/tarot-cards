# Reading Flow Exit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one consistent text-style exit action to every divination-flow page that clears transient reading state and returns to the home root.

**Architecture:** Keep navigation and UI orchestration in `Index.ets`, matching the existing project structure. A single `exitReadingFlow()` method owns state cleanup and root navigation, while one `ReadingExitButton()` builder owns the visual treatment. A Python static regression gate verifies all six flow pages use the shared builder and that the cleanup contract remains present.

**Tech Stack:** HarmonyOS Stage model, ArkTS/ArkUI, Python static regression tests, Hypium device tests.

---

### Task 1: Add The Reading-Flow Exit Contract

**Files:**
- Create: `scripts/test_reading_flow_exit.py`
- Modify: `scripts/check-standard.ps1`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/resources/base/element/string.json`

- [x] **Step 1: Write the failing static regression test**

Create a test that extracts `DrawModePage`, `QuestionPage`, `ShufflePage`, `SelectCardsPage`, `RevealPage`, and `ResultPage`; require each section to call `this.ReadingExitButton()`. Require the shared builder to use `$r('app.string.exit_reading')`, a 48vp click target, transparent background, and `exitReadingFlow()`. Require the exit method to clear the question, main/clarification/pending/selected card collections, result texts, saved-record state, reset `DrawFlowService`, and call `selectRoot('home')`.

- [x] **Step 2: Run the test and verify RED**

Run: `python scripts/test_reading_flow_exit.py`

Expected: FAIL because `ReadingExitButton` and `exitReadingFlow` do not exist.

- [x] **Step 3: Implement the minimal ArkUI behavior**

Add the string resource `{ "name": "exit_reading", "value": "退出" }`. Add `exitReadingFlow()` to reset transient reading fields and select the home root. Add one 48vp transparent text button builder that invokes the method. Render it after the primary page action in all six flow page builders, and after “再抽一次” on the result page.

- [x] **Step 4: Register and run the regression gate**

Invoke `test_reading_flow_exit.py` from `scripts/check-standard.ps1`, fail on a non-zero exit code, then run:

```powershell
python scripts/test_reading_flow_exit.py
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-standard.ps1
python scripts/validate_tarot_catalog.py
git diff --check
```

Expected: all checks pass; only the existing `2in1` declaration warning may remain.

- [x] **Step 5: Build and run device tests**

Build debug and ohosTest HAPs, install both on `127.0.0.1:5555`, and run `OpenHarmonyTestRunner`.

Expected: both builds succeed and all 72 Hypium tests pass.

- [x] **Step 6: Update records and commit**

Mark `T-20260802-005` done, summarize the behavior and observed verification in `changes.md` and `design-qa.md`, then commit with:

```powershell
git add entry/src/main/ets/pages/Index.ets entry/src/main/resources/base/element/string.json scripts/test_reading_flow_exit.py scripts/check-standard.ps1 tasks.md changes.md design-qa.md docs/superpowers/plans/2026-08-02-reading-flow-exit.md
git commit -m "feat: add exit action to reading flow"
```
