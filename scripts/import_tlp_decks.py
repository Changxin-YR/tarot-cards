"""Normalize complete project tarot decks without stretching or side bars."""

from __future__ import annotations

import argparse
import os
import shutil
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


THEMES = ("moon_garden", "stained_glass")
SUITS = ("wands", "cups", "swords", "pentacles")
OUTPUT_SIZE = (600, 1000)
MAX_THEME_BYTES = 16 * 1024 * 1024
CARD_BACK_ID = "card_back"
SUPPLEMENTAL_SOURCE_NAME = "__supplemental_source__"


def _ids(prefix: str, start: int, end: int) -> list[str]:
    return [f"{prefix}-{index:02d}" for index in range(start, end + 1)]


SOURCE_GROUPS: dict[str, list[tuple[str, list[str]]]] = {
    "moon_garden": [
        ("6f7db5a7-1535-4fa5-b71a-98a13b28506b.png", _ids("major", 0, 4)),
        ("cc1b825b-2ff1-4299-8951-e946d4010618.png", _ids("major", 5, 9)),
        ("deda8f98-3e71-4658-9a6a-8aec5bdce4e2.png", _ids("major", 10, 14)),
        ("3d2dc559-5d5e-420b-be75-5f29060de9a5.png", _ids("major", 15, 19)),
        ("6e63cc8b-d953-4dcc-ac5e-bf93d94224b1.png", _ids("major", 20, 21) + _ids("wands", 1, 3)),
        ("b0b5c92d-7575-4998-a349-e725f162d3a2.png", _ids("wands", 4, 8)),
        ("26deea71-a044-42c6-8ed3-45a79a9799c6.png", _ids("wands", 9, 13)),
        ("b51c5d67-d2f7-4524-867a-9940d588e465.png", _ids("wands", 14, 14) + _ids("cups", 1, 4)),
        ("5dbe4e9c-27fc-45cc-835a-7134bb61e763.png", _ids("cups", 5, 9)),
        ("0b5b4ff8-3763-4b76-b7df-c2d08b1b9dcb.png", _ids("cups", 10, 14)),
    ],
    "stained_glass": [
        ("21def993-6058-4338-b9d6-0fa01d488772.png", _ids("major", 0, 4)),
        ("25481805-9ba9-4308-a668-c7b85c454d25.png", _ids("major", 5, 9)),
        ("26abd3f3-6d7a-49d4-ae10-22e3aba80948.png", _ids("major", 10, 14)),
        ("8b0a51c9-dcb9-428b-afee-dcad1d0afb43.png", _ids("major", 15, 19)),
        ("a9f7e1b4-55e8-469e-b965-48ea3ddbddb8.png", _ids("major", 20, 21) + _ids("wands", 1, 3)),
        ("bb8f11dc-96a7-4821-ae0e-a3fa6c4cc4fb.png", _ids("wands", 4, 8)),
        ("e382513c-c2d2-438a-8a5e-5be46f86fc0c.png", _ids("wands", 9, 13)),
        ("fff40ee5-04ad-415e-ac8c-cd56f1be0fb4.png", _ids("wands", 14, 14) + _ids("cups", 1, 4)),
        ("96418a04-10b3-4c1e-b8dc-9e1efbc322b8.png", _ids("cups", 5, 9)),
        ("783de536-893f-486b-ad95-7635a40f43e0.png", _ids("cups", 10, 14)),
    ],
}


