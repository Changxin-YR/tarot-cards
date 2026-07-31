# 参考视频分阶段抽牌体验 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改变离线、隐私与安全边界的前提下，把现有一次点击出结果的抽牌页升级为有牌阵推荐、洗牌、切牌、逐张选牌、确认翻牌和可选补充信息的完整仪式化流程。

**Architecture:** 保留现有 `DrawService`、`InterpretationService`、78 张 RWS 牌库和本地持久化；新增纯 ArkTS 抽牌会话服务与状态机，UI 只展示状态和上报手势。随机牌序与正逆位在服务层生成，用户选择只决定已生成牌序中的位置，动画不参与业务随机性。

**Tech Stack:** HarmonyOS Stage Model, API 24, ArkTS, ArkUI, Hypium, Hvigor, bundled resources, Preferences.

---

## 视频观察结论

视频长度约 61.6 秒、竖屏 576×1280。可确认的流程如下：

| 时间 | 观察到的阶段 | 可迁移的交互 |
| --- | --- | --- |
| 0–8 秒 | 问题输入后进入牌阵选择，并出现推荐加载/推荐结果 | 先理解问题，再高亮推荐牌阵；用户仍可自行选择 |
| 8–18 秒 | 展示三牌阵说明，随后选择牌组 | 用简短图示说明牌位；当前项目只有一套合法牌组，不增加无意义的单选页面 |
| 18–25 秒 | 洗牌、切牌 | 洗牌支持轻触与长按；切牌用水平拖动或按钮完成 |
| 25–55 秒 | 按牌位逐张选牌，每次先选择、再确认、再翻牌 | 扇形牌背、已抽牌槽位、可重选、确认后翻牌并锁定 |
| 55–61 秒 | 可选补充信息，然后开始解读 | 提供本地文本补充与明确跳过入口；不申请麦克风权限 |

视频没有展示最终解读页、错误态、后台恢复、平板布局和无障碍状态，因此本计划不从视频臆测这些行为，继续沿用项目既有规格。

## 方案选择

- **方案 A：逐页复刻参考应用。** 还原度最高，但会引入只有一套牌时仍强制选牌组、浅色视觉替换现有品牌、流程过长等问题。
- **方案 B：迁移交互机制，保留本项目产品边界（采用）。** 三牌阵完整经历推荐、洗牌、切牌、逐张抽取和补充信息；单牌与每日抽牌走更短路径。深蓝星夜视觉、离线牌库和本地解读保持不变。
- **方案 C：只增加动画。** 改动小，但用户仍是一键出结果，无法获得视频中“我参与了抽牌”的核心感受。

采用方案 B。目标是获得相同的参与感和节奏，不复制参考应用的品牌、文案、牌背、牌面或其他专有素材。

## 目标流程

```text
普通抽牌入口
  -> 输入问题（可跳过）
  -> 选择牌阵（本地推荐，可改选）
  -> 洗牌
  -> 切牌（三牌阵必经；单牌可跳过）
  -> 按牌位逐张选择、确认、翻牌
  -> 补充信息（可跳过）
  -> 本地解读结果

每日灵感入口
  -> 简短洗牌
  -> 选择一张
  -> 当日本地固定结果
```

## 文件地图

