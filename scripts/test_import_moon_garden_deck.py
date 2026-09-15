import tempfile
import unittest
import json
from pathlib import Path

from PIL import Image

from import_moon_garden_deck import (
    BACK_SOURCE,
    OUTPUT_SIZE,
    SOURCE_GROUPS,
    EXPECTED_CARD_IDS,
    extract_cards,
    split_horizontal_cards,
    validate_moon_garden_assets,
)


SOURCE_ROOT = Path(r"C:\Users\27363\Desktop\塔罗牌")
PROJECT_ROOT = Path(__file__).resolve().parents[1]
MEDIA_ROOT = PROJECT_ROOT / "entry" / "src" / "main" / "resources" / "base" / "media"


class MoonGardenImportTest(unittest.TestCase):
    def test_expected_order_contains_all_78_standard_cards(self) -> None:
        self.assertEqual(78, len(EXPECTED_CARD_IDS))
        self.assertEqual(78, len(set(EXPECTED_CARD_IDS)))
        self.assertEqual("major-00", EXPECTED_CARD_IDS[0])
        self.assertEqual("wands-01", EXPECTED_CARD_IDS[22])
        self.assertEqual("cups-01", EXPECTED_CARD_IDS[36])
        self.assertEqual("swords-01", EXPECTED_CARD_IDS[50])
        self.assertEqual("pentacles-01", EXPECTED_CARD_IDS[64])

    def test_source_groups_cover_faces_and_one_embedded_back(self) -> None:
        face_ids = [card_id for group in SOURCE_GROUPS for card_id in group.card_ids]
        self.assertEqual(78, len(face_ids))
        self.assertEqual(set(EXPECTED_CARD_IDS), set(face_ids))
        self.assertEqual(("card_back",), BACK_SOURCE.card_ids)

    def test_horizontal_source_sheet_supports_four_and_five_cards(self) -> None:
        for source_name in ("560e774b-04f5-46d2-a23a-3cc498716941.png", "4169d8c5-117f-4b86-8670-bbb01e0dd40e.png"):
            with Image.open(SOURCE_ROOT / source_name) as source:
                cards = split_horizontal_cards(source)
            self.assertIn(len(cards), (4, 5))
            self.assertTrue(all(card.height > 600 for card in cards))

    def test_project_moon_garden_assets_are_complete_and_readable(self) -> None:
        validate_moon_garden_assets(MEDIA_ROOT)

    def test_extraction_normalizes_each_card_to_fixed_size(self) -> None:
        with Image.open(SOURCE_ROOT / "4169d8c5-117f-4b86-8670-bbb01e0dd40e.png") as source:
            result = extract_cards(source, 5)
        self.assertEqual(5, len(result))
        self.assertTrue(all(card.size == OUTPUT_SIZE for card in result))

    def test_theme_mapping_contains_every_moon_garden_resource(self) -> None:
        mapping = (PROJECT_ROOT / "entry/src/main/ets/common/TarotThemeMedia.ets").read_text(encoding="utf-8")
        for card_id in EXPECTED_CARD_IDS:
            resource_name = f"app.media.moon_garden_{card_id.replace('-', '_')}"
            self.assertIn(resource_name, mapping)
        self.assertIn("app.media.moon_garden_card_back", mapping)

    def test_stained_glass_theme_display_name_is_liuxing_qiongting(self) -> None:
        strings = json.loads(
            (PROJECT_ROOT / "entry/src/main/resources/base/element/string.json").read_text(encoding="utf-8")
        )
        values = {item["name"]: item["value"] for item in strings["string"]}
        self.assertEqual("鎏星穹庭", values["theme_stained_glass"])


if __name__ == "__main__":
    unittest.main()
