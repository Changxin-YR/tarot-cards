# Tarot Inspiration Second-Round V2 Implementation Plan

> Execute this plan inline with `executing-plans`. Business behavior follows red-green-refactor. This plan supersedes `2026-07-30-reference-draw-flow-upgrade.md`.

**Goal:** Rebuild the existing offline HarmonyOS tarot app around the approved light-purple reference UI, a five-step reading flow, four spreads, structured local records, offline clarification cards, and two freely switchable 78-card visual themes.

**Architecture:** Keep the Stage-model `entry` module. Move flow state and business rules out of `Index.ets` into typed models/services, keep Preferences access in repositories, and let ArkUI render only state and events. Stable tarot card IDs remain independent from theme media IDs. A generated theme manifest is the only card-to-media mapping used by the app.

**Tech stack:** HarmonyOS NEXT API 24, ArkTS, ArkUI, Preferences, Hypium, Hvigor, PowerShell asset validation.

## Delivery Rules

- Core use is fully offline; remove XiaoYi from the active product flow.
- User-visible text belongs in `base/element/string.json`; visual values belong in resources or `DesignTokens.ets`.
- Phone and tablet share behavior; content width is capped at 720vp and touch targets are at least 48vp.
- Do not expose a theme unless all 78 stable IDs and its card back resolve to readable media.
- Do not write device claims to `design-qa.md` without observed device or emulator evidence.
- Commit each completed batch after its tests, static gate, and relevant build pass.

## Task 1: Baseline, task registration, and asset inventory

**Files:** `tasks.md`, `scripts/validate-theme-assets.ps1`, `docs/assets/tarot-assets.md`

- [ ] Register `T-20260731-002` as `in_progress`.
- [ ] Run the existing static gate, ohosTest HAP build, and debug HAP build; record only actual results.
- [ ] Inventory the six unique atlas sources and two duplicate pairs from attachments 18-25.
- [ ] Write a failing validator for 78 stable IDs, unique theme mappings, readable files, and one card back per theme.
- [ ] Keep `.tmp-device/` and source atlas working files out of commits.

## Task 2: Extract and validate two complete themes

**Files:** `scripts/prepare-theme-assets.ps1`, `scripts/validate-theme-assets.ps1`, `entry/src/main/resources/base/media/moon_garden_*`, `entry/src/main/resources/base/media/stained_glass_*`, generated mapping in `entry/src/main/ets/common/TarotThemeMedia.ets`, `docs/assets/tarot-assets.md`

- [ ] Derive `moon_garden` from attachment 19 (major), 18/24 (wands/cups), and 20 (swords/pentacles).
- [ ] Derive `stained_glass` from attachment 21 (major), 22/25 (wands/cups), and 23 (swords/pentacles).
- [ ] Crop without stretching, preserve complete frames, normalize to a consistent 2:3 display area, and use flat resource names.
- [ ] Map every image to the existing 78 stable card IDs; render names and orientation in ArkUI instead of trusting embedded atlas text.
- [ ] Generate typed resource mapping only after the validator passes both themes.
- [ ] Build the application to prove all generated `$r('app.media.*')` references exist.

## Task 3: Typed domain model and spread engine

**Files:** `entry/src/main/ets/models/TarotModels.ets`, `entry/src/main/ets/models/TarotAppState.ets`, `entry/src/main/ets/services/DrawService.ets`, `entry/src/main/ets/services/SpreadService.ets`, `entry/src/ohosTest/ets/test/DrawService.test.ets`, `entry/src/ohosTest/ets/test/SpreadService.test.ets`

- [ ] First add failing tests for single, timeline, relationship, and seven-card position definitions.
- [ ] Add typed IDs for `moon_garden`, `stained_glass`, all four spreads, reading depth, scene, and five flow steps.
- [ ] Draw the required count without duplicates; honor the reversals setting.
- [ ] Freeze a session snapshot before animation so refresh, backgrounding, and back/forward navigation never redraw it.
- [ ] Add clarification draws capped at three and excluding all existing session cards.

