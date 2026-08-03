# Home Greetings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the home greeting area with natural time-based greetings and remove the unrelated local-storage notice.

**Architecture:** Keep the existing `GreetingService` boundary logic and update only its returned copy. Remove the obsolete home-page resource reference and protect the behavior with static and Hypium regressions.

**Tech Stack:** HarmonyOS Stage model, ArkTS, ArkUI, Hypium, Python static checks, Hvigor

---

### Task 1: Add greeting regressions

**Files:**
- Create: `scripts/test_home_greeting.py`
- Modify: `entry/src/ohosTest/ets/test/GreetingService.test.ets`

- [x] **Step 1: Write failing tests for all six subtitles and removal of the privacy notice**

Add exact expected greeting pairs to the Hypium boundary test. Add a Python regression that reads `GreetingService.ets`, `Index.ets`, and `string.json`, checks all six pairs, and rejects any remaining `privacy_local_only` reference.

- [x] **Step 2: Run the static regression and verify RED**

Run: `python scripts/test_home_greeting.py`

Expected: FAIL because the service still contains the old subtitles and the home page still references `privacy_local_only`.

### Task 2: Implement the greeting copy

**Files:**
- Modify: `entry/src/main/ets/services/GreetingService.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `scripts/check-standard.ps1`

- [x] **Step 1: Replace the six subtitles with the approved natural greetings**

Keep the existing hour boundaries and titles unchanged. Replace only the subtitle values defined in the design specification.

- [x] **Step 2: Remove the local-storage notice from the home greeting area**

Delete the `Text($r('app.string.privacy_local_only'))` node and remove the now-unused `privacy_local_only` string entry.

- [x] **Step 3: Add the greeting regression to the standard gate**

Invoke `scripts/test_home_greeting.py` from `scripts/check-standard.ps1` and fail the gate when it exits nonzero.

- [x] **Step 4: Run the focused regression and verify GREEN**

Run: `python scripts/test_home_greeting.py`

Expected: PASS with one successful test.

### Task 3: Verify and document

**Files:**
- Modify: `tasks.md`
- Modify: `changes.md`

- [x] **Step 1: Run all verification commands**

Run `powershell -ExecutionPolicy Bypass -File scripts/check-standard.ps1`, `powershell -ExecutionPolicy Bypass -File scripts/build-harmony.ps1 -BuildMode debug`, and the project Hvigor command for `entry@ohosTest`.

- [x] **Step 2: Record observed results**

Mark the task `done` only after all commands pass. Record build and test evidence in `changes.md`; do not add device observations without running them.

- [x] **Step 3: Commit and push**

Stage only files belonging to this task, commit with `feat: refresh time-based home greetings`, and push `HEAD` to `origin/master`.
