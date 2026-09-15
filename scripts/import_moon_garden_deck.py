"""Import the user-provided cool tarot deck as local Moon Garden media."""

from __future__ import annotations

import argparse
import os
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


OUTPUT_SIZE = (600, 1000)
SUITS = ("wands", "cups", "swords", "pentacles")


@dataclass(frozen=True)
class SourceGroup:
    source_name: str
    card_ids: tuple[str, ...]
    card_indices: tuple[int, ...]


def _ids(prefix: str, start: int, end: int) -> tuple[str, ...]:
    return tuple(f"{prefix}-{index:02d}" for index in range(start, end + 1))


EXPECTED_CARD_IDS: tuple[str, ...] = (
    _ids("major", 0, 21)
    + _ids("wands", 1, 14)
    + _ids("cups", 1, 14)
    + _ids("swords", 1, 14)
    + _ids("pentacles", 1, 14)
)


SOURCE_GROUPS: tuple[SourceGroup, ...] = (
    SourceGroup("4169d8c5-117f-4b86-8670-bbb01e0dd40e.png", _ids("major", 0, 4), (0, 1, 2, 3, 4)),
    SourceGroup("41762698-139c-47f4-b33b-577c2bfa634d.png", _ids("major", 5, 9), (0, 1, 2, 3, 4)),
    SourceGroup("fdf62528-6712-420b-b6bc-e0e95631bca2.png", _ids("major", 10, 14), (0, 1, 2, 3, 4)),
    SourceGroup("33b20cc7-c905-4c3d-b16e-3547b0fcd1ff.png", _ids("major", 15, 19), (0, 1, 2, 3, 4)),
    SourceGroup(
        "44949724-3be4-4950-9957-ac9a519526e5.png",
        _ids("major", 20, 21) + _ids("cups", 1, 3),
        (0, 1, 2, 3, 4),
    ),
    SourceGroup(
        "69973273-c34f-4c78-aba3-3870eaaf2f38.png",
        ("cups-14",) + _ids("wands", 1, 4),
        (0, 1, 2, 3, 4),
    ),
    SourceGroup("9f3731be-43af-437e-8ee3-2c1354a8a6f2.png", _ids("wands", 5, 9), (0, 1, 2, 3, 4)),
    SourceGroup("d97fcbf9-ac3c-4b47-bf14-69f22b9ce6d3.png", _ids("wands", 10, 14), (0, 1, 2, 3, 4)),
    SourceGroup("f3776b88-d009-4ffb-8963-8d8a4b79f22b.png", _ids("cups", 4, 8), (0, 1, 2, 3, 4)),
    SourceGroup("7e8d31ea-2a21-4adf-8f50-912113838500.png", _ids("cups", 9, 13), (0, 1, 2, 3, 4)),
    SourceGroup("c629affb-f633-4007-bc0b-51fdf487c911.png", _ids("swords", 1, 5), (0, 1, 2, 3, 4)),
    SourceGroup("b548d88a-0430-4db6-b650-17943f4c2afa.png", _ids("swords", 6, 10), (0, 1, 2, 3, 4)),
    SourceGroup("9aee2071-9a82-4f16-8f32-2a04537fecc2.png", _ids("swords", 11, 14), (0, 1, 2, 3)),
    SourceGroup("7e037862-f17c-4043-971b-1f8ca7781e84.png", _ids("pentacles", 1, 5), (0, 1, 2, 3, 4)),
    SourceGroup("1c3b9238-5d1e-41db-b00e-b388b9cd3327.png", _ids("pentacles", 6, 10), (0, 1, 2, 3, 4)),
    SourceGroup("560e774b-04f5-46d2-a23a-3cc498716941.png", _ids("pentacles", 11, 14), (0, 1, 2, 3)),
)

BACK_SOURCE = SourceGroup(
    "9aee2071-9a82-4f16-8f32-2a04537fecc2.png",
    ("card_back",),
    (4,),
)


def resource_path(media_root: Path, card_id: str) -> Path:
    return media_root / f"moon_garden_{card_id.replace('-', '_')}.jpg"


def _background_color(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    samples = Image.new("RGB", (4, 1))
    samples.putdata([
        rgb.getpixel((0, 0)),
        rgb.getpixel((rgb.width - 1, 0)),
        rgb.getpixel((0, rgb.height - 1)),
        rgb.getpixel((rgb.width - 1, rgb.height - 1)),
    ])
    median = ImageStat.Stat(samples).median
    return round(median[0]), round(median[1]), round(median[2])


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


def split_horizontal_cards(image: Image.Image) -> list[Image.Image]:
    rgb = image.convert("RGB")
    minimum_pixels = max(4, round(rgb.height * 0.06))
    active_columns: list[bool] = []
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
    if len(runs) not in (4, 5):
        raise AssertionError(f"horizontal source must contain four or five cards, found {len(runs)}")
    return [rgb.crop((left, 0, right, rgb.height)) for left, right in runs]


def extract_cards(source: Image.Image, count: int) -> list[Image.Image]:
    cards = split_horizontal_cards(source)
    if len(cards) < count:
        raise AssertionError(f"source contains {len(cards)} cards, expected at least {count}")
    return [fit_cover(trim_uniform_border(cards[index])) for index in range(count)]


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


def validate_moon_garden_assets(media_root: Path) -> None:
    paths = [resource_path(media_root, card_id) for card_id in EXPECTED_CARD_IDS]
    paths.append(media_root / "moon_garden_card_back.jpg")
    missing = [path.name for path in paths if not path.is_file()]
    if missing:
        raise AssertionError(f"missing Moon Garden resources: {', '.join(missing)}")

    for path in paths:
        with Image.open(path) as image:
            image.load()
            if image.size != OUTPUT_SIZE:
                raise AssertionError(f"{path.name} must be 600x1000, got {image.size}")
            if _has_black_side_bar(image):
                raise AssertionError(f"{path.name} contains a black side bar")


def _write_group(source_root: Path, staging: Path, group: SourceGroup) -> None:
    source_path = source_root / group.source_name
    if not source_path.is_file():
        raise AssertionError(f"missing source: {source_path}")
    with Image.open(source_path) as source:
        cards = split_horizontal_cards(source)
        if len(group.card_ids) != len(group.card_indices):
            raise AssertionError(f"source mapping length mismatch: {group.source_name}")
        for card_id, card_index in zip(group.card_ids, group.card_indices):
            if card_index >= len(cards):
                raise AssertionError(f"source index {card_index} is outside {group.source_name}")
            output = fit_cover(trim_uniform_border(cards[card_index]))
            output.save(resource_path(staging, card_id), format="JPEG", quality=86, optimize=True)


def import_deck(source_root: Path, media_root: Path) -> None:
    media_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="moon-garden-", dir=media_root.parent) as value:
        staging = Path(value)
        for group in SOURCE_GROUPS:
            _write_group(source_root, staging, group)
        _write_group(source_root, staging, BACK_SOURCE)

        validate_moon_garden_assets(staging)
        generated = [resource_path(staging, card_id) for card_id in EXPECTED_CARD_IDS]
        generated.append(staging / "moon_garden_card_back.jpg")
        for source_path in generated:
            os.replace(source_path, media_root / source_path.name)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument(
        "--media-root",
        type=Path,
        default=Path(__file__).resolve().parents[1]
        / "entry" / "src" / "main" / "resources" / "base" / "media",
    )
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()

    if not args.validate_only:
        import_deck(args.source_root, args.media_root)
    validate_moon_garden_assets(args.media_root)
    print("Validated one complete Moon Garden 78-card deck at 600x1000 with one card back.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