- Modify: `entry/src/main/ets/models/TarotModels.ets` — 增加补充信息与牌阵定义类型。
- Create: `entry/src/main/ets/models/DrawFlowModels.ets` — 抽牌步骤、会话和 UI 快照类型。
- Modify: `entry/src/main/ets/models/TarotAppState.ets` — 用显式状态机替代页面字符串的自由跳转。
- Create: `entry/src/main/ets/services/DrawSessionService.ets` — 洗牌、切牌、选牌和去重的纯业务逻辑。
- Create: `entry/src/main/ets/services/SpreadRecommendationService.ets` — 根据本地问题分类推荐牌阵。
- Modify: `entry/src/main/ets/services/InterpretationService.ets` — 纳入用户补充信息与动态牌位。
- Modify: `entry/src/main/ets/common/DesignTokens.ets` — 集中动画、牌尺寸、扇形和进度条令牌。
- Create: `entry/src/main/ets/components/draw/DrawProgress.ets` — 五段进度指示器。
- Create: `entry/src/main/ets/components/draw/SpreadRecommendationCard.ets` — 推荐牌阵卡。
- Create: `entry/src/main/ets/components/draw/ShufflePile.ets` — 轻触/长按洗牌视觉。
- Create: `entry/src/main/ets/components/draw/CutDeck.ets` — 拖动切牌视觉。
- Create: `entry/src/main/ets/components/draw/CardFan.ets` — 稳定尺寸的扇形牌背选择器。
- Create: `entry/src/main/ets/components/draw/DrawnCardSlots.ets` — 当前牌位和已抽牌状态。
- Create: `entry/src/main/ets/components/draw/SelectedCardPreview.ets` — 选中确认与翻牌展示。
- Create: `entry/src/main/ets/pages/DrawFlowPage.ets` — 只负责编排状态、动画和组件回调。
- Modify: `entry/src/main/ets/pages/Index.ets` — 保留应用壳与其他页面，将抽牌流程委托给 `DrawFlowPage`。
- Modify: `entry/src/main/resources/base/element/string.json` — 新增全部抽牌流程可见文本。
- Modify: `entry/src/main/resources/base/element/float.json` — 新增牌宽高、点击区和内容最大宽度。
- Create: `entry/src/ohosTest/ets/test/DrawSessionService.test.ets` — 会话随机、切牌、选择与去重测试。
- Create: `entry/src/ohosTest/ets/test/SpreadRecommendationService.test.ets` — 推荐规则测试。
- Modify: `entry/src/ohosTest/ets/test/AppState.test.ets` — 合法/非法状态迁移与后台恢复测试。
- Modify: `entry/src/ohosTest/ets/test/InterpretationService.test.ets` — 补充信息和动态牌位测试。
- Modify: `entry/src/ohosTest/ets/test/List.test.ets` — 注册新测试。

### Task 1: 固化会话模型和状态机

**Files:**
- Create: `entry/src/main/ets/models/DrawFlowModels.ets`
- Modify: `entry/src/main/ets/models/TarotAppState.ets`
- Modify: `entry/src/ohosTest/ets/test/AppState.test.ets`

- [ ] **Step 1: 先写失败的状态迁移测试**

```typescript
const state: TarotAppState = new TarotAppState();
state.startDraw();
expect(state.drawStep).assertEqual('question');
expect(state.goNext()).assertFalse();
state.submitQuestion('我该如何推进当前计划？');
expect(state.drawStep).assertEqual('spread');
state.chooseSpread('three');
expect(state.drawStep).assertEqual('shuffle');
expect(state.beginAnimation()).assertTrue();
expect(state.beginAnimation()).assertFalse();
state.onBackground();
expect(state.animationRunning).assertFalse();
```

- [ ] **Step 2: 运行测试构建并确认失败**

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry@ohosTest -p product=default -p buildMode=debug assembleHap --no-daemon
```

Expected: FAIL，提示 `drawStep`、`startDraw` 或新迁移方法尚不存在。

- [ ] **Step 3: 增加明确的状态与会话类型**

```typescript
export type DrawFlowStep =
  'question' | 'spread' | 'shuffle' | 'cut' | 'pick' | 'supplement' | 'result';

export interface SessionCard {
  cardId: string;
  orientation: Orientation;
}

export interface DrawSession {
  remaining: SessionCard[];
  selected: DrawnCard[];
  cutIndex: number;
}
```

`TarotAppState` 只允许相邻合法迁移；动画中拒绝再次前进。`onBackground()` 只结束临时动画并保留已确认的牌，不自动抽牌或跳到结果页。

- [ ] **Step 4: 运行测试并提交**

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p module=entry@ohosTest -p product=default -p buildMode=debug assembleHap --no-daemon
git add entry/src/main/ets/models entry/src/ohosTest/ets/test/AppState.test.ets
git commit -m "feat: define staged tarot draw state"
```

Expected: test HAP 构建成功；状态迁移测试通过。

### Task 2: 实现可复现的牌序、切牌和逐张选择

