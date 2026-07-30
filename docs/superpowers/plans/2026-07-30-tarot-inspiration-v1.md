# Tarot Inspiration V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-structured HarmonyOS ArkTS/ArkUI tarot app whose complete core works offline, produces locally personalized Simplified Chinese readings, and optionally launches a XiaoYi agent.

**Architecture:** A Stage-model `entry` module separates route pages, reusable UI, pure domain services, repositories, and HarmonyOS adapters. A bundled 78-card JSON catalog is the source of truth; pure services handle draws, classification, interpretation, and safety before UI animation begins. Preferences stores small settings, RDB stores user records, and Agent Framework Kit is isolated behind a capability-aware optional adapter.

**Tech Stack:** HarmonyOS 6.1.1 API 24, ArkTS, ArkUI, Ability Kit, ArkData Preferences/RDB, Agent Framework Kit, Hypium, Hvigor.

---

## File map

- Root build files: `build-profile.json5`, `oh-package.json5`, `hvigorfile.ts`, `oh-package-lock.json5`
- Standard delivery docs: `README.md`, `AGENTS.md`, `tasks.md`, `changes.md`, `design.md`, `design-qa.md`, `docs/qa/README.md`
- Build scripts: `scripts/check-standard.ps1`, `scripts/build-harmony.ps1`
- Ability/config: `entry/src/main/module.json5`, `entry/src/main/ets/entryability/EntryAbility.ets`, `entry/src/main/resources/base/profile/main_pages.json`
- Domain models: `entry/src/main/ets/models/*.ets`
- Pure logic: `entry/src/main/ets/services/DrawService.ets`, `QuestionClassifier.ets`, `InterpretationService.ets`, `SafetyService.ets`
- Platform services: `CatalogService.ets`, `SettingsService.ets`, `HistoryService.ets`, `AudioService.ets`, `HapticService.ets`, `XiaoYiAgentService.ets`
- Persistence: `entry/src/main/ets/repositories/*.ets`
- Shared design/UI: `entry/src/main/ets/common/*.ets`, `entry/src/main/ets/components/*.ets`
- Pages: `entry/src/main/ets/pages/*.ets`
- Resources: `entry/src/main/resources/base/{element,media,profile}/`
- Unit tests: `entry/src/ohosTest/ets/test/*.test.ets`
- Data validation: `scripts/validate_tarot_catalog.py`

### Task 1: Standardized Stage project and build gate

**Files:**
- Create all root build files, standard docs, scripts, `entry/build-profile.json5`, `entry/hvigorfile.ts`, `entry/oh-package.json5`, `entry/src/main/module.json5`
- Create `entry/src/main/ets/entryability/EntryAbility.ets`
- Create `entry/src/main/resources/base/profile/main_pages.json`
- Create `entry/src/main/resources/base/element/{string.json,color.json,float.json}`

- [ ] **Step 1: Write the static gate expectation**

```powershell
python "C:\Users\27363\Desktop\harmonyos-project-standard-cn\scripts\check_harmonyos_standard.py" "C:\Users\27363\Desktop\max\taluopai"
```

Expected: failures identify the missing Stage model files and standard documents.

- [ ] **Step 2: Create a minimal API 24 Stage application**

```json5
{
  "app": {
    "products": [{
      "name": "default",
      "compatibleSdkVersion": "6.1.1(24)",
      "targetSdkVersion": "6.1.1(24)",
      "runtimeOS": "HarmonyOS"
    }],
    "buildModeSet": [{ "name": "debug" }, { "name": "release" }]
  },
  "modules": [{ "name": "entry", "srcPath": "./entry", "targets": [{ "name": "default", "applyToProducts": ["default"] }] }]
}
```

- [ ] **Step 3: Register only phone/tablet and vibration permission**

```json5
"deviceTypes": ["phone", "tablet"],
"requestPermissions": [{
  "name": "ohos.permission.VIBRATE",
  "reason": "$string:vibration_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
}]
```

