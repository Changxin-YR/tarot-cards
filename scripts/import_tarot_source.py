from __future__ import annotations

import ctypes
import json
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ARCHIVE = Path(r"C:\Users\27363\Downloads\claude-tarot-main.zip")
RAW_DIR = PROJECT_ROOT / "entry" / "src" / "main" / "resources" / "rawfile"
MEDIA_DIR = PROJECT_ROOT / "entry" / "src" / "main" / "resources" / "base" / "media"
ASSET_DOCS_DIR = PROJECT_ROOT / "docs" / "assets"
LCMAP_SIMPLIFIED_CHINESE = 0x02000000

MAJOR_NAMES = [
    "愚者",
    "魔术师",
    "女祭司",
    "女皇",
    "皇帝",
    "教皇",
    "恋人",
    "战车",
    "力量",
    "隐者",
    "命运之轮",
    "正义",
    "倒吊人",
    "死神",
    "节制",
    "恶魔",
    "高塔",
    "星星",
    "月亮",
    "太阳",
    "审判",
    "世界",
]
SUIT_NAMES = {
    "wands": "权杖",
    "cups": "圣杯",
    "swords": "宝剑",
    "pentacles": "星币",
}
NUMBER_NAMES = [
    "",
    "首牌",
    "二",
    "三",
    "四",
    "五",
    "六",
    "七",
    "八",
    "九",
    "十",
    "侍从",
    "骑士",
    "皇后",
    "国王",
]
ELEMENT_NAMES = {"Air": "风", "Water": "水", "Fire": "火", "Earth": "土"}


def to_simplified(text: str) -> str:
    if not text:
        return text
    kernel32 = ctypes.windll.kernel32
    length = kernel32.LCMapStringEx(
        "zh-CN",
        LCMAP_SIMPLIFIED_CHINESE,
        text,
        len(text),
        None,
        0,
        None,
        None,
        0,
    )
    if length <= 0:
        raise OSError("LCMapStringEx could not determine output length")
    buffer = ctypes.create_unicode_buffer(length)
    written = kernel32.LCMapStringEx(
        "zh-CN",
        LCMAP_SIMPLIFIED_CHINESE,
        text,
        len(text),
        buffer,
        length,
        None,
        None,
        0,
    )
    if written <= 0:
        raise OSError("LCMapStringEx conversion failed")
    converted = buffer.value
    replacements = {
        "疗癒": "疗愈",
        "象徵": "象征",
        "於": "于",
        "慾": "欲",
        "後": "后",
        "占有慾": "占有欲",
        "瞭解": "了解",
        "裡": "里",
        "裏": "里",
        "餘": "余",
        "祕": "秘",
        "纔": "才",
        "週": "周",
        "迴": "回",
        "佈": "布",
        "臺": "台",
    }
    for source, target in replacements.items():
        converted = converted.replace(source, target)
    return converted


def normalized_name(arcana: str, number: int, fallback: str) -> str:
    if arcana == "major":
        return MAJOR_NAMES[number]
    if arcana in SUIT_NAMES and 1 <= number <= 14:
        return f"{SUIT_NAMES[arcana]}{NUMBER_NAMES[number]}"
    return to_simplified(fallback)


def build_side(keywords: list[str], symbolism: str, reversed_side: bool) -> dict[str, object]:
    padded = (keywords + ["觉察", "调整", "行动"])[:3]
    if reversed_side:
        meaning = (
            f"逆位不代表坏结果，而是提醒你留意{padded[0]}、{padded[1]}与{padded[2]}。"
            f"{symbolism}"
        )
        actions = [
            f"先识别造成“{padded[0]}”的具体环节，再决定是否调整。",
            "给自己留出检查信息、边界和节奏的空间。",
        ]
        reflections = [
            f"“{padded[0]}”正在提醒你忽略了什么？",
            "怎样的调整既真实，又不会给自己增加新的压力？",
        ]
    else:
        meaning = f"这张牌把焦点带向{padded[0]}、{padded[1]}与{padded[2]}。{symbolism}"
        actions = [
            f"从“{padded[0]}”出发，完成一个今天可以观察到的小步骤。",
            "把注意力放回自己能够影响的部分。",
        ]
        reflections = [
            f"在当前处境中，什么最能体现“{padded[0]}”？",
            "如果先不追求确定答案，你愿意尝试哪一步？",
        ]
    return {
        "keywords": keywords,
        "meaning": meaning,
        "actionSeeds": actions,
        "reflectionSeeds": reflections,
    }


