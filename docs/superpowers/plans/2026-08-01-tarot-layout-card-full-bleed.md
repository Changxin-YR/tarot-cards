# Tarot Layout And Full-Bleed Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the non-overlay menu, bottom safe-area collision, inconsistent tarot-card proportions, loose spread layout, and visible scrollbars using API 22-compatible ArkTS/ArkUI.

**Architecture:** Keep `Index.ets` as the page compositor, but make the root Stack own overlays and safe-area spacers so transient UI never changes page height. Keep image correction in `prepare_theme_assets.py`: future atlas extraction writes full-bleed cards, while a tested normalization mode updates the checked-in generated JPEGs without requiring external atlas attachments.

**Tech Stack:** HarmonyOS Stage model, ArkTS/ArkUI API 22, PowerShell static gates, Python 3 unittest, Pillow, Hvigor.

---

## File Map

- Modify `tasks.md`: register this repair as `T-20260801-002` and track only `in_progress`/`done`.
- Create `scripts/test_ui_layout_regressions.py`: static regression checks for menu overlay ownership, safe-area spacers, catalog height, and hidden scrollbars.
- Create `scripts/test_prepare_theme_assets.py`: Pillow unit tests for full-bleed extraction and existing-resource normalization.
- Modify `scripts/prepare_theme_assets.py`: add full-bleed extraction, side-band trimming, and `--normalize-existing`.
- Modify `scripts/validate-theme-assets.ps1`: reject generator-colored side bands in addition to wrong dimensions.
- Modify `scripts/check-standard.ps1`: run the two local regression checks after the external HarmonyOS standard gate.
- Modify `entry/src/main/ets/common/DesignTokens.ets`: centralize overlay, safe-area fallback, and compact spread dimensions.
- Modify `entry/src/main/ets/pages/Index.ets`: fixed header, root overlay, internal safe-area spacers, constrained catalog, compact spread cards, and hidden scrollbars.
- Regenerate `entry/src/main/resources/base/media/moon_garden_*.jpg` and `stained_glass_*.jpg`: remove generated side bands while retaining all IDs and `400x600` dimensions.
- Modify `changes.md` and `design-qa.md`: record only completed gates and actually observed device results.

### Task 1: Register Work And Establish Failing Regression Gates

**Files:**
- Modify: `tasks.md`
- Create: `scripts/test_ui_layout_regressions.py`
- Create: `scripts/test_prepare_theme_assets.py`

- [ ] **Step 1: Register the task**

Add `T-20260801-002` under current tasks with status `in_progress`, scope matching the approved spec, and verification requiring the local gates, theme validation, debug HAP, and ohosTest HAP.

- [ ] **Step 2: Write the failing resource tests**

Create tests that import these wished-for functions from `prepare_theme_assets.py`:

```python
from scripts.prepare_theme_assets import full_bleed_crop, normalize_full_bleed

def test_full_bleed_crop_fills_400_by_600_without_background_canvas(self):
    source = Image.new("RGB", (100, 200), (220, 30, 30))
    output = full_bleed_crop(source, (0, 0, 100, 200))
    self.assertEqual((400, 600), output.size)
    self.assertEqual((220, 30, 30), output.getpixel((0, 300)))

def test_normalize_full_bleed_trims_generator_side_bands(self):
    source = Image.new("RGB", (400, 600), (7, 23, 48))
    source.paste((80, 100, 180), (70, 0, 330, 600))
    output = normalize_full_bleed(source, (7, 23, 48))
    self.assertEqual((400, 600), output.size)
    self.assertEqual((80, 100, 180), output.getpixel((0, 300)))
```

- [ ] **Step 3: Write the failing layout gate**

The script must read `Index.ets` and fail unless all of these conditions hold:

```python
assert ".height(this.menuOpen ?" not in source
assert "this.MoreMenuOverlay()" in source
assert "this.SafeAreaSpacer(this.safeTop)" in source
assert "this.SafeAreaSpacer(this.safeBottom)" in source
assert catalog_section.count(".layoutWeight(1)") >= 2
assert source.count(".scrollBar(BarState.Off)") >= scrollable_component_count
```

- [ ] **Step 4: Run both tests and verify RED**

Run:

```powershell
python -m unittest scripts.test_prepare_theme_assets -v
python scripts/test_ui_layout_regressions.py
```

Expected: resource import fails because the new functions do not exist; layout gate fails on the dynamic Header height and missing root overlay/safe-area spacers.

### Task 2: Make Theme Assets Full-Bleed

**Files:**
- Modify: `scripts/prepare_theme_assets.py`
- Modify: `scripts/validate-theme-assets.ps1`
- Modify: `entry/src/main/resources/base/media/moon_garden_*.jpg`
- Modify: `entry/src/main/resources/base/media/stained_glass_*.jpg`

- [ ] **Step 1: Implement full-bleed extraction**

Replace contain-on-canvas extraction with a pure crop resize:

```python
def full_bleed_crop(source: Image.Image, rect: tuple[int, int, int, int]) -> Image.Image:
    x, y, width, height = rect
    crop = source.crop((x, y, x + width, y + height)).convert("RGB")
    return crop.resize(CANVAS, Image.Resampling.LANCZOS)
```

Update `save_cards()` to call `full_bleed_crop()` and remove its unused background argument.

- [ ] **Step 2: Implement existing-resource normalization**

Add `normalize_full_bleed(image, background)` that scans contiguous edge columns, treats a column as background when at least 80% of sampled pixels are within a small RGB tolerance of the theme background, crops only detected left/right bands, and resizes the result to `CANVAS`. Add `--normalize-existing`; when present, normalize all 78 cards and the back for both themes in the project media directory, then exit without requiring atlas arguments.