## Task 4: Structured offline records and settings migration

**Files:** `entry/src/main/ets/repositories/LocalDataCodec.ets`, `entry/src/main/ets/repositories/LocalAppStore.ets`, related models/services/tests

- [ ] First add failing round-trip and legacy-migration tests.
- [ ] Persist versioned records containing question, scene, depth, spread, positions, card IDs, orientations, result, `themeId`, notes, favorite state, and clarification cards.
- [ ] Add the selected theme and new defaults to settings without losing V1 favorites, notes, or history.
- [ ] Keep all Preferences calls inside the repository; pages use the application state/service boundary.
- [ ] Require confirmation for deleting one record, clearing records, or clearing all local data.

## Task 5: Offline interpretation and clarification

**Files:** `entry/src/main/ets/services/InterpretationService.ets`, `entry/src/main/ets/services/SafetyService.ets`, tests

- [ ] First add failing tests for position-aware output, deep-reading connections, deterministic session output, clarification limits, and unsafe-certainty rewrites.
- [ ] Produce `core insight`, `action suggestion`, and `caution` from question category, scene, depth, spread position, card meaning, and orientation.
- [ ] Add cross-card connections for deep readings and progressive context for clarification cards.
- [ ] Keep medical, legal, investment, and destiny wording reflective and non-deterministic.
- [ ] Remove XiaoYi/network dependencies from active interpretation and UI.

## Task 6: Light design system and reusable shell

**Files:** `entry/src/main/ets/common/DesignTokens.ets`, `entry/src/main/resources/base/element/{color,float,string}.json`, new components under `entry/src/main/ets/components/`

- [ ] Replace the dark palette with the approved light moon-purple palette and 4/8/12/16/24/32 spacing scale.
- [ ] Implement reusable top bar, five-item bottom navigation, primary action, theme card, tarot card view, spread option, empty state, and confirmation dialog.
- [ ] Use native responsive ArkUI, safe areas, stable dimensions, accessible labels, and a 720vp maximum content width.
- [ ] Keep page sections unframed; use cards only for repeated items or genuinely framed controls.

## Task 7: Five-step reading flow and main pages

**Files:** `entry/src/main/ets/pages/Index.ets` plus extracted page/view-model/component files as required, string resources, tests

- [ ] First add state-transition tests for question -> spread -> shuffle/draw -> confirm -> result, including back navigation and duplicate-tap locking.
- [ ] Rebuild home, question, spread, shuffle/draw, confirmation, result, catalog, records, and settings/theme screens to references 12-17.
- [ ] Support question length 300, six scenes, concise/deep reading, random or manual draw, and all four spreads.
- [ ] Standardize bottom navigation to 首页 / 占卜 / 牌库 / 记录 / 我的.
- [ ] Make theme changes update home, draw, catalog, result, and history detail immediately while history prefers its saved `themeId`.
- [ ] Implement catalog categories and search across Chinese/English names, keywords, suits, and upright/reversed meanings.

## Task 8: Final verification and observed QA

**Files:** `changes.md`, `tasks.md`, `design-qa.md`, `docs/qa/screenshots/*` only when observed

- [ ] Run catalog/theme validators, all Hypium tests, static gate, debug build, and permission scan.
- [ ] Install and exercise the debug HAP on the available phone/emulator: both themes, all five steps, four spreads, clarification cap, persistence restart, catalog, records, and settings.
- [ ] Compare observed pages with references 12-17 at the supplied 941x1672 ratio and verify large text, small-screen scrolling, landscape, and tablet when available.
- [ ] Record only observed results in `design-qa.md`; record unavailable device classes as `blocked`.
- [ ] Update `changes.md`, set `T-20260731-002` to `done` only after implementation and verification both complete, run `git diff --check`, and commit the final QA batch.