def import_source(archive_path: Path) -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    ASSET_DOCS_DIR.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="tarot-source-") as temp_dir:
        temp_root = Path(temp_dir)
        with zipfile.ZipFile(archive_path) as archive:
            archive.extractall(temp_root)
        source_root = temp_root / "claude-tarot-main"
        payload = json.loads(
            (source_root / "skill" / "tarot" / "cards.json").read_text(encoding="utf-8")
        )

        output_cards: list[dict[str, object]] = []
        asset_rows: list[str] = []
        for source_card in payload["cards"]:
            arcana = str(source_card["arcana"])
            number = int(source_card["number"])
            card_id = f"{arcana}-{number:02d}"
            source_image_name = Path(source_card["image"]).name
            target_image_name = f"tarot_{source_image_name.replace('-', '_')}"
            shutil.copyfile(
                source_root / "images" / source_image_name,
                MEDIA_DIR / target_image_name,
            )

            upright_keywords = [
                to_simplified(str(value)) for value in source_card["upright_keywords"]
            ]
            reversed_keywords = [
                to_simplified(str(value)) for value in source_card["reversed_keywords"]
            ]
            symbolism = to_simplified(str(source_card["symbolism"]))
            output_cards.append(
                {
                    "id": card_id,
                    "nameZhCn": normalized_name(
                        arcana, number, str(source_card["name_zh"])
                    ),
                    "nameEn": str(source_card["name_en"]),
                    "arcana": arcana,
                    "number": number,
                    "element": ELEMENT_NAMES.get(str(source_card["element"]), "灵性"),
                    "image": target_image_name,
                    "upright": build_side(upright_keywords, symbolism, False),
                    "reversed": build_side(reversed_keywords, symbolism, True),
                    "symbolism": symbolism,
                    "sourceIds": ["waite-1910", "claude-tarot-mit-2026"],
                }
            )
            asset_rows.append(
                f"| {arcana} | {source_image_name} | {target_image_name} | "
                "Public Domain / MIT metadata |"
            )

    catalog = {
        "schemaVersion": 1,
        "language": "zh-CN",
        "algorithmVersion": 1,
        "cards": output_cards,
    }
    (RAW_DIR / "tarot_cards_zh_cn.json").write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    sources = {
        "schemaVersion": 1,
        "sources": [
            {
                "id": "waite-1910",
                "title": "The Pictorial Key to the Tarot",
                "author": "Arthur Edward Waite",
                "year": 1910,
                "license": "Public Domain",
                "usage": "牌义与象征的公共领域来源锚点",
            },
            {
                "id": "claude-tarot-mit-2026",
                "title": "Claude Tarot cards.json",
                "author": "Alex Yeh",
                "year": 2026,
                "license": "MIT",
                "usage": "现代繁体中文重写，经本项目规范化为简体中文",
            },
        ],
    }
    (RAW_DIR / "knowledge_sources.json").write_text(
        json.dumps(sources, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    manifest = """# 塔罗素材与知识来源

## 使用边界

- 牌义来源：A. E. Waite 1910 公共领域原典与 `claude-tarot-main` 的 MIT 现代繁体重写。
- 牌面来源：压缩包声明的 Pamela Colman Smith 1909 公共领域图像。
- 本项目将牌义规范化为简体中文并扩展本地行动与反思字段。
- 当前传统 RWS 牌面是可运行基线；用户提供的星夜图鉴不能直接切成 78 张生产牌面，后续独立牌素材可按稳定 ID 替换。

## 文件映射

| 牌组 | 原文件 | 应用资源 | 授权 |
|---|---|---|---|
""" + "\n".join(asset_rows) + "\n"
    (ASSET_DOCS_DIR / "tarot-assets.md").write_text(manifest, encoding="utf-8")
    print(f"Imported {len(output_cards)} cards.")


if __name__ == "__main__":
    source_archive = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_ARCHIVE
    import_source(source_archive)
