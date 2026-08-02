# Tarot Safe-Area and Participatory Reading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a four-tab, safe-area-correct HarmonyOS tarot app with real back navigation, time-aware greetings, participatory drawing, and question-specific constructive offline readings.

**Architecture:** Keep the existing Stage entry and persistence services, but move deterministic behavior into small pure ArkTS services that Hypium can test. `Index.ets` remains the page compositor and consumes the services through a typed view stack and draw-flow state; card knowledge is enriched in the catalog and interpreted through scene-aware helpers.

**Tech Stack:** HarmonyOS Stage model, ArkTS, ArkUI, Preferences, Hypium, PowerShell/Hvigor.

---

### Task 1: Time-aware greeting service

**Files:**
- Create: `entry/src/main/ets/services/GreetingService.ets`
- Create: `entry/src/ohosTest/ets/test/GreetingService.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`

- [ ] **Step 1: Write the failing boundary tests**

```ts
expect(GreetingService.forHour(5).title).assertEqual('早上好');
expect(GreetingService.forHour(9).title).assertEqual('上午好');
expect(GreetingService.forHour(12).title).assertEqual('中午好');
expect(GreetingService.forHour(14).title).assertEqual('下午好');
expect(GreetingService.forHour(18).title).assertEqual('晚上好');
expect(GreetingService.forHour(22).title).assertEqual('夜深了');
expect(GreetingService.forHour(0).title).assertEqual('夜深了');
```

- [ ] **Step 2: Build ohosTest and verify the missing service fails**

Run: `& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry@ohosTest -p product=default -p buildMode=debug assembleHap --no-daemon`

Expected: FAIL because `GreetingService` does not exist.

- [ ] **Step 3: Implement the pure service**

```ts
export interface GreetingCopy { title: string; subtitle: string; }

export class GreetingService {
  static forHour(hour: number): GreetingCopy {
    const normalized: number = ((hour % 24) + 24) % 24;
    if (normalized >= 5 && normalized < 9) return { title: '早上好', subtitle: '愿你带着清醒与从容开始今天' };
    if (normalized < 12 && normalized >= 9) return { title: '上午好', subtitle: '愿你在专注里看见清晰方向' };
    if (normalized < 14 && normalized >= 12) return { title: '中午好', subtitle: '给自己一点停顿与整理的空间' };
    if (normalized < 18 && normalized >= 14) return { title: '下午好', subtitle: '愿你稳稳走向正在靠近的答案' };
    if (normalized < 22 && normalized >= 18) return { title: '晚上好', subtitle: '愿你在安静里听见真实感受' };
    return { title: '夜深了', subtitle: '先照顾自己，再慢慢整理心里的问题' };
  }
}
```

- [ ] **Step 4: Rebuild ohosTest and verify it passes**

Expected: PASS compilation with all greeting assertions included.

### Task 2: Typed navigation and double-back state

**Files:**
- Modify: `entry/src/main/ets/models/TarotModels.ets`
- Create: `entry/src/main/ets/services/NavigationService.ets`
- Create: `entry/src/ohosTest/ets/test/NavigationService.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`

- [ ] **Step 1: Add failing tests for push, pop, tab reset, menu, and double-back**

```ts
const nav: NavigationService = new NavigationService('home');
nav.push('question'); nav.push('drawMode');
expect(nav.back()).assertEqual('question');
nav.selectRoot('catalog');
expect(nav.current()).assertEqual('catalog');
expect(nav.depth()).assertEqual(1);
expect(NavigationService.isSecondBack(1000, 2200, 1500)).assertTrue();
expect(NavigationService.isSecondBack(1000, 2600, 1500)).assertFalse();
```

- [ ] **Step 2: Build and verify failure**

Expected: FAIL because `AppPage` and `NavigationService` do not exist.

- [ ] **Step 3: Add the types and minimal stack service**

