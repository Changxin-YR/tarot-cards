# 音效混音与柔化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让抽牌短音效使用 SoundPool 的混音路径、替换为轻柔且无明显起声延迟的离线资源，并统一首页底部导航图标的视觉承载尺寸。

**Architecture:** `NativeReadingFeedbackPort` 继续拥有预加载的双路 `SoundPool`，仅将 renderer usage 改为 SDK 声明支持短音混音的 `STREAM_USAGE_MUSIC`，同时移除零音量 warm-up。`reading_feedback.wav` 继续由该服务加载，但改为短促、低峰值的 48 kHz PCM 资源；`BottomNavigation` 用固定方形承载区将现有 Unicode 图标居中，`Index.ets` 的反馈事件、设置分流和导航路由不变。

**Tech Stack:** HarmonyOS Stage、ArkTS、`@kit.AudioKit`、`@kit.MediaKit`、Python `unittest`、Hypium、Hvigor。

---

### Task 1: 锁定混音和音色契约

**Files:**
- Modify: `scripts/test_appgallery_followup.py`
- Test: `scripts/test_appgallery_followup.py`

- [x] **Step 1: 写入失败的 SoundPool 混音回归**

```python
def test_native_feedback_uses_the_documented_short_sound_mixing_path(self) -> None:
    feedback = (ROOT / 'entry/src/main/ets/services/ReadingFeedbackService.ets').read_text(encoding='utf-8')
    self.assertIn('usage: audio.StreamUsage.STREAM_USAGE_MUSIC', feedback)
    self.assertNotIn('STREAM_USAGE_GAME', feedback)
    self.assertNotIn('WARM_UP_PLAY_PARAMETERS', feedback)
    self.assertNotIn("AppLogger.error('NativeReadingFeedbackPort', 'warmUp'", feedback)
```

- [x] **Step 2: 写入失败的 wav 参数回归**

```python
def test_feedback_asset_is_short_gentle_pcm_without_late_start(self) -> None:
    with wave.open(str(ROOT / 'entry/src/main/resources/rawfile/reading_feedback.wav'), 'rb') as asset:
        self.assertEqual(asset.getnchannels(), 1)
        self.assertEqual(asset.getsampwidth(), 2)
        self.assertEqual(asset.getframerate(), 48000)
        samples = struct.unpack('<' + 'h' * asset.getnframes(), asset.readframes(asset.getnframes()))
    self.assertGreaterEqual(len(samples), 4320)
    self.assertLessEqual(len(samples), 5280)
    self.assertLess(next(index for index, value in enumerate(samples) if value != 0), 240)
    self.assertGreater(max(abs(value) for value in samples), 1200)
    self.assertLessEqual(max(abs(value) for value in samples), 7000)
```

- [x] **Step 3: 写入失败的底部导航图标尺寸回归**

```python
def test_bottom_navigation_uses_a_shared_square_icon_box(self) -> None:
    self.assertIn('static readonly NAV_ICON_HEIGHT: number = 36;', self.tokens)
    self.assertIn('.width(DesignTokens.NAV_ICON_HEIGHT)', self.bottom_navigation)
    self.assertIn('.height(DesignTokens.NAV_ICON_HEIGHT)', self.bottom_navigation)
    self.assertIn('Stack({ alignContent: Alignment.Center })', self.bottom_navigation)
    self.assertIn('.fontSize(22)', self.bottom_navigation)
```

- [x] **Step 4: 运行专项回归，确认它因旧用途、预热、资源格式和图标承载尺寸失败**

Run: `python scripts/test_appgallery_followup.py`

Expected: FAIL，因为服务仍包含 `STREAM_USAGE_GAME` 和 `WARM_UP_PLAY_PARAMETERS`，资源仍为 22050 Hz，导航图标承载区仍为 36×28vp 的文本框。

### Task 2: 使用混音路径并更新离线音效

**Files:**
- Modify: `entry/src/main/ets/services/ReadingFeedbackService.ets`
- Modify: `entry/src/main/resources/rawfile/reading_feedback.wav`
- Modify: `entry/src/main/ets/components/BottomNavigation.ets`
- Modify: `entry/src/main/ets/common/DesignTokens.ets`

- [x] **Step 1: 保持资源就绪和并发策略，仅切换短音混音用途**

```ts
const pool: media.SoundPool = await media.createSoundPool(NativeReadingFeedbackPort.MAX_CONCURRENT_STREAMS, {
  usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
  rendererFlags: 0
});
```

删除 `WARM_UP_PLAY_PARAMETERS` 及 `loadComplete` 后的零音量 `pool.play()` 调用。保留 `CLICK_PLAY_PARAMETERS`、`loadComplete` 等待、`SoundPoolLoadState` 和播放失败日志。

- [x] **Step 2: 生成轻柔的短 wav 资源**

生成 48 kHz、16-bit、单声道、96 ms 的 PCM WAV：以 523 Hz 与 784 Hz 的低幅度泛音混合为主体，4 ms 淡入、自然衰减，峰值不超过 7000，且首个有效采样在前 5 ms。资源仅写入 `entry/src/main/resources/rawfile/reading_feedback.wav`。

- [x] **Step 3: 将导航字形置于共享方形承载区**

```ts
Stack({ alignContent: Alignment.Center }) {
  Text(icon)
    .fontSize(this.iconSizeFor(target))
    .textAlign(TextAlign.Center)
}
.width(DesignTokens.NAV_ICON_HEIGHT)
.height(DesignTokens.NAV_ICON_HEIGHT)
.backgroundColor(this.currentPage === target ? DesignTokens.PURPLE_DEEP : Color.Transparent)
```

将 `DesignTokens.NAV_ICON_HEIGHT` 从 `28` 调整为 `36`，并新增集中令牌：首页/抽取为 `22`、卡片库为 `21`、我的为 `19`。`iconSizeFor()` 按入口返回相应令牌，保留当前颜色、圆角、标签轨道、导航高度和点击回调。

- [x] **Step 4: 运行专项回归，确认混音、资源和导航图标契约通过**

Run: `python scripts/test_appgallery_followup.py`

Expected: PASS，所有专项断言通过。

### Task 3: 完整验证和任务闭环

**Files:**
- Modify: `tasks.md`
- Modify: `changes.md`
- Test: `scripts/check-standard.ps1`
- Test: `scripts/build-harmony.ps1`

- [x] **Step 1: 执行静态门禁与变更检查**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
git diff --check
```

Expected: 两个命令均以 0 退出；若完整门禁受已记录的外部检查器缺失影响，记录实际失败原因，不将其归因于本次改动。

- [x] **Step 2: 构建应用与测试 HAP**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --mode module -p product=default -p module=entry@ohosTest -p buildMode=debug
```

Expected: ArkTS 类型检查、资源处理、签名和打包成功。

- [x] **Step 3: 记录可证实结果**

将 `T-20260805-007` 更新为 `done`，写入通过的专项回归和构建命令；仅在实际设备上完成十次洗牌、选牌和翻牌的听感复测后，才更新 `design-qa.md`。