- [ ] **Step 4: Run the standard gate and debug build**

```powershell
python "C:\Users\27363\Desktop\harmonyos-project-standard-cn\scripts\check_harmonyos_standard.py" .
.\scripts\build-harmony.ps1 -Mode debug
```

Expected: static gate exits 0; Hvigor produces an unsigned or locally signed debug HAP without embedding external signing secrets.

- [ ] **Step 5: Commit**

```powershell
git add .
git commit -m "build: scaffold standardized HarmonyOS app"
```

### Task 2: Simplified Chinese 78-card catalog and asset manifest

**Files:**
- Create `entry/src/main/resources/rawfile/tarot_cards_zh_cn.json`
- Create `entry/src/main/resources/rawfile/knowledge_sources.json`
- Create `entry/src/main/resources/base/media/tarot_*.jpg`
- Create `entry/src/main/resources/base/media/card_back.png`
- Create `entry/src/main/resources/base/media/card_placeholder.png`
- Create `scripts/validate_tarot_catalog.py`
- Create `docs/assets/tarot-assets.md`
- Test `entry/src/ohosTest/ets/test/CatalogSchema.test.ets`

- [ ] **Step 1: Write a failing catalog validator**

```python
assert len(cards) == 78
assert len({card["id"] for card in cards}) == 78
assert all(card["nameZhCn"] and card["upright"]["keywords"] for card in cards)
assert all((media_dir / card["image"]).exists() for card in cards)
```

- [ ] **Step 2: Run the validator**

```powershell
python .\scripts\validate_tarot_catalog.py
```

Expected: FAIL because the catalog and media do not exist.

- [ ] **Step 3: Convert and normalize the licensed source**

Each record follows this stable schema:

```json
{
  "id": "major-00",
  "nameZhCn": "愚者",
  "nameEn": "The Fool",
  "arcana": "major",
  "number": 0,
  "element": "风",
  "image": "tarot_major_00_fool.jpg",
  "upright": {
    "keywords": ["新开始", "自由", "纯真", "冒险"],
    "meaning": "你正站在一个新阶段的入口。",
    "actionSeeds": ["允许自己先迈出一个小步"],
    "reflectionSeeds": ["什么让你既期待又犹豫？"]
  },
  "reversed": {
    "keywords": ["轻率", "准备不足", "犹豫"],
    "meaning": "新的可能仍在，但需要先检查准备是否充分。",
    "actionSeeds": ["确认风险和最小可行步骤"],
    "reflectionSeeds": ["你缺少的是信息、准备，还是勇气？"]
  },
  "symbolism": "旅人站在崖边，象征未知与开放的可能。",
  "sourceIds": ["waite-1910", "claude-tarot-mit-2026"]
}
```

- [ ] **Step 4: Copy the 78 independent licensed images and write provenance**

`docs/assets/tarot-assets.md` records source archive, original entry, final resource name, license, dimensions, and visual replacement status for every asset group.

- [ ] **Step 5: Run validator and Hypium schema test**

```powershell
python .\scripts\validate_tarot_catalog.py
.\hvigorw.bat --mode module -p module=entry@ohosTest -p product=default -p buildMode=debug assembleHap
```

Expected: 78 records, 78 unique IDs, all media present, test HAP builds.

- [ ] **Step 6: Commit**

```powershell
git add entry/src/main/resources scripts/validate_tarot_catalog.py docs/assets
git commit -m "feat: add simplified Chinese tarot catalog"
```

### Task 3: Pure draw, classification, safety, and interpretation engine

**Files:**
- Create `entry/src/main/ets/models/TarotModels.ets`
- Create `entry/src/main/ets/services/DrawService.ets`
- Create `entry/src/main/ets/services/QuestionClassifier.ets`
- Create `entry/src/main/ets/services/SafetyService.ets`
- Create `entry/src/main/ets/services/InterpretationService.ets`
- Test `entry/src/ohosTest/ets/test/{DrawService,QuestionClassifier,SafetyService,InterpretationService}.test.ets`