```ts
export type AppRootPage = 'home' | 'question' | 'catalog' | 'settings';
export type AppPage = AppRootPage | 'drawMode' | 'shuffle' | 'select' | 'reveal' |
  'result' | 'history' | 'cardDetail' | 'about';

export class NavigationService {
  private stack: AppPage[];
  constructor(initial: AppPage) { this.stack = [initial]; }
  current(): AppPage { return this.stack[this.stack.length - 1]; }
  depth(): number { return this.stack.length; }
  push(page: AppPage): AppPage { this.stack.push(page); return page; }
  replace(page: AppPage): AppPage { this.stack[this.stack.length - 1] = page; return page; }
  back(): AppPage { if (this.stack.length > 1) this.stack.pop(); return this.current(); }
  selectRoot(page: AppRootPage): AppPage { this.stack = [page]; return page; }
  static isSecondBack(first: number, next: number, windowMs: number): boolean {
    return first > 0 && next >= first && next - first <= windowMs;
  }
}
```

- [ ] **Step 4: Build and verify the tests pass**

Expected: navigation tests compile and pass without modifying persistence.

### Task 3: Participatory draw state machine

**Files:**
- Modify: `entry/src/main/ets/models/TarotModels.ets`
- Create: `entry/src/main/ets/services/DrawFlowService.ets`
- Create: `entry/src/ohosTest/ets/test/DrawFlowService.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`

- [ ] **Step 1: Write failing tests for three shuffles, selection, locking, reveal, and duplicate rejection**

```ts
const flow: DrawFlowService = new DrawFlowService(3);
flow.shuffle(); flow.shuffle();
expect(flow.canSelect()).assertFalse();
flow.shuffle();
expect(flow.canSelect()).assertTrue();
expect(flow.toggle('major-00')).assertTrue();
expect(flow.toggle('major-00')).assertTrue();
expect(flow.selectedCount()).assertEqual(0);
flow.toggle('major-00'); flow.toggle('major-01'); flow.toggle('major-02');
expect(flow.confirm()).assertTrue();
expect(flow.toggle('major-03')).assertFalse();
expect(flow.revealNext()).assertEqual(1);
expect(flow.allRevealed()).assertFalse();
```

- [ ] **Step 2: Build and verify failure**

Expected: FAIL because `DrawFlowService` does not exist.

- [ ] **Step 3: Implement the deterministic flow**

```ts
export type DrawPhase = 'shuffle' | 'select' | 'reveal' | 'complete';

export class DrawFlowService {
  private phaseValue: DrawPhase = 'shuffle';
  private shuffleValue: number = 0;
  private selected: string[] = [];
  private revealed: number = 0;
  constructor(private required: number) {}
  shuffle(): number { if (this.phaseValue === 'shuffle') this.shuffleValue = Math.min(3, this.shuffleValue + 1); return this.shuffleValue; }
  canSelect(): boolean { return this.shuffleValue >= 3 && this.phaseValue !== 'reveal' && this.phaseValue !== 'complete'; }
  toggle(cardId: string): boolean {
    if (!this.canSelect()) return false;
    this.phaseValue = 'select';
    const index: number = this.selected.indexOf(cardId);
    if (index >= 0) { this.selected.splice(index, 1); return true; }
    if (this.selected.length >= this.required) return false;
    this.selected.push(cardId); return true;
  }
  confirm(): boolean {
    if (this.phaseValue !== 'select' || this.selected.length !== this.required) return false;
    this.phaseValue = 'reveal'; return true;
  }
  revealNext(): number {
    if (this.phaseValue !== 'reveal') return this.revealed;
    this.revealed = Math.min(this.required, this.revealed + 1);
    if (this.revealed === this.required) this.phaseValue = 'complete';
    return this.revealed;
  }
  allRevealed(): boolean { return this.phaseValue === 'complete'; }
  selectedIds(): string[] { return this.selected.slice(); }
  selectedCount(): number { return this.selected.length; }
  phase(): DrawPhase { return this.phaseValue; }
}
```

Implement the bodies exactly to satisfy the state-transition assertions, including selection removal and post-confirm locking.

- [ ] **Step 4: Build and verify all flow tests pass**

Expected: three-shuffle gate, exact-count confirmation, sequential reveal, and duplicate prevention all pass.

### Task 4: Scene-aware constructive interpretation

**Files:**
- Modify: `entry/src/main/ets/models/TarotModels.ets`
- Create: `entry/src/main/ets/services/SceneKnowledgeService.ets`
- Modify: `entry/src/main/ets/services/QuestionClassifier.ets`
- Modify: `entry/src/main/ets/services/InterpretationService.ets`
- Modify: `entry/src/ohosTest/ets/test/QuestionClassifier.test.ets`
- Modify: `entry/src/ohosTest/ets/test/InterpretationService.test.ets`