**Files:**
- Create: `entry/src/main/ets/services/DrawSessionService.ets`
- Create: `entry/src/ohosTest/ets/test/DrawSessionService.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`

- [ ] **Step 1: 先写失败的会话测试**

```typescript
const session: DrawSession = DrawSessionService.create(ids, true, seededRandom);
expect(session.remaining.length).assertEqual(78);
expect(new Set(session.remaining.map((item: SessionCard): string => item.cardId)).size)
  .assertEqual(78);
const cut: DrawSession = DrawSessionService.cut(session, 17);
expect(cut.remaining[0].cardId).assertEqual(session.remaining[17].cardId);
const picked: DrawSession = DrawSessionService.pick(cut, 5, '背景线索');
expect(picked.selected.length).assertEqual(1);
expect(picked.remaining.length).assertEqual(77);
expect(picked.remaining.some((item: SessionCard): boolean =>
  item.cardId === picked.selected[0].cardId)).assertFalse();
```

- [ ] **Step 2: 实现纯服务**

```typescript
export class DrawSessionService {
  static create(cardIds: string[], reversalsEnabled: boolean,
    random: () => number = Math.random): DrawSession;
  static cut(session: DrawSession, rawIndex: number): DrawSession;
  static pick(session: DrawSession, rawIndex: number, position: string): DrawSession;
}
```

`create` 使用 Fisher–Yates 生成 78 张唯一牌序，并在服务层预分配正逆位；`cut` 旋转牌序；`pick` 返回新对象并从 `remaining` 移除已选牌。UI 不直接调用 `Math.random()`。

- [ ] **Step 3: 覆盖边界并运行测试**

测试空牌库、越界切牌、越界选择、关闭逆位、三次选择不重复。运行 Task 1 的 Hypium 构建命令，Expected: PASS。

- [ ] **Step 4: 提交**

```powershell
git add entry/src/main/ets/services/DrawSessionService.ets entry/src/ohosTest/ets/test
git commit -m "feat: add interactive draw session service"
```

### Task 3: 增加本地牌阵推荐，不增加伪牌组选择

**Files:**
- Modify: `entry/src/main/ets/models/TarotModels.ets`
- Create: `entry/src/main/ets/services/SpreadRecommendationService.ets`
- Create: `entry/src/ohosTest/ets/test/SpreadRecommendationService.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`

- [ ] **Step 1: 写推荐规则测试**

```typescript
expect(SpreadRecommendationService.recommend('decision').id).assertEqual('three');
expect(SpreadRecommendationService.recommend('relationship').positions[2])
  .assertEqual('沟通方向');
expect(SpreadRecommendationService.recommend('daily').id).assertEqual('daily');
```

- [ ] **Step 2: 定义数据驱动牌阵**

```typescript
export interface SpreadDefinition {
  id: SpreadType;
  title: string;
  description: string;
  positions: string[];
}
```

关系问题使用“我的视角 / 互动焦点 / 沟通方向”；选择问题使用“背景线索 / 当前阻力 / 下一步建议”；其他三牌问题使用“过去影响 / 当下焦点 / 行动建议”。推荐结果只高亮，不自动替用户确认。

- [ ] **Step 3: 保留单一合法牌组边界**

在牌阵页展示“经典韦特 · 78 张 · 本地牌库”的只读说明，不新增只有一个选项的牌组页面。只有取得第二套完整、授权明确、78 张一一映射的牌面后，才启用牌组选择。

- [ ] **Step 4: 运行测试并提交**

```powershell
git add entry/src/main/ets/models/TarotModels.ets entry/src/main/ets/services/SpreadRecommendationService.ets entry/src/ohosTest/ets/test
git commit -m "feat: recommend offline tarot spreads"
```

### Task 4: 抽离抽牌页并资源化可见文本

