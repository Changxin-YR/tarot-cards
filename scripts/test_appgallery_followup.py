from __future__ import annotations

import unittest
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class AppGalleryFollowupTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.index = (ROOT / 'entry/src/main/ets/pages/Index.ets').read_text(encoding='utf-8')
        cls.bottom_navigation = (
            ROOT / 'entry/src/main/ets/components/BottomNavigation.ets'
        ).read_text(encoding='utf-8')
        cls.local_app_store = (
            ROOT / 'entry/src/main/ets/repositories/LocalAppStore.ets'
        ).read_text(encoding='utf-8')
        cls.tokens = (ROOT / 'entry/src/main/ets/common/DesignTokens.ets').read_text(encoding='utf-8')
        cls.strings = (ROOT / 'entry/src/main/resources/base/element/string.json').read_text(encoding='utf-8')

    def test_platform_privacy_hosting_does_not_show_a_second_startup_gate(self) -> None:
        self.assertNotIn('ComplianceGate', self.index)
        self.assertNotIn('ComplianceService', self.index)
        self.assertNotIn('showCompliance', self.index)

    def test_settings_does_not_display_or_package_the_privacy_declaration(self) -> None:
        self.assertNotIn('privacy_policy_title', self.index)
        self.assertNotIn('privacy_policy_body', self.index)
        self.assertNotIn('privacy_policy_title', self.strings)
        self.assertNotIn('privacy_policy_body', self.strings)
        self.assertIn('user_agreement_title', self.index)

    def test_feedback_is_wired_to_each_reading_milestone(self) -> None:
        self.assertIn('ReadingFeedbackService', self.index)
        self.assertIn("this.feedback.emit('shuffle', this.soundEnabled, this.hapticEnabled)", self.index)
        self.assertIn("this.feedback.emit('selection', this.soundEnabled, this.hapticEnabled)", self.index)
        self.assertIn("this.feedback.emit('reveal', this.soundEnabled, this.hapticEnabled)", self.index)
        self.assertTrue((ROOT / 'entry/src/main/resources/rawfile/reading_feedback.wav').is_file())

    def test_sound_is_disabled_by_default_without_overwriting_saved_preferences(self) -> None:
        self.assertIn("soundValue = await this.store.get('sound', false);", self.local_app_store)
        self.assertIn(
            "soundEnabled: typeof soundValue === 'boolean' ? soundValue : false,",
            self.local_app_store,
        )
        self.assertIn('@State soundEnabled: boolean = false;', self.index)
        self.assertIn('    this.soundEnabled = false;\n    this.hapticEnabled = true;', self.index)

    def test_native_feedback_waits_for_sound_pool_readiness(self) -> None:
        feedback = (ROOT / 'entry/src/main/ets/services/ReadingFeedbackService.ets').read_text(encoding='utf-8')
        self.assertIn("pool.on('loadComplete'", feedback)
        self.assertIn('await loadComplete', feedback)
        self.assertIn('this.soundLoadState.readySoundId()', feedback)

    def test_native_feedback_load_error_does_not_block_app_initialization(self) -> None:
        feedback = (ROOT / 'entry/src/main/ets/services/ReadingFeedbackService.ets').read_text(encoding='utf-8')
        self.assertIn("pool.on('error'", feedback)
        self.assertIn('reject(error)', feedback)
        self.assertIn('failedPool.release()', feedback)
        self.assertNotIn('await this.feedbackPort.initialize(context)', self.index)
        self.assertIn('this.feedbackPort.initialize(context).catch', self.index)

    def test_native_feedback_keeps_rapid_taps_immediate_without_replaying_stale_actions(self) -> None:
        feedback = (ROOT / 'entry/src/main/ets/services/ReadingFeedbackService.ets').read_text(encoding='utf-8')
        self.assertIn('private static readonly MAX_CONCURRENT_STREAMS: number = 2;', feedback)
        self.assertIn('media.createSoundPool(NativeReadingFeedbackPort.MAX_CONCURRENT_STREAMS', feedback)
        self.assertIn('private static readonly CLICK_PLAY_PARAMETERS', feedback)
        self.assertIn('this.soundPool.play(soundId, NativeReadingFeedbackPort.CLICK_PLAY_PARAMETERS)', feedback)

    def test_native_feedback_uses_the_documented_short_sound_mixing_path(self) -> None:
        feedback = (ROOT / 'entry/src/main/ets/services/ReadingFeedbackService.ets').read_text(encoding='utf-8')
        self.assertIn('usage: audio.StreamUsage.STREAM_USAGE_MUSIC', feedback)
        self.assertNotIn('STREAM_USAGE_GAME', feedback)
        self.assertNotIn('WARM_UP_PLAY_PARAMETERS', feedback)
        self.assertNotIn("AppLogger.error('NativeReadingFeedbackPort', 'warmUp'", feedback)

    def test_feedback_asset_is_short_gentle_pcm_without_late_start(self) -> None:
        asset_path = ROOT / 'entry/src/main/resources/rawfile/reading_feedback.wav'
        with wave.open(str(asset_path), 'rb') as asset:
            self.assertEqual(asset.getnchannels(), 1)
            self.assertEqual(asset.getsampwidth(), 2)
            self.assertEqual(asset.getframerate(), 48000)
            frame_count = asset.getnframes()
            samples = struct.unpack('<' + 'h' * frame_count, asset.readframes(frame_count))

        self.assertGreaterEqual(len(samples), 4320)
        self.assertLessEqual(len(samples), 5280)
        self.assertLess(next(index for index, value in enumerate(samples) if value != 0), 240)
        self.assertGreater(max(abs(value) for value in samples), 1200)
        self.assertLessEqual(max(abs(value) for value in samples), 7000)

    def test_shared_navigation_and_setting_rows_use_explicit_alignment_tracks(self) -> None:
        self.assertIn('static readonly NAV_ICON_HEIGHT', self.tokens)
        self.assertIn('static readonly NAV_LABEL_HEIGHT', self.tokens)
        self.assertIn('.alignItems(VerticalAlign.Center)', self.bottom_navigation)
        self.assertIn('.alignItems(VerticalAlign.Center)', self.index)

    def test_active_bottom_navigation_icon_has_a_clear_compact_affordance(self) -> None:
        self.assertIn('.backgroundColor(this.currentPage === target ? DesignTokens.PURPLE_DEEP : Color.Transparent)', self.bottom_navigation)
        self.assertIn('.borderRadius(DesignTokens.RADIUS_MEDIUM)', self.bottom_navigation)
        self.assertIn('.fontWeight(FontWeight.Medium)', self.bottom_navigation)

    def test_root_navigation_does_not_animate_selected_icon_state(self) -> None:
        self.assertIn('this.page = this.navigationService.selectRoot(page);', self.index)
        self.assertNotIn('this.transitionTo(this.navigationService.selectRoot(page));', self.index)
        self.assertIn('.transition(TransitionEffect.OPACITY.animation({ duration: 180, curve: Curve.EaseOut }))', self.index)

    def test_bottom_navigation_uses_a_shared_square_icon_box(self) -> None:
        self.assertIn('static readonly NAV_ICON_HEIGHT: number = 36;', self.tokens)
        self.assertIn('static readonly NAV_ICON_SIZE: number = 24;', self.tokens)
        self.assertIn('static readonly NAV_LABEL_FONT_SIZE: number = 11;', self.tokens)
        self.assertIn('.width(DesignTokens.NAV_ICON_SIZE)', self.bottom_navigation)
        self.assertIn('.height(DesignTokens.NAV_ICON_SIZE)', self.bottom_navigation)
        self.assertIn('Stack({ alignContent: Alignment.Center })', self.bottom_navigation)
        self.assertIn('Image(icon)', self.bottom_navigation)
        self.assertIn('.objectFit(ImageFit.Contain)', self.bottom_navigation)
        self.assertIn('.fontSize(DesignTokens.NAV_LABEL_FONT_SIZE)', self.bottom_navigation)
        for icon_name in ('nav_home', 'nav_draw', 'nav_catalog', 'nav_profile'):
            self.assertTrue((ROOT / f'entry/src/main/resources/base/media/{icon_name}.svg').is_file())


if __name__ == '__main__':
    unittest.main()
