# Stained Glass Deck And Identity Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import the complete second local tarot deck as the Stained Glass theme while restoring the original app name and icon.

**Architecture:** Keep stable card IDs and ArkTS resource references unchanged. Extend the deterministic Pillow importer so it maps the 16 supplied sheets to all 78 Stained Glass faces and one card back, writes only optimized 600×1000 JPEGs after validation, and checks a 16 MiB per-theme resource budget. Restore identity assets directly from `HEAD` without touching current feature work.

**Tech Stack:** Python, Pillow, HarmonyOS Stage resources, ArkTS `$r` media references, PowerShell, Hvigor.

---

### Task 1: Define The Complete Second-Deck Contract

**Files:**
- Modify: `scripts/test_import_tlp_decks.py`
- Modify: `tasks.md`

- [x] **Step 1: Write the failing test**

Import the second-deck source mapping and assert it contains every `expected_card_ids()` value exactly once plus one `card_back` placement. Assert `MAX_THEME_BYTES` is below 16 MiB and that the project deck validator applies it.

- [x] **Step 2: Verify RED**

Run:

```powershell
python scripts/test_import_tlp_decks.py
```

Expected: FAIL because the complete Stained Glass mapping and its byte budget do not exist.

### Task 2: Add Atomic Second-Deck Import

**Files:**
- Modify: `scripts/import_tlp_decks.py`
- Modify: `scripts/test_import_tlp_decks.py`

- [x] **Step 1: Implement the mapping**

Declare all 16 source sheets in their visual left-to-right order. Route the 78 labels to standard card IDs and route the embedded card-back tile to `stained_glass_card_back.jpg`.

- [x] **Step 2: Implement bounded output validation**

Validate a single theme before replacing its files: every card is readable and 600×1000, no perceptual duplicate exists, the card back is valid, and all 79 files total at most 16 MiB. Keep generated files in a temporary staging directory until the complete deck validates.

- [x] **Step 3: Verify GREEN**

Run:

```powershell
python scripts/test_import_tlp_decks.py
```

Expected: PASS for mapping, crop, atomic normalization and project resource validation after import.

### Task 3: Generate Resources And Restore Identity

**Files:**
- Modify: `entry/src/main/resources/base/media/stained_glass_*.jpg`
- Modify: `AppScope/resources/base/element/string.json`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `AppScope/resources/base/media/app_icon.png`
- Modify: `entry/src/main/resources/base/media/app_icon.png`

- [x] **Step 1: Generate the Stained Glass deck**

Run the importer with `C:\Users\27363\Desktop\tlp\` as its main source and the user-provided clipboard PNG as the supplemental source. It must emit only the 79 optimized runtime JPEGs.

- [x] **Step 2: Restore the identity resources**

Restore the two app-name values and two binary icon resources from the branch baseline, without changing the app package, version, permissions or icon resource keys.

- [x] **Step 3: Verify output**

Run:

```powershell
python scripts/test_import_tlp_decks.py
python scripts/test_import_moon_garden_deck.py
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-standard.ps1
git diff --check
```

Expected: all tests and static gates pass, with no whitespace errors.

### Task 4: Build And Record Evidence

**Files:**
- Modify: `tasks.md`
- Modify: `changes.md`

- [x] **Step 1: Build debug HAP**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-harmony.ps1 -BuildMode debug
```

Expected: ArkTS compile, resource processing, packaging and signing succeed.

- [x] **Step 2: Build ohosTest HAP**

Run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --mode module -p product=default -p buildMode=debug -p module=entry@ohosTest
```

Expected: the test HAP compiles and packages successfully.

- [x] **Step 3: Record actual results**

Mark the task done only after all commands above pass. Record resource and build evidence in `changes.md`; do not update `design-qa.md` without a new observed device result.
