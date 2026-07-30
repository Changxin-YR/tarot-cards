from __future__ import annotations

import json
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = (
    PROJECT_ROOT
    / "entry"
    / "src"
    / "main"
    / "resources"
    / "rawfile"
    / "tarot_cards_zh_cn.json"
)
MEDIA_DIR = (
    PROJECT_ROOT
    / "entry"
    / "src"
    / "main"
    / "resources"
    / "base"
    / "media"
)

REQUIRED_FIELDS = {
    "id",
    "nameZhCn",
    "nameEn",
    "arcana",
    "number",
    "element",
    "image",
    "upright",
    "reversed",
    "symbolism",
    "sourceIds",
}
VALID_ARCANA = {"major", "wands", "cups", "swords", "pentacles"}


def fail(message: str) -> None:
    raise AssertionError(message)


def validate_side(card_id: str, side_name: str, side: object) -> None:
    if not isinstance(side, dict):
        fail(f"{card_id}.{side_name} must be an object")
    for field in ("keywords", "meaning", "actionSeeds", "reflectionSeeds"):
        if field not in side:
            fail(f"{card_id}.{side_name} missing {field}")
    if not isinstance(side["keywords"], list) or not side["keywords"]:
        fail(f"{card_id}.{side_name}.keywords must be non-empty")
    if not isinstance(side["actionSeeds"], list) or not side["actionSeeds"]:
        fail(f"{card_id}.{side_name}.actionSeeds must be non-empty")
    if not isinstance(side["reflectionSeeds"], list) or not side["reflectionSeeds"]:
        fail(f"{card_id}.{side_name}.reflectionSeeds must be non-empty")


def main() -> int:
    if not CATALOG_PATH.is_file():
        fail(f"catalog not found: {CATALOG_PATH}")

    payload = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    cards = payload.get("cards")
    if not isinstance(cards, list):
        fail("root.cards must be an array")
    if len(cards) != 78:
        fail(f"expected 78 cards, got {len(cards)}")

    ids: set[str] = set()
    names: set[str] = set()
    arcana_counts: dict[str, int] = {name: 0 for name in VALID_ARCANA}
    for card in cards:
        if not isinstance(card, dict):
            fail("each card must be an object")
        missing = REQUIRED_FIELDS - set(card)
        if missing:
            fail(f"card missing fields: {sorted(missing)}")
        card_id = card["id"]
        name = card["nameZhCn"]
        if card_id in ids:
            fail(f"duplicate id: {card_id}")
        if name in names:
            fail(f"duplicate Simplified Chinese name: {name}")
        ids.add(card_id)
        names.add(name)
        arcana = card["arcana"]
        if arcana not in VALID_ARCANA:
            fail(f"{card_id} has invalid arcana: {arcana}")
        arcana_counts[arcana] += 1
        validate_side(card_id, "upright", card["upright"])
        validate_side(card_id, "reversed", card["reversed"])
        image_path = MEDIA_DIR / card["image"]
        if not image_path.is_file() or image_path.stat().st_size == 0:
            fail(f"{card_id} image missing or empty: {image_path}")

    expected_counts = {
        "major": 22,
        "wands": 14,
        "cups": 14,
        "swords": 14,
        "pentacles": 14,
    }
    if arcana_counts != expected_counts:
        fail(f"arcana counts mismatch: {arcana_counts}")

    print("Tarot catalog validation passed.")
    print(f"Cards: {len(cards)}; unique ids: {len(ids)}; images: {len(cards)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, json.JSONDecodeError) as error:
        print(f"Tarot catalog validation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
