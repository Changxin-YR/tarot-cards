# 双主题牌面全量替换与离线解读 V3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将用户提供的玫瑰粉金、紫黑金素材稳定导入为两套各 78 张牌面，并交付更贴合问题、能分析多牌关系且完整解释澄清牌的离线解读 V3。

**Architecture:** 素材侧使用显式 JSON 清单驱动裁切、去边、归一化和资源映射生成，校验器同时检查完整性、重复和黑边。业务侧保持页面只负责状态编排，由关系分析服务和解读服务接收分离的主牌/澄清牌，生成结构化 `ReadingResult`；本地编码升级为 TR4 并兼容 TR3 与旧记录。

**Tech Stack:** HarmonyOS Stage、ArkTS/ArkUI、Hypium、Python 3、Pillow、PowerShell、Preferences。

---

## 文件结构

- Create: `scripts/tlp_deck_manifest.json`：156 张正面与两张牌背的来源文件、裁切区域和输出 ID。
- Create: `scripts/import_tlp_decks.py`：清单驱动的裁切、去边、等比归一化、联系表和媒体映射生成器。
- Create: `scripts/test_import_tlp_decks.py`：资源导入的纯 Python 回归测试。
- Modify: `scripts/validate-theme-assets.ps1`：校验尺寸、解码、完整性并调用 Python 深度校验。
- Modify: `scripts/check-standard.ps1`：把资源导入测试与主题校验接入标准门禁。
- Modify: `entry/src/main/ets/common/TarotThemeMedia.ets`：由脚本重新生成 156 个强类型资源分支。
- Modify: `entry/src/main/ets/common/DesignTokens.ets`：集中定义牌面 3:5 比例和最大宽度。
- Modify: `entry/src/main/ets/models/TarotModels.ets`：增加多牌关系和结构化澄清解读类型，`ReadingContext` 分离澄清牌。
- Create: `entry/src/main/ets/services/ReadingRelationshipService.ets`：分析正逆位转折、牌组集中、花色和元素关系。
- Modify: `entry/src/main/ets/services/InterpretationService.ets`：组合问题焦点、逐牌、多牌关系与澄清解读，输出算法版本 3。
- Modify: `entry/src/main/ets/repositories/LocalDataCodec.ets`：新增 TR4 编解码和 TR3 兼容路径。
- Modify: `entry/src/main/ets/pages/Index.ets`：分开传递主牌/澄清牌，并呈现独立澄清解读区域。
- Modify: `entry/src/main/resources/base/element/string.json`：增加澄清解读标题、字段标签和无障碍文本。
- Modify: `entry/src/ohosTest/ets/test/InterpretationService.test.ets`：覆盖 V3、稳定输出和澄清牌行为。
- Create: `entry/src/ohosTest/ets/test/ReadingRelationshipService.test.ets`：覆盖多牌关系规则。
- Modify: `entry/src/ohosTest/ets/test/LocalDataCodec.test.ets`：覆盖 TR4 往返、TR3 兼容和损坏数据拒绝。
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`：注册新增测试套件。
- Modify: `scripts/test_bottom_navigation_layout.py`：增加牌面比例和澄清结果布局静态断言。
- Modify: `changes.md`、`design-qa.md`、`tasks.md`：回填实现与实际验证结果。

## Task 1：建立素材清单与失败门禁

**Files:**
- Create: `scripts/tlp_deck_manifest.json`
- Create: `scripts/test_import_tlp_decks.py`
- Test: `scripts/test_import_tlp_decks.py`

- [ ] **Step 1: 建立清单格式和选择规则**

清单根对象使用以下完整结构；`cards` 最终必须包含每个主题 78 个唯一 `cardId`，`backs` 每个主题一个。所有 `source` 使用相对 `C:\Users\27363\Desktop\tlp` 的文件名，禁止复制绝对路径进项目。

```json
{
  "sourceRoot": "C:/Users/27363/Desktop/tlp",
  "outputSize": [600, 1000],
  "themes": {
    "moon_garden": "rose_gold",
    "stained_glass": "violet_black_gold"
  },
  "cards": [
    {
      "themeId": "moon_garden",
      "cardId": "major-00",
      "source": "6f7db5a7-1535-4fa5-b71a-98a13b28506b.png",
      "rect": [12, 16, 390, 690]
    }
  ],
  "backs": [
    {
      "themeId": "moon_garden",
      "source": "d9f6eae1-97a4-4990-9a70-db9641785ef9.png",
      "rect": [1277, 522, 245, 500]
    }
  ]
}
```

选择时以牌面可见中文标题和编号为准：月影花庭只选粉色牌，星璃穹顶只选紫黑金牌；同名候选优先选择边框、色调与各自五牌长图一致的版本；`d9f6...` 第六列只作为牌背；任何同名候选只能进入清单一次。裁切坐标在生成的联系表上逐张复核后写入清单，不使用 OCR 结果直接决定牌 ID。

- [ ] **Step 2: 写入失败测试**

`scripts/test_import_tlp_decks.py` 先导入尚未存在的模块，并断言 78 张、标准牌 ID、3:5 输出和无重复：

```python
from pathlib import Path