- [ ] **Step 1: Write failing deterministic draw tests**

```typescript
expect(drawSingle(ids, seededRandom).cardId).assertEqual('major-00')
expect(new Set(drawThree(ids, seededRandom).map(item => item.cardId)).size).assertEqual(3)
expect(dailyDraw(ids, '2026-07-30', true)).assertDeepEquals(dailyDraw(ids, '2026-07-30', true))
```

- [ ] **Step 2: Run tests and verify failure**

```powershell
.\hvigorw.bat --mode module -p module=entry@ohosTest -p product=default -p buildMode=debug assembleHap
```

Expected: compile failure because services do not exist.

- [ ] **Step 3: Implement domain contracts**

```typescript
export type QuestionCategory = 'relationship' | 'workStudy' | 'decision' | 'emotion' | 'growth' | 'daily'
export type Orientation = 'upright' | 'reversed'
export interface DrawnCard { cardId: string; orientation: Orientation; position: string }
export interface ReadingContext {
  question: string
  category: QuestionCategory
  mood?: string
  recentThemes: string[]
  cards: DrawnCard[]
}
```

- [ ] **Step 4: Write failing personalization and safety tests**

```typescript
expect(reading.summary.includes('工作')).assertTrue()
expect(reading.action.length > 0).assertTrue()
expect(filterUnsafe('你一定会成功').includes('一定')).assertFalse()
expect(classifyQuestion('我该怎么面对这段关系')).assertEqual('relationship')
```

- [ ] **Step 5: Implement the layered local result**

```typescript
export interface ReadingResult {
  summary: string
  sections: CardReadingSection[]
  connection?: string
  action: string
  reflection: string
  safetyNotice?: string
  algorithmVersion: number
}
```

Generation order is category → position → orientation → mood → recent theme → safety rewrite. Medical, legal, investment, death, and disease terms return a professional-advice notice and reflective wording only.

- [ ] **Step 6: Run tests and build**

```powershell
.\scripts\build-harmony.ps1 -Mode debug
```

Expected: pure service tests pass and application debug HAP builds.

- [ ] **Step 7: Commit**

```powershell
git add entry/src/main/ets/models entry/src/main/ets/services entry/src/ohosTest
git commit -m "feat: add offline personalized reading engine"
```

### Task 4: Local persistence and repositories

**Files:**
- Create `entry/src/main/ets/repositories/SettingsRepository.ets`
- Create `entry/src/main/ets/repositories/TarotRecordRepository.ets`
- Create `entry/src/main/ets/services/{SettingsService,HistoryService,CatalogService}.ets`
- Test `entry/src/ohosTest/ets/test/{SettingsRepository,TarotRecordRepository,HistoryService}.test.ets`

- [ ] **Step 1: Write failing restart-persistence tests**

```typescript
await settings.save({ reversalsEnabled: false, soundEnabled: true })
expect((await settings.load()).reversalsEnabled).assertFalse()
const id = await records.save(sampleRecord)
expect((await records.findById(id))?.question).assertEqual(sampleRecord.question)
```

- [ ] **Step 2: Implement versioned settings and RDB records**

```typescript
export interface AppSettings {
  schemaVersion: number
  onboardingComplete: boolean
  soundEnabled: boolean
  hapticEnabled: boolean
  reversalsEnabled: boolean
  autoSaveEnabled: boolean
  recentThemesEnabled: boolean
}
```

RDB tables use stable text IDs and include `created_at`, `updated_at`, `favorite`, `mood`, `note`, `question`, `spread_type`, `cards_json`, `reading_json`, and `algorithm_version`.

- [ ] **Step 3: Add migration and damaged-row tolerance**

Each query maps rows independently; a malformed JSON row is skipped and reported to the service without preventing the rest of the history list from loading.

- [ ] **Step 4: Run tests and build**