**Files:**
- Create: `entry/src/main/ets/pages/DrawFlowPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `entry/src/main/resources/base/element/float.json`
- Modify: `entry/src/main/ets/common/DesignTokens.ets`

- [ ] **Step 1: 把抽牌流程从单体 `Index.ets` 抽出**

`Index.ets` 继续持有应用壳、设置和持久化入口；`DrawFlowPage` 接收设置与完成回调，不直接访问 Preferences：

```typescript
@Component
export struct DrawFlowPage {
  reversalsEnabled: boolean = true;
  soundEnabled: boolean = true;
  hapticEnabled: boolean = true;
  onComplete: (context: ReadingContext) => void = (): void => {};
}
```

- [ ] **Step 2: 资源化新增文案和尺寸**

新增 `draw_step_question`、`draw_step_spread`、`draw_step_shuffle`、`draw_step_cut`、`draw_step_pick`、`draw_step_supplement`、`draw_shuffle_title`、`draw_shuffle_hint`、`draw_shuffle_again`、`draw_cut_title`、`draw_cut_hint`、`draw_cut_auto`、`draw_pick_title`、`draw_pick_position`、`draw_confirm_card`、`draw_reselect_card`、`draw_supplement_title`、`draw_supplement_hint`、`draw_skip_to_reading`、`draw_deck_name`、`draw_deck_description`、`draw_exit_confirm_title` 和 `draw_exit_confirm_message`。例如标题使用 `$r('app.string.draw_shuffle_title')`；固定牌尺寸和页面宽度使用资源或 `DesignTokens`。

- [ ] **Step 3: 固定响应式约束**

Phone 内容宽度为 `100%` 减安全边距；tablet 内容最大宽度 720vp。卡背维持 2:3 比例；所有图标按钮同时提供文字/无障碍说明，点击区不小于 48vp。

- [ ] **Step 4: 构建并提交**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
git add entry/src/main/ets/pages entry/src/main/ets/common entry/src/main/resources/base/element
git commit -m "refactor: isolate tarot draw flow page"
```

Expected: static gate and debug build exit 0；抽牌页不直接读写持久化。

### Task 5: 实现进度、洗牌和切牌交互

**Files:**
- Create: `entry/src/main/ets/components/draw/DrawProgress.ets`
- Create: `entry/src/main/ets/components/draw/ShufflePile.ets`
- Create: `entry/src/main/ets/components/draw/CutDeck.ets`
- Modify: `entry/src/main/ets/pages/DrawFlowPage.ets`

- [ ] **Step 1: 建立稳定布局**

顶部使用五段进度条；洗牌区只渲染 18–24 张复用牌背，不渲染 78 个大图。组件使用固定高度和 2:3 牌比例，洗牌次数变化不得推动标题或底部按钮位移。

- [ ] **Step 2: 实现轻触和长按洗牌**

```typescript
.gesture(
  GestureGroup(GestureMode.Parallel,
    TapGesture().onAction((): void => this.shuffleOnce()),
    LongPressGesture({ repeat: true, duration: 260 })
      .onAction((): void => this.shuffleOnce())
  )
)
```

每次只更新预先计算的偏移/旋转数组；动画 220–320ms。洗牌视觉不改变 `DrawSession` 牌序，防止 UI 动画承担业务随机性。

- [ ] **Step 3: 实现拖动切牌**

`PanGesture` 将横向位移归一化为 `1..remaining.length - 1` 的切牌索引；松手前只预览上下两叠偏移，松手后调用 `DrawSessionService.cut()` 并播放合拢动画。另提供“自动切一次”按钮作为无障碍和手势失败兜底。

- [ ] **Step 4: 加入动画互斥和后台恢复**

动画期间禁用主 CTA 与重复手势；进入后台时清除长按重复状态、完成当前视觉复位，但不丢失已确认选择。

