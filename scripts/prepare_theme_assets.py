"""Extract the two approved tarot atlas themes into flat Harmony media resources."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Iterable

from PIL import Image


CANVAS = (400, 600)
SUITS = ("wands", "cups", "swords", "pentacles")


def rect_grid(xs: list[int], rows: list[tuple[int, int]]) -> list[tuple[int, int, int, int]]:
    return [(x, y, 115, height) for y, height in rows for x in xs]


def major_rects(theme: str) -> list[tuple[int, int, int, int]]:
    if theme == "moon_garden":
        xs = [60, 250, 440, 630, 820]
        rows = [(165, 286), (464, 268), (743, 258), (1013, 258)]
        return [(x, y, 172, height) for y, height in rows for x in xs] + [
            (60, 1282, 172, 199),
            (250, 1282, 172, 199),
        ]
    xs = [56, 246, 436, 626, 816]
    rows = [(158, 263), (431, 259), (703, 245), (958, 251)]
    return [(x, y, 170, height) for y, height in rows for x in xs] + [
        (56, 1217, 170, 245),
        (246, 1217, 170, 245),
    ]


def minor_rects(theme: str, first_pair: bool) -> list[tuple[int, int, int, int]]:
    if theme == "moon_garden" and first_pair:
        return rect_grid([54, 192, 330, 467, 604, 741, 878], [(245, 250), (504, 251), (795, 251), (1054, 251)])
    if theme == "moon_garden":
        return rect_grid([64, 201, 338, 475, 612, 749, 886], [(228, 246), (489, 247), (799, 247), (1058, 247)])
    if first_pair:
        return rect_grid([35, 182, 329, 476, 623, 770, 917], [(202, 265), (478, 264), (796, 246), (1050, 246)])
    return rect_grid([35, 182, 329, 476, 623, 770, 917], [(212, 257), (480, 257), (805, 244), (1063, 244)])


def contain_crop(source: Image.Image, rect: tuple[int, int, int, int], background: tuple[int, int, int]) -> Image.Image:
    x, y, width, height = rect
    crop = source.crop((x, y, x + width, y + height)).convert("RGB")
    max_width, max_height = 380, 580
    scale = min(max_width / crop.width, max_height / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", CANVAS, background)
    canvas.paste(resized, ((CANVAS[0] - resized.width) // 2, (CANVAS[1] - resized.height) // 2))
    return canvas


def rectify_back(source: Image.Image, theme: str, background: tuple[int, int, int]) -> Image.Image:
    if theme == "moon_garden":
        quad = (786, 1284, 768, 1457, 906, 1468, 920, 1298)
    else:
        quad = (824, 1263, 815, 1440, 922, 1444, 934, 1277)
    card = source.convert("RGB").transform((360, 540), Image.Transform.QUAD, quad, Image.Resampling.BICUBIC)
    canvas = Image.new("RGB", CANVAS, background)
    canvas.paste(card, (20, 30))
    return canvas


def save_cards(
    source_path: Path,
    rects: Iterable[tuple[int, int, int, int]],
    names: Iterable[str],
    output_dir: Path,
    background: tuple[int, int, int],
) -> None:
    with Image.open(source_path) as source:
        for rect, name in zip(rects, names, strict=True):
            output = contain_crop(source, rect, background)
            output.save(output_dir / f"{name}.jpg", format="JPEG", quality=92, optimize=True)


def theme_names(theme: str) -> list[str]:
    names = [f"{theme}_major_{index:02d}" for index in range(22)]
    for suit in SUITS:
        names.extend(f"{theme}_{suit}_{index:02d}" for index in range(1, 15))
    return names


def write_mapping(output_path: Path) -> None:
    lines = [
        "import { TarotThemeId } from '../models/TarotModels';",
        "",
        "export function tarotThemeMedia(themeId: TarotThemeId, cardId: string): Resource {",
        "  const key: string = `${themeId}:${cardId}`;",
        "  switch (key) {",
    ]
    for theme in ("moon_garden", "stained_glass"):
        for card_id in [f"major-{index:02d}" for index in range(22)]:
            resource = f"{theme}_{card_id.replace('-', '_')}"
            lines.extend([f"    case '{theme}:{card_id}':", f"      return $r('app.media.{resource}');"])
        for suit in SUITS:
            for index in range(1, 15):
                card_id = f"{suit}-{index:02d}"
                resource = f"{theme}_{card_id.replace('-', '_')}"
                lines.extend([f"    case '{theme}:{card_id}':", f"      return $r('app.media.{resource}');"])
    lines.extend([
        "    default:",
        "      return $r('app.media.card_placeholder');",
        "  }",
        "}",
        "",
        "export function tarotThemeBack(themeId: TarotThemeId): Resource {",
        "  return themeId === 'stained_glass'",
        "    ? $r('app.media.stained_glass_card_back')",
        "    : $r('app.media.moon_garden_card_back');",
        "}",
        "",
    ])
    output_path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--moon-major", type=Path, required=True)
    parser.add_argument("--moon-wands-cups", type=Path, required=True)
    parser.add_argument("--moon-swords-pentacles", type=Path, required=True)
    parser.add_argument("--glass-major", type=Path, required=True)
    parser.add_argument("--glass-wands-cups", type=Path, required=True)
    parser.add_argument("--glass-swords-pentacles", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    media = args.project_root / "entry/src/main/resources/base/media"
    media.mkdir(parents=True, exist_ok=True)
    mapping = args.project_root / "entry/src/main/ets/common/TarotThemeMedia.ets"

    themes = [
        ("moon_garden", args.moon_major, args.moon_wands_cups, args.moon_swords_pentacles, (238, 234, 254)),
        ("stained_glass", args.glass_major, args.glass_wands_cups, args.glass_swords_pentacles, (7, 23, 48)),
    ]
    for theme, major, first_pair, second_pair, background in themes:
        save_cards(major, major_rects(theme), theme_names(theme)[:22], media, background)
        save_cards(first_pair, minor_rects(theme, True), theme_names(theme)[22:50], media, background)
        save_cards(second_pair, minor_rects(theme, False), theme_names(theme)[50:], media, background)
        with Image.open(major) as source:
            rectify_back(source, theme, background).save(
                media / f"{theme}_card_back.jpg", format="JPEG", quality=92, optimize=True
            )

    write_mapping(mapping)
    print("Prepared 158 validated theme resources and generated TarotThemeMedia.ets")


if __name__ == "__main__":
    main()
