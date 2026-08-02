import tempfile
import unittest
from pathlib import Path

from PIL import Image

from import_tlp_decks import (
    OUTPUT_SIZE,
    SOURCE_GROUPS,
    expected_card_ids,
    fit_cover,
    normalize_existing_decks,
    perceptual_hash,
    split_horizontal_cards,
    trim_uniform_border,
    validate_output_decks,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MEDIA_ROOT = PROJECT_ROOT / "entry" / "src" / "main" / "resources" / "base" / "media"


class TlpDeckImportTest(unittest.TestCase):
    def test_expected_card_ids_are_the_standard_ordered_78(self) -> None:
        expected = (
            [f"major-{number:02d}" for number in range(22)]
            + [f"wands-{number:02d}" for number in range(1, 15)]
            + [f"cups-{number:02d}" for number in range(1, 15)]
            + [f"swords-{number:02d}" for number in range(1, 15)]
            + [f"pentacles-{number:02d}" for number in range(1, 15)]
        )
        self.assertEqual(expected, expected_card_ids())

    def test_uniform_side_borders_are_trimmed_before_cover_resize(self) -> None:
        source = Image.new("RGB", (400, 600), (5, 5, 5))
        content = Image.new("RGB", (300, 600), (210, 90, 130))
        source.paste(content, (50, 0))

        trimmed = trim_uniform_border(source)
        result = fit_cover(trimmed)

        self.assertLessEqual(trimmed.width, 304)
        self.assertEqual(OUTPUT_SIZE, result.size)
        self.assertEqual((210, 90, 130), result.getpixel((0, 500)))
        self.assertEqual((210, 90, 130), result.getpixel((599, 500)))

    def test_horizontal_source_sheet_is_split_into_five_cards(self) -> None:
        source = Image.new("RGB", (550, 180), "white")
        for index in range(5):
            card = Image.new("RGB", (90, 160), (40 + index * 30, 30, 70))
            source.paste(card, (10 + index * 108, 10))

        cards = split_horizontal_cards(source)

        self.assertEqual(5, len(cards))
        self.assertTrue(all(card.height >= 158 for card in cards))

    def test_source_groups_map_fifty_unique_cards_per_theme(self) -> None:
        for theme_id in ("moon_garden", "stained_glass"):
            mapped = [card_id for group in SOURCE_GROUPS[theme_id] for card_id in group[1]]
            self.assertEqual(50, len(mapped))
            self.assertEqual(50, len(set(mapped)))
            self.assertEqual(expected_card_ids()[:50], mapped)

    def test_normalization_is_atomic_and_keeps_unique_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as value:
            root = Path(value)
            for theme_index, theme_id in enumerate(("moon_garden", "stained_glass")):
                for card_index, card_id in enumerate(expected_card_ids()):
                    image = Image.new(
                        "RGB",
                        (400, 600),
                        ((card_index * 19) % 255, (theme_index * 80 + card_index * 7) % 255, 130),
                    )
                    image.save(root / f"{theme_id}_{card_id.replace('-', '_')}.jpg")
                Image.new("RGB", (400, 600), (20 + theme_index * 80, 30, 40)).save(
                    root / f"{theme_id}_card_back.jpg"
                )

            normalize_existing_decks(root)
            validate_output_decks(root)
            first = root / "moon_garden_major_00.jpg"
            second = root / "moon_garden_major_01.jpg"
            with Image.open(first) as image:
                self.assertEqual(OUTPUT_SIZE, image.size)
            self.assertNotEqual(perceptual_hash(first), perceptual_hash(second))

    def test_project_decks_are_complete_normalized_and_unique(self) -> None:
        validate_output_decks(MEDIA_ROOT)


if __name__ == "__main__":
    unittest.main()
