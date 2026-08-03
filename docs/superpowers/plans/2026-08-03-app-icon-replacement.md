# HarmonyOS App Icon Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the packaged HarmonyOS application icon with a compliant 1024×1024 PNG derived from the user-provided artwork.

**Architecture:** Preserve the existing `$media:app_icon` resource contract and synchronize the AppScope and entry bitmap assets. A deterministic local transform crops 30px from each source edge, flood-fills only edge-connected near-white pixels with the project deep purple, and downsamples with Lanczos. A static Python gate validates both identical final bitmaps and all configuration references.

**Tech Stack:** HarmonyOS Stage resources, PNG, Pillow, Python regression gate, Hvigor.

---

### Task 1: Add The Icon Compliance Gate

**Files:**
- Create: `scripts/test_app_icon.py`
- Modify: `scripts/check-standard.ps1`

- [x] **Step 1: Write the failing test**

The test opens both `AppScope/resources/base/media/app_icon.png` and `entry/src/main/resources/base/media/app_icon.png`, requires identical bytes, PNG format, 1024×1024 dimensions, RGB/RGBA mode, no transparent pixels, non-white corners, and `$media:app_icon` references in both configs.

- [x] **Step 2: Verify RED**

Run `python scripts/test_app_icon.py` and expect failure because the current icon is 180×180.

- [x] **Step 3: Generate the final icon**

Use Pillow to crop source box `(30, 30, 1224, 1224)`. Flood-fill from the crop border where `min(R,G,B) >= 220` and `max(R,G,B)-min(R,G,B) <= 25`, replacing only connected background pixels with `(15, 9, 39)`. Resize to 1024×1024 with Lanczos and save as optimized RGB PNG to `entry/src/main/resources/base/media/app_icon.png`.

- [x] **Step 4: Register and verify GREEN**

Add `scripts/test_app_icon.py` to `scripts/check-standard.ps1`, then run:

```powershell
python scripts/test_app_icon.py
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-standard.ps1
git diff --check
```

Expected: all icon assertions and project gates pass.

### Task 2: Build, Observe, And Deliver

**Files:**
- Modify: `tasks.md`
- Modify: `changes.md`
- Modify: `design-qa.md`

- [x] **Step 1: Build both HAP variants**

Run the project debug build and `entry@ohosTest` build. Expected: ArkTS type check and both HAP packages succeed.

- [x] **Step 2: Install and observe on API 22**

Install the debug HAP on `127.0.0.1:5555`, launch the application, and inspect the launcher/start-window icon. Record only observed results.

- [x] **Step 3: Update project records**

Mark `T-20260803-001` done and record the exact test, build, and device evidence.

- [x] **Step 4: Commit and push**

Commit with `feat: replace HarmonyOS application icon` and push `HEAD:master` to the configured Gitee remote.