```powershell
.\scripts\build-harmony.ps1 -Mode debug
```

Expected: settings and records survive repository re-instantiation; malformed row test leaves valid rows visible.

- [ ] **Step 5: Commit**

```powershell
git add entry/src/main/ets/repositories entry/src/main/ets/services entry/src/ohosTest
git commit -m "feat: persist tarot settings and records"
```

### Task 5: Design tokens, application shell, and reusable components

**Files:**
- Create `entry/src/main/ets/common/{DesignTokens,Routes,Formatters}.ets`
- Create `entry/src/main/ets/components/{PageShell,TopBar,BottomNav,TarotCardView,PrimaryButton,SectionCard,MoodPicker,EmptyState,ConfirmDialog}.ets`
- Create `entry/src/main/ets/pages/MainTabsPage.ets`
- Test `entry/src/ohosTest/ets/test/{DesignTokens,ResponsiveLayout}.test.ets`

- [ ] **Step 1: Write token and responsive-layout tests**

```typescript
expect(DesignTokens.color.background).assertEqual('#0E1024')
expect(resolveContentWidth(360)).assertEqual(328)
expect(resolveContentWidth(1280) <= 720).assertTrue()
```

- [ ] **Step 2: Implement centralized design tokens**

```typescript
export class DesignTokens {
  static readonly color = {
    background: '#0E1024',
    surface: '#141B3A',
    card: '#1F2854',
    gold: '#E2C07A',
    text: '#FFF1CC',
    textSecondary: '#B8B2C8'
  }
  static readonly spacing = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 }
  static readonly radius = { sm: 8, md: 12, lg: 16, button: 14 }
}
```

- [ ] **Step 3: Build the shell and four-tab navigation**

The shell respects system safe areas, caps tablet content width, uses text labels for every icon, and keeps touch targets at least 48vp.

- [ ] **Step 4: Build reusable loading, empty, error, card, and confirmation states**

Components accept plain typed props and callbacks; they do not load repositories directly.

- [ ] **Step 5: Build and save baseline screenshots when a device is available**

```powershell
.\scripts\build-harmony.ps1 -Mode debug
```

Expected: debug build succeeds; no device result is claimed without a captured screenshot.

- [ ] **Step 6: Commit**

```powershell
git add entry/src/main/ets/common entry/src/main/ets/components entry/src/main/ets/pages entry/src/ohosTest
git commit -m "feat: add tarot design system and app shell"
```

### Task 6: Onboarding, home, draw flow, and result pages

**Files:**
- Create `entry/src/main/ets/pages/{SplashPage,OnboardingPage,HomePage,DrawModePage,QuestionPage,ShufflePage,SingleResultPage,ThreeCardResultPage,DailyReadingPage}.ets`
- Create `entry/src/main/ets/viewmodels/{DrawFlowViewModel,ResultViewModel}.ets`
- Modify `entry/src/main/resources/base/profile/main_pages.json`
- Test `entry/src/ohosTest/ets/test/{DrawFlowViewModel,DailyReading}.test.ets`

- [ ] **Step 1: Write failing state-machine tests**

```typescript
expect(flow.state).assertEqual('idle')
flow.startShuffle()
flow.startShuffle()
expect(flow.shuffleStartCount).assertEqual(1)
flow.onBackground()
expect(flow.state).assertEqual('idle')
```

- [ ] **Step 2: Implement draw state before animation**

`DrawFlowViewModel` computes and stores the complete result before changing state from `idle` to `shuffling`; UI animation reads the stored result and never determines randomness.

- [ ] **Step 3: Implement the three-step flow**

Question input accepts up to 120 Chinese characters, offers four safe example questions, and has a visible skip action. Shuffle/flip buttons remain disabled while animations are running.

- [ ] **Step 4: Implement layered result pages**

Above the fold shows card, Chinese name, orientation text, keywords, and short insight. Detailed meaning, personalized mapping, action, reflection, mood, and note appear below in a scroll view.

