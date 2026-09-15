import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ReviewRemediationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tokens = (ROOT / 'entry/src/main/ets/common/DesignTokens.ets').read_text(encoding='utf-8')
        cls.index = (ROOT / 'entry/src/main/ets/pages/Index.ets').read_text(encoding='utf-8')
        cls.ability = (ROOT / 'entry/src/main/ets/entryability/EntryAbility.ets').read_text(encoding='utf-8')
        cls.safety = (ROOT / 'entry/src/main/ets/services/SafetyService.ets').read_text(encoding='utf-8')
        cls.reading_records = (ROOT / 'entry/src/main/ets/services/ReadingRecordService.ets').read_text(encoding='utf-8')
        cls.module = (ROOT / 'entry/src/main/module.json5').read_text(encoding='utf-8')
        cls.profile = (ROOT / 'build-profile.json5').read_text(encoding='utf-8')
        cls.strings = json.loads(
            (ROOT / 'entry/src/main/resources/base/element/string.json').read_text(encoding='utf-8')
        )

    def test_primary_and_gold_tokens_have_distinct_semantics(self) -> None:
        self.assertIn('static readonly PRIMARY:', self.tokens)
        self.assertIn('static readonly ACCENT_GOLD:', self.tokens)
        self.assertNotRegex(self.tokens, r'static readonly GOLD(?:_LIGHT)?:')

    def test_visible_progress_uses_resources(self) -> None:
        self.assertIn("$r('app.string.shuffle_progress', this.shuffleCount)", self.index)
        self.assertRegex(self.index, r"\$r\(\s*'app\.string\.selected_count'")
        self.assertNotIn('Text(`已洗牌', self.index)
        self.assertNotIn('Text(`已选', self.index)
        self.assertNotIn("return ['今日灵感']", self.index)
        self.assertNotIn('? [`澄清 ${', self.index)
        self.assertNotIn('return `第 ${this.history.length', self.index)

    def test_mood_options_have_stable_key(self) -> None:
        pattern = re.compile(
            r'ForEach\(MOOD_OPTIONS,[\s\S]*?\},\s*\(item:\s*\[Resource, string\]\):\s*string\s*=>\s*item\[1\]\)'
        )
        self.assertRegex(self.index, pattern)

    def test_remaining_review_items_have_regression_coverage(self) -> None:
        names = {item['name'] for item in self.strings['string']}
        required = {
            'question_length_counter', 'question_limit_reached', 'question_quote',
            'card_image_accessibility', 'card_back_accessibility',
            'candidate_card_accessibility', 'history_empty_image_accessibility'
        }
        self.assertTrue(required.issubset(names))
        self.assertIn("$r('app.string.question_limit_reached')", self.index)
        self.assertIn("$r('app.string.question_length_counter', this.question.length)", self.index)
        self.assertEqual(self.index.count("$r('app.string.question_quote', this.question)"), 2)
        self.assertGreaterEqual(self.index.count('card_image_accessibility'), 6)
        self.assertGreaterEqual(self.index.count("$r('app.string.card_back_accessibility')"), 6)
        self.assertIn("$r('app.string.candidate_card_accessibility', index + 1)", self.index)
        self.assertIn("$r('app.string.history_empty_image_accessibility')", self.index)

    def test_static_option_lists_have_explicit_stable_keys(self) -> None:
        scene_key = re.compile(
            r'ForEach\(SCENE_OPTIONS\.slice\(0, 3\),[\s\S]*?\},\s*'
            r'\(item:\s*\[Resource, ReadingScene\]\):\s*string\s*=>\s*item\[1\]\)'
        )
        scene_tail_key = re.compile(
            r'ForEach\(SCENE_OPTIONS\.slice\(3\),[\s\S]*?\},\s*'
            r'\(item:\s*\[Resource, ReadingScene\]\):\s*string\s*=>\s*item\[1\]\)'
        )
        catalog_key = re.compile(
            r'ForEach\(CATALOG_FILTERS,[\s\S]*?\},\s*'
            r'\(item:\s*\[string, Resource\]\):\s*string\s*=>\s*item\[0\]\)'
        )
        self.assertRegex(self.index, scene_key)
        self.assertRegex(self.index, scene_tail_key)
        self.assertRegex(self.index, catalog_key)

    def test_no_empty_catch_blocks_remain(self) -> None:
        sources = [self.index, self.ability]
        for source in sources:
            self.assertNotRegex(source, r'catch(?:\s*\([^)]*\))?\s*\{\s*\}')
            self.assertNotRegex(source, r'\.catch\(\([^)]*\):\s*void\s*=>\s*\{\s*\}\)')

    def test_corrupted_storage_has_a_confirmed_recovery_path(self) -> None:
        names = {item['name'] for item in self.strings['string']}
        required = {
            'recover_local_data_action', 'recover_local_data_title',
            'recover_local_data_message', 'recover_local_data_confirm'
        }
        self.assertTrue(required.issubset(names))
        self.assertIn('private confirmRecoverFromInitializationFailure()', self.index)
        self.assertIn('private async recoverFromInitializationFailure()', self.index)
        self.assertIn('await this.appDataService.clearAll()', self.index)
        self.assertIn("$r('app.string.recover_local_data_action')", self.index)
        self.assertIn('this.initializationFailed = true', self.index)
        self.assertIn('this.initializationFailed = false', self.index)

    def test_reading_record_queue_logs_and_recovers_from_failures(self) -> None:
        self.assertIn("import { AppLogger } from '../common/AppLogger';", self.reading_records)
        self.assertIn(
            "AppLogger.error('ReadingRecordService', 'queuedOperation', error)",
            self.reading_records
        )

    def test_responsive_layout_remains_connected_without_a_duplicate_privacy_gate(self) -> None:
        self.assertTrue((ROOT / 'entry/src/main/ets/common/ResponsiveLayout.ets').is_file())
        self.assertFalse((ROOT / 'entry/src/main/ets/services/ComplianceService.ets').exists())
        self.assertFalse((ROOT / 'entry/src/main/ets/components/ComplianceGate.ets').exists())
        self.assertIn('ResponsiveLayout.', self.index)
        self.assertNotIn('ComplianceGate(', self.index)

    def test_page_transition_and_singleton_launch_are_explicit(self) -> None:
        self.assertIn('.transition(', self.index)
        self.assertRegex(self.module, r'"launchType"\s*:\s*"singleton"')

    def test_api_22_baseline_is_preserved(self) -> None:
        self.assertRegex(self.profile, r'"compatibleSdkVersion"\s*:\s*"6\.0\.2\(22\)"')
        self.assertRegex(self.profile, r'"targetSdkVersion"\s*:\s*"6\.0\.2\(22\)"')

    def test_required_policy_resources_exist(self) -> None:
        names = {item['name'] for item in self.strings['string']}
        required = {
            'user_agreement_title', 'user_agreement_body', 'clarification_position',
            'candidate_card_position'
        }
        self.assertTrue(required.issubset(names))

    def test_only_clear_all_resets_local_settings_without_a_compliance_gate(self) -> None:
        clear_records = self.index.split('private async clearRecords()', 1)[1].split(
            'private confirmClearRecords()', 1
        )[0]
        clear_all = self.index.split('private async clearAllLocalData()', 1)[1].split(
            'private confirmClearAllLocalData()', 1
        )[0]
        self.assertNotIn('ComplianceGate', clear_records)
        self.assertIn('this.resetAfterClearingLocalData()', clear_all)
        self.assertNotIn('showCompliance', self.index)

    def test_high_risk_coverage_includes_immediate_harm_and_medication(self) -> None:
        for term in ('伤害自己', '停药', '官司', '买哪只股票'):
            self.assertIn(term, self.safety)


if __name__ == '__main__':
    unittest.main()