STAINED_GLASS_SOURCE_GROUPS: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("7005996e-bc1b-4393-8885-6e548acd031d.png", tuple(_ids("major", 0, 4))),
    ("80bb724f-5252-403f-970d-9224be90cf81.png", tuple(_ids("major", 5, 9))),
    ("eeabe22f-18e9-4fb4-9b03-9593f41725d7.png", tuple(_ids("major", 10, 14))),
    ("38d2254c-34f9-4d57-81bd-5abf74349587.png", tuple(_ids("major", 15, 19))),
    ("8c5395b6-7a4e-4d80-bd01-c4be1a37e6c0.png", tuple(_ids("major", 20, 21) + _ids("cups", 1, 3))),
    ("17eae0b8-94e4-488a-93ae-18164eabd226.png", ("cups-14", *_ids("wands", 1, 4))),
    ("e54e6b7d-53dd-4c39-aecf-fefe4777bde6.png", tuple(_ids("wands", 5, 9))),
    ("5f857b07-14a7-4e94-a2d1-a73a0b8aa157.png", tuple(_ids("wands", 10, 14))),
    ("276d53d8-876a-4312-b6f9-a38fd8113ab2.png", tuple(_ids("cups", 4, 8))),
    ("e352979c-2bf7-44ef-a943-048faed2cd20.png", tuple(_ids("cups", 9, 13))),
    ("09377971-5e41-4766-a551-aa5bf3d7b85d.png", tuple(_ids("swords", 11, 14) + _ids("pentacles", 1, 1))),
    ("b7fe7933-bd03-458c-8d7b-fbd6822ee31d.png", tuple(_ids("swords", 1, 5))),
    (SUPPLEMENTAL_SOURCE_NAME, tuple(_ids("swords", 6, 10))),
    ("8f197e02-26df-4ff9-8a08-820ef835471d.png", tuple(_ids("pentacles", 2, 6))),
    ("b61e4b54-ce7e-434c-88c9-b4eacdea1a18.png", tuple(_ids("pentacles", 7, 11))),
    ("271b98ba-caa8-4261-b583-b5ba825aa127 (1).png", tuple(_ids("pentacles", 12, 14) + [CARD_BACK_ID])),
)


def expected_card_ids() -> list[str]:
    card_ids = [f"major-{index:02d}" for index in range(22)]
    for suit in SUITS:
        card_ids.extend(f"{suit}-{index:02d}" for index in range(1, 15))
    return card_ids


def resource_path(media_root: Path, theme_id: str, card_id: str) -> Path:
    return media_root / f"{theme_id}_{card_id.replace('-', '_')}.jpg"