- [ ] **Step 5: Implement same-day daily reading**

The service key is local date `yyyy-MM-dd`; reopening the page returns the same card and orientation until the date changes.

- [ ] **Step 6: Run tests and build**

```powershell
.\scripts\build-harmony.ps1 -Mode debug
```

Expected: duplicate-click and background tests pass; all routes resolve; build succeeds.

- [ ] **Step 7: Commit**

```powershell
git add entry/src/main/ets/pages entry/src/main/ets/viewmodels entry/src/main/resources entry/src/ohosTest
git commit -m "feat: implement offline tarot draw flows"
```

### Task 7: Catalog, favorites, history, record detail, and settings

**Files:**
- Create `entry/src/main/ets/pages/{CatalogPage,CardDetailPage,HistoryPage,RecordDetailPage,FavoritesPage,SettingsPage,PrivacyPage,AboutPage}.ets`
- Create `entry/src/main/ets/viewmodels/{CatalogViewModel,HistoryViewModel,SettingsViewModel}.ets`
- Test `entry/src/ohosTest/ets/test/{CatalogFilter,HistoryFilter,SettingsViewModel}.test.ets`

- [ ] **Step 1: Write failing catalog and history filter tests**

```typescript
expect(filterCards(cards, '星星', 'all', false).length).assertEqual(1)
expect(filterRecords(records, 'three').every(item => item.spreadType === 'three')).assertTrue()
expect(sortNewest(records)[0].createdAt >= sortNewest(records)[1].createdAt).assertTrue()
```

- [ ] **Step 2: Implement the 78-card searchable catalog**

Tabs cover all, major, wands, cups, swords, and pentacles; favorite-only is a separate filter. Cards use thumbnail resources and stable IDs.

- [ ] **Step 3: Implement history and destructive confirmations**

Single delete and clear-all are repository operations. Clear-all requires a confirmation dialog that names the irreversible result; note clearing is a separate action.

- [ ] **Step 4: Implement settings and content pages**

Settings include sound, vibration, reversals, auto-save, recent-theme personalization, replay onboarding, clear history, clear notes, restore defaults, privacy, usage, and about.

- [ ] **Step 5: Run tests and build**

```powershell
.\scripts\build-harmony.ps1 -Mode debug
```

Expected: catalog filters, favorites, history ordering, persistence refresh, and routes pass.

- [ ] **Step 6: Commit**

```powershell
git add entry/src/main/ets/pages entry/src/main/ets/viewmodels entry/src/ohosTest
git commit -m "feat: add catalog history favorites and settings"
```

### Task 8: Audio, haptics, lifecycle, and optional XiaoYi agent

**Files:**
- Create `entry/src/main/ets/services/{AudioService,HapticService,AppLifecycleService,XiaoYiAgentService}.ets`
- Create `entry/src/main/ets/components/XiaoYiEnhancementCard.ets`
- Modify `entry/src/main/ets/entryability/EntryAbility.ets`
- Test `entry/src/ohosTest/ets/test/{LifecycleService,XiaoYiAgentService}.test.ets`

- [ ] **Step 1: Write failing downgrade and consent tests**

```typescript
expect(await agent.getAvailability()).assertEqual('unsupported')
expect(await agent.launch(context, false)).assertEqual({ status: 'consent-required' })
expect((await agent.buildPayload(context)).history).assertUndefined()
```

- [ ] **Step 2: Implement independent feedback services**

Audio or vibration failure is caught and logged without rejecting a draw. Lifecycle background events stop feedback and reset unfinished animation state.

- [ ] **Step 3: Implement the Agent Framework adapter against official API 24 docs**

The adapter detects capability, requires explicit confirmation, sends only current question/cards/local summary, and returns `launched`, `unsupported`, `unconfigured`, `offline`, or `failed`.

- [ ] **Step 4: Add the optional result-page enhancement card**