- [ ] **Step 5: 构建并提交**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
git add entry/src/main/ets/components/draw entry/src/main/ets/pages/DrawFlowPage.ets
git commit -m "feat: add shuffle and cut interactions"
```

### Task 6: 实现扇形选牌、确认和逐张翻牌

**Files:**
- Create: `entry/src/main/ets/components/draw/CardFan.ets`
- Create: `entry/src/main/ets/components/draw/DrawnCardSlots.ets`
- Create: `entry/src/main/ets/components/draw/SelectedCardPreview.ets`
- Modify: `entry/src/main/ets/pages/DrawFlowPage.ets`

- [ ] **Step 1: 生成稳定扇形布局**

```typescript
export interface FanCardLayout {
  index: number;
  angle: number;
  translateX: number;
  translateY: number;
  zIndex: number;
}
```

Phone 显示 22 张可点击牌背，tablet 可显示 28 张；布局由容器宽度和索引计算，同一次选择过程中不随机抖动。由于会话牌 ID 唯一，每张牌直接使用 `item.cardId` 作为稳定 key。

- [ ] **Step 2: 实现两段式选择**

第一次点击只抬起并高亮候选牌，底部 CTA 变为“确定选这张”；点击其他牌允许重选。确认后先调用 `DrawSessionService.pick()`，再播放 260–360ms 的 Y 轴翻转揭示；动画中不接受第二次确认。

- [ ] **Step 3: 顺序推进牌位**

三牌阵顶部槽位依次显示“待选择 / 当前选择 / 已揭示”。确认一张后将其缩放移动到对应槽位，再进入下一牌位；第三张完成后进入补充信息。单牌与每日抽牌只出现一个槽位。

- [ ] **Step 4: 处理正逆位和重新开始**

正逆位只来自 `SessionCard.orientation`；翻开后按 0°/180°展示。已确认的牌不能返回扇形。退出流程需使用确认对话框，确认后丢弃内存会话，不写历史。

- [ ] **Step 5: 构建并提交**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
git add entry/src/main/ets/components/draw entry/src/main/ets/pages/DrawFlowPage.ets
git commit -m "feat: add sequential tarot card picking"
```

### Task 7: 接入可选补充信息和本地解读

**Files:**
- Modify: `entry/src/main/ets/models/TarotModels.ets`
- Modify: `entry/src/main/ets/services/InterpretationService.ets`
- Modify: `entry/src/main/ets/pages/DrawFlowPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/ohosTest/ets/test/InterpretationService.test.ets`

- [ ] **Step 1: 先写失败的解读测试**

```typescript
const context: ReadingContext = {
  question: '我该如何推进当前计划？',
  supplement: '我最担心时间不够',
  category: 'decision',
  recentThemes: [],
  cards: [{ cardId: 'major-17', orientation: 'upright', position: '背景线索' }]
};
const result: ReadingResult = InterpretationService.build(context, [SAMPLE_CARD]);
expect(result.summary.includes('时间')).assertTrue();
expect(result.sections[0].position).assertEqual('背景线索');
```

- [ ] **Step 2: 增加可选字段并安全纳入解读**

```typescript
export interface ReadingContext {
  question: string;
  supplement?: string;
  category: QuestionCategory;
  mood?: string;
  recentThemes: string[];
  cards: DrawnCard[];
}
```

补充信息最多 160 字，先经过现有 `SafetyService`，只在本地用于摘要和行动建议，不自动传给小艺、不新增长期画像。

- [ ] **Step 3: 提供清晰的跳过路径**

页面包含“补充更多信息（可选）”文本框和“跳过，直接开始解读”主按钮。V1 不申请 `MICROPHONE`；用户需要语音时可使用系统输入法自带的语音输入。

- [ ] **Step 4: 结果生成时机**

最后一次确认翻牌完成后只保留 `ReadingContext`；用户提交或跳过补充信息时，`Index.ets` 调用 `InterpretationService.build()` 并切换结果页。重复点击必须只生成一次结果。