- [ ] **Step 3: Verify GREEN for resource unit tests**

Run:

```powershell
python -m unittest scripts.test_prepare_theme_assets -v
```

Expected: both full-bleed tests pass.

- [ ] **Step 4: Normalize checked-in resources**

Run:

```powershell
python scripts/prepare_theme_assets.py --normalize-existing
```

Expected: reports 158 normalized theme resources; file names and media mapping remain unchanged.

- [ ] **Step 5: Harden theme validation**

Extend `validate-theme-assets.ps1` to inspect edge columns against `(238,234,254)` for `moon_garden` and `(7,23,48)` for `stained_glass`; fail when a contiguous generator-colored band wider than the allowed small border remains.

- [ ] **Step 6: Run the theme gate**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-theme-assets.ps1
```

Expected: two themes, 78 cards each, one back each, all `400x600`, no generated side bands.

### Task 3: Correct ArkUI Layout Ownership

**Files:**
- Modify: `entry/src/main/ets/common/DesignTokens.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Add centralized dimensions**

Add numeric tokens for `MENU_WIDTH`, `MENU_OFFSET`, `SAFE_BOTTOM_FALLBACK`, `SPREAD_CARD_HEIGHT`, and `SPREAD_CARD_PADDING`. Keep touch targets at least `48vp`.

- [ ] **Step 2: Keep Header height fixed and build the overlay**

Remove the conditional Header height and menu child. Add a root-level builder:

```typescript
@Builder
MoreMenuOverlay() {
  if (this.menuOpen) {
    Column() {
      Button($r('app.string.history_title'))
        .type(ButtonType.Normal)
        .width('100%')
        .height(DesignTokens.TOUCH_TARGET)
        .onClick((): void => this.openPage('history'))
    }
    .width(DesignTokens.MENU_WIDTH)
    .margin({ top: this.safeTop + DesignTokens.HEADER_HEIGHT, right: DesignTokens.MENU_OFFSET })
    .zIndex(20)
  }
}
```

Render it as the last child of the root `Stack`, so it paints above the fixed-height page without participating in page flow.

- [ ] **Step 3: Replace root padding with safe-area spacers**

Add a declarative builder with no local variables:

```typescript
@Builder
SafeAreaSpacer(height: number) {
  Row().width('100%').height(height)
}
```

Place the top spacer, weighted content/nav Column, and bottom spacer inside the fixed-height root Column. Re-read window avoid areas from `onPageShow()`, and apply `Math.max(reportedBottom, DesignTokens.SAFE_BOTTOM_FALLBACK)`.

- [ ] **Step 4: Constrain catalog and compact spread cards**

Add `.layoutWeight(1)` to the `CatalogPage()` root Column. Apply the compact spread tokens to `SpreadCard` and reduce the `DrawModePage` spacing while preserving the four `48vp`-accessible rows and existing strings.

- [ ] **Step 5: Hide scrollbars without disabling scrolling**

Add `.scrollBar(BarState.Off)` to every `Scroll`, `Grid`, and other scrollable container in `Index.ets`, including the horizontal catalog filter.

- [ ] **Step 6: Verify GREEN for the layout gate**

Run:

```powershell
python scripts/test_ui_layout_regressions.py
```

Expected: all menu, safe-area, catalog, and scrollbar assertions pass.

### Task 4: Integrate Gates And Compile ArkTS

**Files:**
- Modify: `scripts/check-standard.ps1`

- [ ] **Step 1: Add local regressions to the standard gate**

After the external HarmonyOS checker succeeds, invoke:

```powershell
python (Join-Path $PSScriptRoot 'test_ui_layout_regressions.py')
if ($LASTEXITCODE -ne 0) { throw 'UI layout regression check failed.' }

python -m unittest scripts.test_prepare_theme_assets -v
if ($LASTEXITCODE -ne 0) { throw 'Theme preparation tests failed.' }
```

- [ ] **Step 2: Run static and resource gates**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-theme-assets.ps1
python scripts\validate_tarot_catalog.py
```

Expected: all commands exit 0.

- [ ] **Step 3: Build debug HAP**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
```

Expected: Hvigor exits 0 and reports a debug HAP below `entry/build/default/outputs/`.

- [ ] **Step 4: Build ohosTest HAP**

Run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry@ohosTest -p product=default -p buildMode=debug assembleHap --no-daemon
```

Expected: Hvigor exits 0 with no ArkTS syntax or type errors.

### Task 5: Device Observation And Documentation

**Files:**
- Modify: `tasks.md`
- Modify: `changes.md`
- Modify: `design-qa.md`

- [ ] **Step 1: Detect an available HarmonyOS device**

Use the existing hdc toolchain to list targets. If none is available, record device observation as `blocked` and do not claim visual passage.

- [ ] **Step 2: Observe the five requested behaviors when a device is available**

Install the new debug HAP and observe: menu overlays near the greeting without movement; catalog stops above app navigation and system gesture area; representative major/minor cards from both themes are full-bleed and proportionate; all four spread cards fit cohesively; scrollbars are invisible while content still scrolls.

- [ ] **Step 3: Update documentation from evidence**

Add the completed implementation and exact gate results to `changes.md`. Add only observed device results to `design-qa.md`; otherwise add a `blocked` line. Mark `T-20260801-002` `done` only when implementation, builds, and documentation are complete.

- [ ] **Step 4: Run final verification after documentation edits**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-theme-assets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
```

Expected: all commands exit 0; report any unavailable device check as a limitation rather than a pass.