The card is never shown as required. Unsupported/unconfigured state explains that local interpretation remains fully available.

- [ ] **Step 5: Run tests, static permission audit, and build**

```powershell
rg -n "INTERNET|CAMERA|MICROPHONE|LOCATION" entry/src/main/module.json5
.\scripts\build-harmony.ps1 -Mode debug
```

Expected: no unrelated permission; downgrade tests pass; build succeeds on the installed SDK. If Agent Framework requires a project/account configuration unavailable locally, keep the compiled adapter behind configuration and record the exact external prerequisite.

- [ ] **Step 6: Commit**

```powershell
git add entry/src/main/ets/services entry/src/main/ets/components entry/src/main/ets/entryability entry/src/ohosTest
git commit -m "feat: add optional XiaoYi enhancement"
```

### Task 9: Visual restoration, accessibility, and performance pass

**Files:**
- Modify all page/component files as indicated by screenshot comparison
- Create `docs/qa/visual-checklist.md`
- Create `docs/qa/performance-checklist.md`

- [ ] **Step 1: Compare implementation in hierarchy order**

Record pass/fail for safe area, header, hero, cards, CTA hierarchy, bottom navigation, radii, dividers, icon stroke, card aspect ratio, and gold/purple contrast.

- [ ] **Step 2: Test responsive and text-resilience states**

Test 320vp phone, common phone, tablet capped width, 1.3× font, longest card name, 120-character question, empty lists, and damaged-image fallback.

- [ ] **Step 3: Verify loading policy**

Catalog uses thumbnails, catalog JSON is parsed once and cached, history loads in batches, and unused animation/audio resources are released on page exit.

- [ ] **Step 4: Build and capture evidence**

```powershell
.\scripts\build-harmony.ps1 -Mode debug
```

Expected: build succeeds; device screenshots are stored only if a real device/emulator is actually used.

- [ ] **Step 5: Commit**

```powershell
git add entry docs/qa
git commit -m "fix: polish tarot visual and accessibility details"
```

### Task 10: Final gates and delivery record

**Files:**
- Modify `tasks.md`, `changes.md`, `design-qa.md`, `docs/qa/README.md`

- [ ] **Step 1: Run catalog and static gates**

```powershell
python .\scripts\validate_tarot_catalog.py
python "C:\Users\27363\Desktop\harmonyos-project-standard-cn\scripts\check_harmonyos_standard.py" .
```

Expected: both exit 0.

- [ ] **Step 2: Run clean debug build**

```powershell
.\scripts\build-harmony.ps1 -Mode debug -Clean
```

Expected: Hvigor exits 0 and the produced HAP path/size are recorded.

- [ ] **Step 3: Audit privacy and secrets**

```powershell
rg -n "password|secret|token|storePassword|keyPassword|ohos.permission.INTERNET|ohos.permission.CAMERA|ohos.permission.MICROPHONE" . -g "!docs/superpowers/**" -g "!.git/**"
```

Expected: no credential, signing secret, online endpoint, or unrelated permission in source.

- [ ] **Step 4: Update evidence documents truthfully**

`tasks.md` marks only verified tasks done. `changes.md` records exact commands, exit codes, HAP path, warnings, and external XiaoYi configuration prerequisites. `design-qa.md` contains only observed UI results.

- [ ] **Step 5: Commit**

```powershell
git add tasks.md changes.md design-qa.md docs/qa
git commit -m "docs: record final tarot app verification"
```

## Self-review

- Spec coverage: all eleven design sections map to Tasks 1–10.
- Type consistency: `QuestionCategory`, `Orientation`, `DrawnCard`, `ReadingContext`, `ReadingResult`, and `AppSettings` retain the same names across services, UI, persistence, and tests.
- Scope boundaries: online behavior exists only in `XiaoYiAgentService`; all core workflows depend exclusively on bundled resources and local repositories.
- No unresolved placeholders or unbounded “implement later” steps remain.
