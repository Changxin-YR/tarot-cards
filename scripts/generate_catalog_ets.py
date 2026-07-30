from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "entry/src/main/resources/rawfile/tarot_cards_zh_cn.json"
TARGET = ROOT / "entry/src/main/ets/common/TarotCatalogData.ets"
MEDIA_TARGET = ROOT / "entry/src/main/ets/common/TarotMedia.ets"


def main() -> None:
    payload = json.loads(SOURCE.read_text(encoding="utf-8"))
    cards = payload["cards"]
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    literal = json.dumps(cards, ensure_ascii=False, indent=2)
    TARGET.write_text(
        "import { TarotCard } from '../models/TarotModels';\n\n"
        f"export const TAROT_CARDS: TarotCard[] = {literal};\n",
        encoding="utf-8",
    )
    cases = []
    for card in cards:
        stem = Path(card["image"]).stem
        cases.append(
            f"    case '{card['id']}':\n      return $r('app.media.{stem}');"
        )
    MEDIA_TARGET.write_text(
        "export function tarotMedia(cardId: string): Resource {\n"
        "  switch (cardId) {\n"
        + "\n".join(cases)
        + "\n    default:\n      return $r('app.media.card_placeholder');\n"
        "  }\n}\n",
        encoding="utf-8",
    )
    print(f"Generated ArkTS catalog for {len(cards)} cards.")


if __name__ == "__main__":
    main()