from import_tlp_decks import expected_card_ids, load_manifest, validate_manifest


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "scripts" / "tlp_deck_manifest.json"


def main() -> int:
    payload = load_manifest(MANIFEST)
    validate_manifest(payload)
    expected = expected_card_ids()
    for theme_id in ("moon_garden", "stained_glass"):
        ids = [item["cardId"] for item in payload["cards"] if item["themeId"] == theme_id]
        assert ids == expected, f"{theme_id} card order or completeness mismatch"
        assert len(set(ids)) == 78, f"{theme_id} contains duplicate card ids"
    assert payload["outputSize"] == [600, 1000]
    print("TLP deck manifest tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 3: 运行并观察预期失败**

Run: `python scripts/test_import_tlp_decks.py`

Expected: FAIL，错误为 `ModuleNotFoundError: No module named 'import_tlp_decks'`。

- [ ] **Step 4: 完成 156 张清单并复跑测试**

按 `major-00..major-21`、`wands-01..14`、`cups-01..14`、`swords-01..14`、`pentacles-01..14` 顺序录入两套清单。此时模块仍未实现，测试应继续在导入处失败；清单自身用 `Get-Content -Raw ... | ConvertFrom-Json` 验证为合法 JSON。

Run: `Get-Content -Raw -Encoding UTF8 scripts/tlp_deck_manifest.json | ConvertFrom-Json | Out-Null`

Expected: exit code 0。

## Task 2：实现无拉伸牌面导入和资源审计

**Files:**
- Create: `scripts/import_tlp_decks.py`
- Modify: `scripts/test_import_tlp_decks.py`
- Modify: `scripts/validate-theme-assets.ps1`
- Modify: `scripts/check-standard.ps1`
- Generate: `entry/src/main/resources/base/media/moon_garden_*.jpg`
- Generate: `entry/src/main/resources/base/media/stained_glass_*.jpg`
- Generate: `entry/src/main/ets/common/TarotThemeMedia.ets`

- [ ] **Step 1: 实现清单与裁切核心**

`scripts/import_tlp_decks.py` 提供以下接口。`trim_uniform_border()` 只裁去与四角背景连续相近的边缘，最多裁掉任一方向 12%，避免误删深色牌面；`fit_cover()` 等比缩放并中心裁切到 600x1000，禁止改变横纵缩放比。

```python
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageStat


THEMES = ("moon_garden", "stained_glass")
SUITS = ("wands", "cups", "swords", "pentacles")
OUTPUT_SIZE = (600, 1000)


def expected_card_ids() -> list[str]:
    ids = [f"major-{index:02d}" for index in range(22)]
    for suit in SUITS:
        ids.extend(f"{suit}-{index:02d}" for index in range(1, 15))
    return ids


def load_manifest(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_manifest(payload: dict[str, Any]) -> None:
    if tuple(payload.get("outputSize", [])) != OUTPUT_SIZE:
        raise AssertionError("outputSize must be 600x1000")
    expected = expected_card_ids()
    for theme_id in THEMES:
        ids = [item["cardId"] for item in payload["cards"] if item["themeId"] == theme_id]
        if ids != expected:
            raise AssertionError(f"{theme_id} must contain the ordered 78-card catalog")
        if len({(item["source"], tuple(item["rect"])) for item in payload["cards"]
                if item["themeId"] == theme_id}) != 78:
            raise AssertionError(f"{theme_id} reuses a source crop")
    if sorted(item["themeId"] for item in payload["backs"]) != sorted(THEMES):
        raise AssertionError("each theme must contain one back")


def fit_cover(image: Image.Image, size: tuple[int, int] = OUTPUT_SIZE) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()
```

- [ ] **Step 2: 实现输出、感知哈希和映射生成**

为脚本增加 `extract_entry()`、8x8 灰度 dHash、边缘黑带占比检查、JPEG 输出和 `TarotThemeMedia.ets` 生成。执行时先把所有结果写入系统临时目录；只有 158 张全部通过后才逐文件覆盖项目媒体资源，从而避免半套资源落盘。跨套同 `cardId` 可以题材相同，但 dHash 不得完全相等；任意主题内 dHash 不得重复。

- [ ] **Step 3: 扩展测试并验证通过**

在 `scripts/test_import_tlp_decks.py` 增加临时图像测试：

```python
from PIL import Image
from tempfile import TemporaryDirectory


def test_fit_cover_preserves_content_ratio() -> None:
    source = Image.new("RGB", (300, 500), (240, 100, 120))
    result = fit_cover(source)
    assert result.size == (600, 1000)


def test_duplicate_hash_is_rejected() -> None:
    with TemporaryDirectory() as value:
        root = Path(value)
        first = root / "a.jpg"
        second = root / "b.jpg"
        Image.new("RGB", (600, 1000), "white").save(first)
        Image.new("RGB", (600, 1000), "white").save(second)
        assert perceptual_hash(first) == perceptual_hash(second)
```

Run: `python scripts/test_import_tlp_decks.py`

Expected: `TLP deck manifest tests passed.`

- [ ] **Step 4: 生成资源与联系表**

Run: `python scripts/import_tlp_decks.py --manifest scripts/tlp_deck_manifest.json --contact-sheet docs/qa/tlp-deck-contact-sheet.jpg`

Expected: `Generated 156 card faces, 2 backs, and TarotThemeMedia.ets.`

逐张检查联系表：标题与 ID 对应、两套色系正确、无黑边、无明显截字、无重复。发现问题时只调整清单坐标或候选来源并重新生成，不手工编辑输出 JPEG。

- [ ] **Step 5: 接入标准门禁**

在 `scripts/validate-theme-assets.ps1` 把期望尺寸改为 600x1000，并在尾部调用：

```powershell
python (Join-Path $PSScriptRoot 'test_import_tlp_decks.py')
if ($LASTEXITCODE -ne 0) {
  throw "TLP deck asset validation failed with exit code $LASTEXITCODE"
}
```

在 `scripts/check-standard.ps1` 的 HarmonyOS 规范检查后调用 `validate-theme-assets.ps1`。运行：

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-theme-assets.ps1`

Expected: 两套各 78 张和一个牌背全部通过。

## Task 3：统一全应用牌面比例和无边框表现

**Files:**
- Modify: `entry/src/main/ets/common/DesignTokens.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `scripts/test_bottom_navigation_layout.py`

- [ ] **Step 1: 写入失败静态断言**

在 `scripts/test_bottom_navigation_layout.py` 读取 `Index.ets` 与 `DesignTokens.ets`，增加：

```python
assert "CARD_ASPECT_RATIO: number = 0.6" in tokens, "card ratio must match 600x1000 assets"
assert ".aspectRatio(DesignTokens.CARD_ASPECT_RATIO)" in index, "card images must share one ratio"
assert ".border({ width:" not in card_face_blocks, "card faces must not draw visible borders"
```

Run: `python scripts/test_bottom_navigation_layout.py`

Expected: FAIL，提示缺少统一牌面比例。

- [ ] **Step 2: 增加设计令牌并替换冲突尺寸**

在 `DesignTokens` 增加：

```typescript
static readonly CARD_ASPECT_RATIO: number = 0.6;
static readonly CARD_RADIUS: number = 6;
static readonly CARD_MAX_WIDTH: number = 180;
```

将 `Index.ets` 中所有正面牌图的固定宽高对改为“稳定宽度或网格宽度 + `.aspectRatio(DesignTokens.CARD_ASPECT_RATIO)`”；牌背也使用同一比例。删除正面牌的明显描边，选中状态改由外层位置偏移、阴影或独立选择指示表达，不能改变图片盒尺寸。

- [ ] **Step 3: 运行布局门禁**

Run: `python scripts/test_bottom_navigation_layout.py`

Expected: `Bottom navigation and safe-area layout checks passed.`

## Task 4：建立多牌关系分析服务

**Files:**
- Create: `entry/src/main/ets/services/ReadingRelationshipService.ets`
- Create: `entry/src/ohosTest/ets/test/ReadingRelationshipService.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`

- [ ] **Step 1: 写失败测试**

测试使用三个显式样本牌，分别覆盖逆位转正位、同花色加强和大阿卡纳集中：

```typescript
it('describesOrientationTurnAndSuitPattern', 0, () => {
  const insight: RelationshipInsight = ReadingRelationshipService.analyze(
    [
      { cardId: 'cups-05', orientation: 'reversed', position: '过去' },
      { cardId: 'cups-08', orientation: 'upright', position: '现在' },
      { cardId: 'major-17', orientation: 'upright', position: '行动建议' }
    ],
    [CUPS_FIVE, CUPS_EIGHT, STAR]
  );
  expect(insight.patterns.includes('orientation_turn')).assertTrue();
  expect(insight.patterns.includes('suit_cluster')).assertTrue();
  expect(insight.text.includes('从')).assertTrue();
});
```

在 `List.test.ets` 注册 `readingRelationshipServiceTest()`。

- [ ] **Step 2: 运行 ohosTest 编译并观察失败**

Run: `& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --mode module -p product=default -p module=entry@ohosTest -p buildMode=debug`

Expected: FAIL，提示找不到 `ReadingRelationshipService` 或 `RelationshipInsight`。

- [ ] **Step 3: 实现强类型关系分析**

服务公开以下接口：

```typescript
export type RelationshipPattern =
  'orientation_turn' | 'suit_cluster' | 'major_focus' | 'element_support' | 'neutral_sequence';

export interface RelationshipInsight {
  patterns: RelationshipPattern[];
  text: string;
}

export class ReadingRelationshipService {
  static analyze(cards: DrawnCard[], catalog: TarotCard[]): RelationshipInsight;
}
```

实现优先级固定为正逆位转折、同花色聚集、大阿卡纳集中、相邻元素支持，均无匹配时返回 `neutral_sequence`。只使用 `DrawnCard` 和 `TarotCard` 数据，不读取页面状态，不使用 `any`、对象展开或动态属性访问。

- [ ] **Step 4: 重新构建测试包**

Run: `& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --mode module -p product=default -p module=entry@ohosTest -p buildMode=debug`

Expected: `entry@ohosTest` HAP 编译成功。

## Task 5：升级解读 V3 并独立解释澄清牌

**Files:**
- Modify: `entry/src/main/ets/models/TarotModels.ets`
- Modify: `entry/src/main/ets/services/InterpretationService.ets`
- Modify: `entry/src/ohosTest/ets/test/InterpretationService.test.ets`

- [ ] **Step 1: 写入 V3 与澄清牌失败测试**

增加一个主牌和两个澄清牌的测试，断言主牌 section 数量不变且每张澄清解读字段完整：

```typescript
it('explainsClarificationsWithoutMixingThemIntoMainSections', 0, () => {
  const result: ReadingResult = InterpretationService.build({
    question: '我该如何推进这个停滞的项目？',
    category: 'workStudy',
    recentThemes: [],
    cards: [{ cardId: 'major-17', orientation: 'upright', position: '核心提示' }],
    clarifications: [
      { cardId: 'cups-05', orientation: 'reversed', position: '澄清 1' },
      { cardId: 'cups-08', orientation: 'upright', position: '澄清 2' }
    ],
    scene: 'career',
    depth: 'deep'
  }, [STAR, CUPS_FIVE, CUPS_EIGHT]);

  expect(result.sections.length).assertEqual(1);
  expect(result.sections[0].meaning.includes('可以利用')).assertTrue();
  expect(result.sections[0].meaning.includes('需要留意')).assertTrue();
  expect((result.clarificationReadings ?? []).length).assertEqual(2);
  expect(result.clarificationReadings?.[0].focus.length > 0).assertTrue();
  expect(result.clarificationReadings?.[0].meaning.length > 0).assertTrue();
  expect(result.clarificationReadings?.[0].impact.length > 0).assertTrue();
  expect(result.clarificationReadings?.[0].action.length > 0).assertTrue();
  expect(result.clarificationReadings?.[1].impact.includes('上一张')).assertTrue();
  expect(result.algorithmVersion).assertEqual(3);
});
```

再增加稳定性测试：对同一 `ReadingContext` 连续调用两次，断言 `summary`、`connection`、`action`、`reflection` 和澄清解读完全相等。

- [ ] **Step 2: 扩充模型并观察类型失败**

在 `TarotModels.ets` 增加：

```typescript
export type ClarificationImpactType = 'reinforce' | 'supplement' | 'caution' | 'adjust';

export interface ClarificationReading {
  cardId: string;
  cardName: string;
  orientation: Orientation;
  index: number;
  focus: string;
  meaning: string;
  impactType: ClarificationImpactType;
  impact: string;
  action: string;
}
```

`ReadingContext` 增加 `clarifications?: DrawnCard[]`，`ReadingResult` 增加 `clarificationReadings?: ClarificationReading[]`。

Run: `& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --mode module -p product=default -p module=entry@ohosTest -p buildMode=debug`

Expected: FAIL，现有 `InterpretationService` 尚未生成 `clarificationReadings`，新增测试不通过。

- [ ] **Step 3: 重写 V3 组合流程**

`InterpretationService.build()` 只用 `context.cards` 生成 `sections` 和主牌关系；使用 `ReadingRelationshipService.analyze()` 生成多牌联系。新增私有方法：

```typescript
private static buildClarifications(
  context: ReadingContext,
  catalog: TarotCard[],
  mainSections: CardReadingSection[]
): ClarificationReading[];

private static stableIndex(seed: string, length: number): number;

private static impactType(
  main: CardReadingSection,
  clarification: DrawnCard,
  card: TarotCard
): ClarificationImpactType;

private static strengthText(side: TarotMeaningSide, lens: SceneLens): string;

private static challengeText(side: TarotMeaningSide, lens: SceneLens): string;
```

`strengthText` 使用正逆位的第二、第三关键词及场景 `strength` 生成“可以利用”的具体力量；`challengeText` 使用第一关键词及场景 `caution` 生成“需要留意”的具体阻碍。两段必须进入每张主牌的 `meaning`，且正逆位使用不同关键词，不能只复制同一通用句。

`stableIndex` 使用字符码累加的非负整数取模选择已有 action/reflection seed；不得使用 `Date.now()` 或 `Math.random()`。第一张澄清牌从主牌中的逆位、阻碍或最后一个行动位置选择焦点；后续澄清牌在 `impact` 中明确引用“上一张澄清牌”。所有输出经过 `SafetyService.soften()`，算法版本设为 3。

- [ ] **Step 4: 运行测试包构建**

Run: `& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --mode module -p product=default -p module=entry@ohosTest -p buildMode=debug`

Expected: Hypium 测试源码编译成功，InterpretationService 既有 V2 行为测试调整为期望版本 3 后通过编译。

## Task 6：持久化 TR4 并兼容旧记录

**Files:**
- Modify: `entry/src/main/ets/repositories/LocalDataCodec.ets`
- Modify: `entry/src/ohosTest/ets/test/LocalDataCodec.test.ets`

- [ ] **Step 1: 写入 TR4 往返和 TR3 兼容失败测试**

构造含一个 `ClarificationReading` 的记录，经 `encodeRecords()`/`decodeRecords()` 后断言 `focus`、`impactType`、`impact` 和 `action` 完整保留。保留现有硬编码 TR3 用例并断言其 `clarificationReadings` 为 `undefined`。

- [ ] **Step 2: 运行测试包构建并观察失败**

Run: `& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --mode module -p product=default -p module=entry@ohosTest -p buildMode=debug`

Expected: FAIL，新结构尚未被编码或解码。

- [ ] **Step 3: 实现版本化编解码**

在 `LocalDataCodec` 中保留 `TR3:` 常量并新增：

```typescript
private static readonly RECORD_VERSION_PREFIX: string = 'TR4:';
private static readonly RECORD_VERSION_3_PREFIX: string = 'TR3:';
private static readonly CLARIFICATION_SEPARATOR: string = '|~A~|';
private static readonly CLARIFICATION_FIELD_SEPARATOR: string = '|~B~|';
```

TR4 在现有 19 个字段末尾追加编码后的 `clarificationReadings`。`decodeRecords()` 先识别 TR4，再识别 TR3，最后进入旧格式路径。澄清字段严格校验 9 个字段、合法 `orientation`、合法 `impactType` 和有限整数 `index`；任一行损坏时整包抛错，不返回部分结果。

- [ ] **Step 4: 验证编解码测试编译**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-harmony.ps1 -BuildMode test`

Expected: 测试包编译成功，旧记录测试不需更改保存内容。

## Task 7：接入页面状态和澄清解读 UI

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/resources/base/element/string.json`
- Modify: `scripts/test_bottom_navigation_layout.py`

- [ ] **Step 1: 写入页面静态失败断言**

在布局门禁中断言页面不再调用 `updateReading(this.drawn.concat(this.clarifications))`，并要求存在 `clarificationReadings` 状态和资源化标题：

```python
assert "this.drawn.concat(this.clarifications)" not in index
assert "@State clarificationReadings: ClarificationReading[] = []" in index
assert "app.string.clarification_focus" in index
assert "app.string.clarification_impact" in index
assert "app.string.clarification_action" in index
```

Run: `python scripts/test_bottom_navigation_layout.py`

Expected: FAIL，提示页面仍混合主牌和澄清牌。

- [ ] **Step 2: 修改页面数据流**

`updateReading()` 固定接收主牌数组，并构造：

```typescript
const context: ReadingContext = {
  question: this.question,
  category: this.category,
  mood: this.mood,
  recentThemes: this.deriveRecentThemes(),
  cards: this.drawn,
  clarifications: this.clarifications,
  scene: this.readingScene,
  depth: this.readingDepth
};
```

`finishReveal()` 添加澄清牌后调用 `this.updateReading(this.drawn)`；新主牌流程清空 `clarificationReadings`。把 `result.clarificationReadings ?? []` 保存到 `@State`，并在 `saveCurrent()` 中写入 `ReadingResult`。

- [ ] **Step 3: 增加用户可见字符串**

向 `string.json` 增加：

```json
{ "name": "clarification_reading_title", "value": "澄清解读" },
{ "name": "clarification_focus", "value": "澄清焦点" },
{ "name": "clarification_meaning", "value": "这张牌的提示" },
{ "name": "clarification_impact", "value": "对原解读的影响" },
{ "name": "clarification_action", "value": "下一步提示" }
```

- [ ] **Step 4: 重做结果页澄清区域**

将现有仅牌图 `Row` 替换为 `ForEach(this.clarificationReadings, ...)` 的全宽内容带。每项使用左侧固定宽度、3:5 比例牌图，右侧展示牌名/正逆位和四段资源化标签；窄屏时用垂直布局，文字 `maxLines` 不限制。不得使用卡片嵌套卡片，不为牌面添加边框。

- [ ] **Step 5: 运行静态门禁**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-standard.ps1`

Expected: HarmonyOS 规范、资源、牌面比例、安全区和澄清布局全部通过。

## Task 8：运行完整自动验证和 API 22 设备验收

**Files:**
- Modify: `changes.md`
- Modify: `design-qa.md`
- Modify: `tasks.md`
- Generate: `docs/qa/screenshots/2026-08-02-theme-moon-catalog.jpeg`
- Generate: `docs/qa/screenshots/2026-08-02-theme-glass-catalog.jpeg`
- Generate: `docs/qa/screenshots/2026-08-02-clarification-reading.jpeg`

- [ ] **Step 1: 运行完整静态与资源门禁**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-standard.ps1
python scripts/validate_tarot_catalog.py
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-theme-assets.ps1
git diff --check
```

Expected: 全部 exit code 0；`git diff --check` 允许报告工作区既有 LF/CRLF 提示，但不得有空白错误。

- [ ] **Step 2: 构建 debug 与 ohosTest HAP**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-harmony.ps1 -BuildMode debug
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --mode module -p product=default -p module=entry@ohosTest -p buildMode=debug
```

Expected: ArkTS 类型检查、debug HAP 和 `entry@ohosTest` HAP 均成功；只允许项目既有未签名与 `LocalAppStore` 异常处理警告。

- [ ] **Step 3: 在 API 22 phone 模拟器运行 Hypium**

使用 `C:\Users\27363\Desktop\max\openharmony-sdk\default\openharmony\toolchains\hdc.exe -t 127.0.0.1:5555` 明确选择 phone，安装 debug 与测试 HAP并运行测试能力。

Expected: `Failure: 0, Error: 0`，新增关系、V3、澄清牌和 TR4 用例全部计入通过数。

- [ ] **Step 4: 设备端视觉与流程验收**

在 1320x2856 API 22 phone 上逐项观察并截图：

1. 月影花庭牌库显示粉色牌面，卡图无黑边、无拉伸、无明显描边。
2. 星璃穹顶牌库显示紫黑金牌面，同一卡位切换主题后资源同步变化。
3. 完成三牌抽取，逐牌图像比例一致，多牌联系包含真实转折或呼应。
4. 连续抽取两张澄清牌，每张显示焦点、牌义、影响和下一步，第二张解释与上一张关系。
5. 保存后从灵感记录回看，澄清解读仍完整；旧记录能够打开。
6. 顶部状态栏、底部 TabBar 与系统手势区继续无重叠，页面无侧边滚动条。

- [ ] **Step 5: 回填文档并完成任务**

`changes.md` 记录实现和自动验证；`design-qa.md` 只写 Step 4 实际观察到的设备结果，未观察的 tablet、横屏和字体放大继续标为受限验收。全部必需门禁和 phone 验收通过后，把 `tasks.md` 中 `T-20260802-004` 状态从 `in_progress` 改为 `done`。

## 执行约束

- 当前工作区已有用户改动，所有步骤必须保留并适配这些改动，不得重置或回退无关文件。
- 不复制相邻工程的签名配置，不输出证书、口令或用户数据。
- 生产代码修改必须在对应失败测试已经观察后进行。
- 计划中的提交仅在用户明确要求提交时执行；否则以逐任务 `git diff` 和验证结果作为检查点。