- [ ] **Step 1: Add failing relevance and constructive-language tests**

```ts
expect(QuestionClassifier.sceneFor('明天的工作汇报怎么准备', 'relationship')).assertEqual('career');
expect(QuestionClassifier.sceneFor('怎样和伴侣谈边界', 'career')).assertEqual('relationship');
const career = InterpretationService.build({ ...base, question: '项目延期怎么办', scene: 'career' }, [SAMPLE_CARD]);
const relation = InterpretationService.build({ ...base, question: '关系中如何沟通', scene: 'relationship' }, [SAMPLE_CARD]);
expect(career.summary.includes('项目')).assertTrue();
expect(relation.summary.includes('沟通')).assertTrue();
expect(career.summary === relation.summary).assertFalse();
expect(reversed.action.includes('可以')).assertTrue();
expect(reversed.summary.includes('一定会')).assertFalse();
```

- [ ] **Step 2: Build and verify the new assertions fail**

Expected: FAIL because scene override and scene knowledge are absent.

- [ ] **Step 3: Implement scene lenses and question focus extraction**

```ts
export interface SceneLens { focus: string; strength: string; caution: string; actionFrame: string; }
export class SceneKnowledgeService {
  static forScene(scene: ReadingScene): SceneLens {
    if (scene === 'study') return { focus: '学习与准备', strength: '已有方法和可积累的能力', caution: '节奏、理解盲点与压力', actionFrame: '选一项最能推进理解的练习' };
    if (scene === 'career') return { focus: '工作与推进', strength: '现有资源和可影响的环节', caution: '沟通、优先级与边界', actionFrame: '明确一个可交付的下一步' };
    if (scene === 'relationship') return { focus: '关系与沟通', strength: '真实感受和连接意愿', caution: '期待差异、边界与表达方式', actionFrame: '进行一次不预设结果的沟通' };
    if (scene === 'social') return { focus: '相处与支持', strength: '可建立的信任和共同点', caution: '角色压力与互惠失衡', actionFrame: '确认一项双方都舒服的边界' };
    if (scene === 'growth') return { focus: '个人成长', strength: '觉察、选择和调整能力', caution: '惯性、自我否定与过度要求', actionFrame: '完成一个足够小的改变' };
    return { focus: '今天的状态', strength: '当下可用的精力和注意力', caution: '忽略休息或被琐事牵引', actionFrame: '安排一件真正重要的小事' };
  }
  static questionFocus(question: string, scene: ReadingScene): string {
    const value: string = question.trim().replace(/\s+/g, ' ');
    return value.length === 0 ? SceneKnowledgeService.forScene(scene).focus : value.slice(0, 24);
  }
}
```

Add `QuestionClassifier.sceneFor(question, selectedScene)` so explicit work/study, relationship, social, growth, or daily terms override a mismatched chip. Update `InterpretationService.build()` to combine the original question focus, scene lens, card position, orientation, keywords, and depth. Increment `algorithmVersion` to `2`; keep `SafetyService.noticeFor()` authoritative.

- [ ] **Step 4: Build and verify interpretation tests pass**

Expected: summaries differ by question/scene, reversed readings remain actionable, and high-risk notices remain present.

### Task 5: Resources, tokens, header, menu, and four-tab shell

**Files:**
- Modify: `entry/src/main/ets/common/DesignTokens.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`