def _background_color(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    samples = Image.new("RGB", (4, 1))
    samples.putdata([
        rgb.getpixel((0, 0)),
        rgb.getpixel((rgb.width - 1, 0)),
        rgb.getpixel((0, rgb.height - 1)),
        rgb.getpixel((rgb.width - 1, rgb.height - 1)),
    ])
    values = ImageStat.Stat(samples).median
    return round(values[0]), round(values[1]), round(values[2])


def trim_uniform_border(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    background = Image.new("RGB", rgb.size, _background_color(rgb))
    difference = ImageChops.difference(rgb, background).convert("L")
    mask = difference.point(lambda value: 255 if value > 12 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        return rgb

    max_x_trim = round(rgb.width * 0.18)
    max_y_trim = round(rgb.height * 0.12)
    left = min(bounds[0], max_x_trim)
    top = min(bounds[1], max_y_trim)
    right = max(bounds[2], rgb.width - max_x_trim)
    bottom = max(bounds[3], rgb.height - max_y_trim)
    if right - left < rgb.width * 0.55 or bottom - top < rgb.height * 0.7:
        return rgb
    return rgb.crop((left, top, right, bottom))


def fit_cover(image: Image.Image, size: tuple[int, int] = OUTPUT_SIZE) -> Image.Image:
    rgb = image.convert("RGB")
    scale = max(size[0] / rgb.width, size[1] / rgb.height)
    resized = rgb.resize(
        (round(rgb.width * scale), round(rgb.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def split_horizontal_cards(image: Image.Image, expected_count: int | None = None) -> list[Image.Image]:
    rgb = image.convert("RGB")
    active_columns: list[bool] = []
    minimum_pixels = max(4, round(rgb.height * 0.06))
    for x in range(rgb.width):
        non_white = 0
        for y in range(rgb.height):
            red, green, blue = rgb.getpixel((x, y))
            if min(red, green, blue) < 242:
                non_white += 1
        active_columns.append(non_white >= minimum_pixels)

    runs: list[tuple[int, int]] = []
    start: int | None = None
    for index, active in enumerate(active_columns + [False]):
        if active and start is None:
            start = index
        elif not active and start is not None:
            if index - start >= round(rgb.width * 0.1):
                runs.append((start, index))
            start = None
    if expected_count is not None:
        if expected_count not in (4, 5):
            raise AssertionError(f"horizontal source must expect four or five cards, got {expected_count}")
        if len(runs) != expected_count:
            boundaries = [round(rgb.width * index / expected_count) for index in range(expected_count + 1)]
            return [rgb.crop((boundaries[index], 0, boundaries[index + 1], rgb.height)) for index in range(expected_count)]
    if len(runs) not in (4, 5):
        raise AssertionError(f"horizontal source must contain four or five cards, found {len(runs)}")
    return [rgb.crop((left, 0, right, rgb.height)) for left, right in runs]


def perceptual_hash(path: Path) -> str:
    with Image.open(path) as source:
        image = source.convert("RGB")
        average = tuple(round(value) for value in ImageStat.Stat(image.resize((1, 1))).mean)
        grayscale = image.convert("L").resize((9, 8), Image.Resampling.LANCZOS)
        pixels = list(grayscale.getdata())
    bits = 0
    for row in range(8):
        for column in range(8):
            bits = (bits << 1) | int(pixels[row * 9 + column] > pixels[row * 9 + column + 1])
    return f"{average[0]:02x}{average[1]:02x}{average[2]:02x}-{bits:016x}"


def _has_black_side_bar(image: Image.Image) -> bool:
    rgb = image.convert("RGB")
    band_width = max(1, round(rgb.width * 0.04))
    bands = (
        rgb.crop((0, 0, band_width, rgb.height)),
        rgb.crop((rgb.width - band_width, 0, rgb.width, rgb.height)),
    )
    for band in bands:
        pixels = list(band.getdata())
        dark = sum(1 for red, green, blue in pixels if max(red, green, blue) < 18)
        if dark / len(pixels) > 0.82:
            return True
    return False


def theme_media_paths(media_root: Path, theme_id: str) -> list[Path]:
    return [resource_path(media_root, theme_id, card_id) for card_id in expected_card_ids()] + [
        media_root / f"{theme_id}_card_back.jpg"
    ]


def theme_media_bytes(media_root: Path, theme_id: str) -> int:
    return sum(path.stat().st_size for path in theme_media_paths(media_root, theme_id))


def validate_theme_deck(media_root: Path, theme_id: str) -> None:
    paths = theme_media_paths(media_root, theme_id)
    missing = [path.name for path in paths if not path.is_file()]
    if missing:
        raise AssertionError(f"missing {theme_id} resources: {', '.join(missing)}")

    hashes: set[str] = set()
    for card_id in expected_card_ids():
        path = resource_path(media_root, theme_id, card_id)
        with Image.open(path) as image:
            image.load()
            if image.size != OUTPUT_SIZE:
                raise AssertionError(f"{path.name} must be 600x1000, got {image.size}")
            if _has_black_side_bar(image):
                raise AssertionError(f"{path.name} contains a black side bar")
        digest = perceptual_hash(path)
        if digest in hashes:
            raise AssertionError(f"{theme_id} contains a duplicate-looking card: {path.name}")
        hashes.add(digest)

    back = media_root / f"{theme_id}_card_back.jpg"
    with Image.open(back) as image:
        image.load()
        if image.size != OUTPUT_SIZE:
            raise AssertionError(f"{back.name} must be 600x1000, got {image.size}")

    total_bytes = theme_media_bytes(media_root, theme_id)
    if total_bytes > MAX_THEME_BYTES:
        raise AssertionError(
            f"{theme_id} media is {total_bytes} bytes, over the {MAX_THEME_BYTES}-byte transport budget"
        )


def validate_output_decks(media_root: Path) -> None:
    for theme_id in THEMES:
        validate_theme_deck(media_root, theme_id)


def normalize_existing_decks(media_root: Path) -> None:
    sources = [
        resource_path(media_root, theme_id, card_id)
        for theme_id in THEMES
        for card_id in expected_card_ids()
    ] + [media_root / f"{theme_id}_card_back.jpg" for theme_id in THEMES]
    missing = [path.name for path in sources if not path.is_file()]
    if missing:
        raise AssertionError(f"cannot normalize incomplete decks: {', '.join(missing)}")

    with tempfile.TemporaryDirectory(prefix="tarot-normalized-", dir=media_root.parent) as value:
        staging = Path(value)
        for source_path in sources:
            with Image.open(source_path) as source:
                output = fit_cover(trim_uniform_border(source))
                output.save(staging / source_path.name, format="JPEG", quality=94, optimize=True)
        validate_output_decks(staging)
        for source_path in sources:
            os.replace(staging / source_path.name, source_path)


def _source_sheet_path(source_root: Path, source_name: str, supplemental_source: Path | None) -> Path:
    if source_name == SUPPLEMENTAL_SOURCE_NAME:
        if supplemental_source is None:
            raise AssertionError("missing supplemental source for swords-06 through swords-10")
        return supplemental_source
    return source_root / source_name


def import_stained_glass_sources(
    source_root: Path, supplemental_source: Path | None, media_root: Path
) -> None:
    media_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="stained-glass-", dir=media_root.parent) as value:
        staging = Path(value)
        for source_name, card_ids in STAINED_GLASS_SOURCE_GROUPS:
            source_path = _source_sheet_path(source_root, source_name, supplemental_source)
            if not source_path.is_file():
                raise AssertionError(f"missing Stained Glass source: {source_path}")
            with Image.open(source_path) as source:
                cards = split_horizontal_cards(source, expected_count=len(card_ids))
            if len(cards) != len(card_ids):
                raise AssertionError(
                    f"Stained Glass source {source_path.name} has {len(cards)} cards, expected {len(card_ids)}"
                )
            for card, card_id in zip(cards, card_ids, strict=True):
                output = fit_cover(trim_uniform_border(card))
                output_name = (
                    "stained_glass_card_back.jpg"
                    if card_id == CARD_BACK_ID
                    else resource_path(staging, "stained_glass", card_id).name
                )
                output.save(staging / output_name, format="JPEG", quality=85, optimize=True)

        validate_theme_deck(staging, "stained_glass")
        for source_path in theme_media_paths(staging, "stained_glass"):
            os.replace(source_path, media_root / source_path.name)


def import_tlp_sources(source_root: Path, media_root: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="tarot-tlp-", dir=media_root.parent) as value:
        staging = Path(value)
        for theme_id in THEMES:
            for card_id in expected_card_ids():
                current = resource_path(media_root, theme_id, card_id)
                shutil.copy2(current, staging / current.name)
            back = media_root / f"{theme_id}_card_back.jpg"
            shutil.copy2(back, staging / back.name)

        for theme_id, groups in SOURCE_GROUPS.items():
            for source_name, card_ids in groups:
                source_path = source_root / source_name
                if not source_path.is_file():
                    raise AssertionError(f"missing TLP source: {source_name}")
                with Image.open(source_path) as source:
                    cards = split_horizontal_cards(source)
                for card, card_id in zip(cards, card_ids, strict=True):
                    output = fit_cover(trim_uniform_border(card))
                    output.save(
                        resource_path(staging, theme_id, card_id),
                        format="JPEG",
                        quality=94,
                        optimize=True,
                    )

        validate_output_decks(staging)
        for theme_id in THEMES:
            for card_id in expected_card_ids():
                target = resource_path(media_root, theme_id, card_id)
                os.replace(resource_path(staging, theme_id, card_id), target)
            back_name = f"{theme_id}_card_back.jpg"
            os.replace(staging / back_name, media_root / back_name)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--media-root",
        type=Path,
        default=Path(__file__).resolve().parents[1]
        / "entry" / "src" / "main" / "resources" / "base" / "media",
    )
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--source-root", type=Path)
    parser.add_argument("--supplemental-source", type=Path)
    args = parser.parse_args()
    if args.source_root is not None:
        import_stained_glass_sources(args.source_root, args.supplemental_source, args.media_root)
    elif not args.validate_only:
        normalize_existing_decks(args.media_root)
    validate_output_decks(args.media_root)
    print("Validated two complete 78-card decks at 600x1000 with no black side bars.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