- [ ] **Step 5: 运行测试、构建并提交**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
git add entry/src/main/ets/models entry/src/main/ets/services/InterpretationService.ets entry/src/main/ets/pages entry/src/ohosTest/ets/test
git commit -m "feat: include optional draw context in readings"
```

### Task 8: 触感反馈、性能和无障碍收口

**Files:**
- Create: `entry/src/main/ets/services/HapticService.ets`
- Modify: `entry/src/main/ets/pages/DrawFlowPage.ets`
- Modify: `entry/src/main/ets/components/draw/*.ets`
- Modify: `entry/src/main/ets/common/DesignTokens.ets`

- [ ] **Step 1: 隔离触感服务**

洗牌、切牌、选中和翻牌完成分别使用轻量触感；设置关闭或系统调用失败时静默降级，不影响会话状态。UI 组件只调用 `onShuffle`、`onCut`、`onSelect`，不直接访问系统能力。

- [ ] **Step 2: 统一动画令牌**

定义 `MOTION_FAST = 180`、`MOTION_NORMAL = 280`、`MOTION_REVEAL = 360`；低性能设备减少阴影和同时运动的牌数，不降低交互点击区。

- [ ] **Step 3: 完成可访问性约束**

所有牌背提供“第 N 张可选塔罗牌”，已选牌提供“牌位、牌名、正逆位”；切牌和洗牌均有按钮替代手势；字体放大时标题和说明允许换行，主 CTA 不使用固定单行字号缩放。

- [ ] **Step 4: 构建并提交**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
git add entry/src/main/ets/services/HapticService.ets entry/src/main/ets/components/draw entry/src/main/ets/pages/DrawFlowPage.ets entry/src/main/ets/common/DesignTokens.ets
git commit -m "fix: polish draw feedback and accessibility"
```

### Task 9: 回归、设备 QA 和文档闭环

**Files:**
- Modify: `tasks.md`
- Modify: `changes.md`
- Modify: `design-qa.md` only after observed target-device/emulator results
- Create: `docs/qa/draw-flow-checklist.md`

- [ ] **Step 1: 运行自动门禁**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug -Clean
```

Expected: 两条命令退出 0，生成新的 debug HAP。

- [ ] **Step 2: 审计边界**

```powershell
rg -n "Math\.random|MICROPHONE|INTERNET|password|secret|token" entry/src/main entry/src/ohosTest
rg -n "Text\('|Button\('|placeholder: '" entry/src/main/ets/pages/DrawFlowPage.ets entry/src/main/ets/components/draw
```

Expected: 抽牌 UI 不直接使用 `Math.random()`；没有新增网络、麦克风或秘密；新增可见中文全部来自字符串资源。

- [ ] **Step 3: 在 HarmonyOS phone 模拟器/真机逐项观察**

验证问题跳过、推荐可改选、长按洗牌、自动切牌、拖动切牌、候选重选、重复确认拦截、三张不重复、正逆位、后台恢复、补充信息跳过、结果保存和再次抽牌。保存每个关键阶段截图。

- [ ] **Step 4: 检查 tablet 与文本韧性**

验证 720vp 最大内容宽度、横屏、1.3× 字体、最长牌位文案、160 字补充信息和 TalkBack/无障碍说明；未实际观察的项目保持 `blocked`，不得写成 `passed`。

- [ ] **Step 5: 回填记录并提交**

```powershell
git add tasks.md changes.md design-qa.md docs/qa/draw-flow-checklist.md
git commit -m "docs: record staged draw flow verification"
```

## 验收标准

- 三牌阵完整具备推荐、洗牌、切牌、逐张选择、确认、翻牌、可选补充和解读衔接。
- 单牌与每日灵感不被迫经历无意义的全部步骤；每日结果仍同日本地固定。
- 所有抽牌业务随机性位于服务层，UI 动画和触点不直接生成牌 ID 或正逆位。
- 动画中重复点击无效，切后台后不会重复抽牌、跳页或丢失已确认牌。
- 78 张牌、问题、补充信息、结果和记录保持离线；不新增登录、广告、付费、网络或麦克风权限。
- 参考视频的交互节奏被吸收，但应用继续使用现有星夜品牌和已授权素材。
- 静态门禁、Hypium test HAP 和 debug HAP 构建通过；只有观察到的设备结果写入 `design-qa.md`。

## Self-review

- Spec coverage: 覆盖视频中可观察的推荐、洗牌、切牌、逐张选牌、翻牌、补充信息，并明确视频未展示的范围。
- Scope: 不增加第二牌组、语音权限、在线推荐或品牌重做；单牌/每日路径保持精简。
- Type consistency: `DrawFlowStep`、`DrawSession`、`SessionCard`、`SpreadDefinition`、`ReadingContext.supplement` 在模型、服务、UI 和测试中名称一致。
- Boundary consistency: 页面不访问数据库，动画不负责随机，解读仍由服务层生成。
- Placeholder scan: 未发现占位标记或未定义的延后实施步骤。