- [ ] **Step 1: Run the standard gate as a UI baseline**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1`

Expected: current gate result captured before UI edits.

- [ ] **Step 2: Centralize the approved visual tokens**

Add `CONTENT_MAX_WIDTH = 720`, `PAGE_PADDING = 16`, `HEADER_HEIGHT = 56`, `NAV_HEIGHT = 64`, `TOUCH_TARGET = 48`, `RADIUS_SMALL = 6`, `RADIUS_MEDIUM = 8`, and safe-area surface colors. Replace hard-coded UI values touched by this task with these tokens.

- [ ] **Step 3: Add all visible copy to resources**

Add resources for six greeting titles/subtitles, `再次返回以退出`, `退出应用？`, `是否退出塔罗灵感牌？`, `灵感记录`, menu accessibility, shuffle count, selection count, confirm selection, reveal next, and finish reading.

- [ ] **Step 4: Wire typed navigation into `Index.ets`**

Replace direct page assignments in touched flows with `openPage`, `replacePage`, `selectRoot`, and `goBack`. Add `onBackPress(): boolean` to call the same `goBack()` behavior. On home, use the 1.5-second double-back rule and `showAlertDialog`; confirmed exit calls the host `UIAbilityContext.terminateSelf()`.

- [ ] **Step 5: Replace the moon and settings jump**

The left header control is always a 48vp back button. The right three-dot button toggles an anchored menu; the button itself never changes pages. The menu item `灵感记录` pushes `history`. Dismiss it on outside click, back, and root-tab change.

- [ ] **Step 6: Reduce the bottom bar to four roots**

Render only home, draw, catalog, and profile/settings. Remove history from `NavBar`; hide `NavBar` for every non-root page. Keep all interactive content above the system bottom avoid area and constrain the inner column to `CONTENT_MAX_WIDTH`.

- [ ] **Step 7: Build debug and fix ArkTS/ArkUI errors**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug`

Expected: debug HAP builds with no missing resource or illegal Builder errors.

### Task 6: Interactive shuffle, selection, reveal, and clarification UI

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/resources/base/element/string.json`

- [ ] **Step 1: Connect the required card count to `SpreadService`**

When entering shuffle, resolve `const normalized: SpreadType = SpreadService.storedValue(this.spread)` and create `DrawFlowService` with `SpreadService.byId(normalized).positions.length`; daily and single resolve to one. Precompute eligible card IDs but do not compute orientations or interpretations before confirmation.

- [ ] **Step 2: Rebuild `ShufflePage`**

Keep the `tlp` stacked-card composition. Each tap or horizontal pan completion calls `shuffle()`, animates rotation/translation, and displays `已洗牌 n/3`. Only after three interactions does the continue action enter selection.

- [ ] **Step 3: Add `SelectCardsPage`**

Display stable card-back candidates in a horizontally scrollable/fan-like layout. A selected card lifts by 16vp and receives the next spread-position label. Permit deselection before confirmation, cap selection at the spread size, and enable confirmation only at exact count.

- [ ] **Step 4: Materialize the confirmed draw and add `RevealPage`**

Map confirmed IDs to `DrawnCard` values with one orientation per card. Reveal only the first locked card initially. Each user tap reveals the next card with rotation/opacity animation. Call `updateReading()` and push `result` only after `allRevealed()`.

- [ ] **Step 5: Route clarification through the same mini-flow**

Replace immediate `addClarification()` with selection and reveal state for one excluded card. Append it only after reveal, regenerate the reading, preserve `savedRecordId`, and keep the three-card cap.

- [ ] **Step 6: Verify all spread sizes in debug build**

Expected: single/daily require 1 selection, timeline/relationship require 3, seven requires 7; no result appears before the final reveal.

### Task 7: Full verification and documentation

**Files:**
- Modify: `changes.md`
- Modify: `design-qa.md` only for observed device results
- Modify: `tasks.md`

- [ ] **Step 1: Run source and data gates**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
python .\scripts\validate_tarot_catalog.py
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-theme-assets.ps1
```

Expected: all commands exit 0.

- [ ] **Step 2: Build debug and ohosTest HAPs**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry@ohosTest -p product=default -p buildMode=debug assembleHap --no-daemon
```

Expected: both builds exit 0.

- [ ] **Step 3: Run device tests and visual QA when an emulator/device is available**

Observe status-bar clearance, bottom gesture clearance, four-tab navigation, menu-only history entry, back-stack order, double-back exit confirmation, six greeting periods through injected service tests, shuffle/select/reveal gates, and single/three/seven-card layouts. Record only direct observations in `design-qa.md`; mark unavailable tablet, landscape, or font-scale checks `blocked`.

- [ ] **Step 4: Update project records**

Set `T-20260801-001` to `done` only when implementation, automated gates, builds, and required documentation are complete. Summarize changed behavior and exact verification evidence in `changes.md` without overwriting prior records.
