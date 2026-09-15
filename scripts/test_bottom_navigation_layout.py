"""Static regression gate for system safe-area ownership."""

import re
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INDEX_PATH = PROJECT_ROOT / "entry/src/main/ets/pages/Index.ets"
TOKENS_PATH = PROJECT_ROOT / "entry/src/main/ets/common/DesignTokens.ets"
HEADER_PATH = PROJECT_ROOT / "entry/src/main/ets/components/AppHeader.ets"
NAV_PATH = PROJECT_ROOT / "entry/src/main/ets/components/BottomNavigation.ets"


def section(source: str, start: str, end: str) -> str:
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[start_index:end_index]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    source = INDEX_PATH.read_text(encoding="utf-8")
    tokens = TOKENS_PATH.read_text(encoding="utf-8")
    nav_bar = NAV_PATH.read_text(encoding="utf-8")
    header = HEADER_PATH.read_text(encoding="utf-8")
    catalog = section(source, "  CatalogPage() {", "  @Builder\n  CardDetailPage")
    quick_card = section(source, "  QuickCard(", "  @Builder\n  DrawModePage")
    build = section(source, "  build() {", "\n  }\n}")
    page_builders = [
        "HomePage",
        "DrawModePage",
        "QuestionPage",
        "ShufflePage",
        "SelectCardsPage",
        "RevealPage",
        "ResultPage",
        "CatalogPage",
        "CardDetailPage",
        "HistoryPage",
        "SettingsPage",
    ]

    require(
        "SAFE_TOP_FALLBACK" in tokens,
        "DesignTokens must define a minimum top safe-area fallback",
    )
    require(
        "CARD_ASPECT_RATIO: number = 0.6" in tokens,
        "DesignTokens must define the 3:5 tarot card ratio",
    )
    require(
        "CARD_RADIUS: number" in tokens,
        "DesignTokens must define one restrained card corner radius",
    )
    card_face_blocks = re.findall(
        r"Image\(tarotThemeMedia[\s\S]*?\.objectFit\(ImageFit\.Cover\)",
        source,
    )
    require(len(card_face_blocks) >= 5, "all card-face contexts must be covered by the layout gate")
    for card_face in card_face_blocks:
        require(
            ".aspectRatio(DesignTokens.CARD_ASPECT_RATIO)" in card_face,
            "every card face must use the shared 3:5 aspect ratio",
        )
        require(
            ".height(" not in card_face,
            "card faces must not combine fixed width and height",
        )
    require(
        "@State safeTop: number = DesignTokens.SAFE_TOP_FALLBACK" in source,
        "the first frame must start below the top system bar",
    )
    require(
        "Math.max(DesignTokens.SAFE_TOP_FALLBACK" in source,
        "safeTop must retain a fallback when the window initially reports zero",
    )
    require(
        "this.safeTop = DesignTokens.SAFE_TOP_FALLBACK" in source,
        "safeTop must retain its fallback when avoid-area access fails",
    )
    require(
        "SAFE_BOTTOM_FALLBACK" in tokens,
        "DesignTokens must define a minimum bottom safe-area fallback",
    )
    require(
        "@State safeBottom: number = DesignTokens.SAFE_BOTTOM_FALLBACK" in source,
        "the first frame must reserve the bottom system gesture area",
    )
    require(
        "Math.max(DesignTokens.SAFE_BOTTOM_FALLBACK" in source,
        "safeBottom must retain a fallback when the window initially reports zero",
    )
    require(
        "this.SafeAreaSpacer(this.safeTop)" in build,
        "the top safe area must be an in-flow spacer inside the 100% root",
    )
    require(
        "} else {\n            this.SafeAreaSpacer(this.safeBottom)" in build,
        "pages without TabBar must retain an in-flow bottom safe-area spacer",
    )
    require(
        ".padding({ top: this.safeTop, bottom: this.safeBottom })" not in build,
        "the 100% root must not grow beyond the viewport through safe-area padding",
    )
    require(
        ".height(this.safeBottom)" in nav_bar,
        "the TabBar must own a bottom spacer below its interactive content",
    )
    require(
        ".height(DesignTokens.NAV_HEIGHT + this.safeBottom)" in nav_bar,
        "the TabBar height must include the system bottom safe area",
    )
    require(
        ".height(DesignTokens.HEADER_HEIGHT)" in header,
        "opening the header menu must not increase the header height",
    )
    require(
        "HEADER_HEIGHT + 60" not in header,
        "the header menu must not push page content down",
    )
    require(
        ".translate({ y: DesignTokens.HEADER_HEIGHT })" in header,
        "the header menu must visually overlay content below the fixed header",
    )
    for track in (
        "QUICK_ENTRY_ICON_HEIGHT",
        "QUICK_ENTRY_TITLE_HEIGHT",
        "QUICK_ENTRY_SUBTITLE_HEIGHT",
    ):
        require(
            f"static readonly {track}" in tokens,
            f"DesignTokens must define the {track} track for quick-entry alignment",
        )
        require(
            f".height(DesignTokens.{track})" in quick_card,
            f"QuickCard must reserve the {track} track for every shortcut",
        )
    require(
        "Column({ space: 0 })" in quick_card,
        "QuickCard must use explicit tracks rather than content-dependent spacing",
    )
    require(
        ".alignItems(HorizontalAlign.Center)" in quick_card,
        "QuickCard contents must share a centered horizontal track",
    )
    require(
        catalog.count(".layoutWeight(1)") >= 2,
        "CatalogPage and its Grid must both be constrained to the area above TabBar",
    )
    require(
        "this.drawn.concat(this.clarifications)" not in source,
        "main cards and clarification cards must not be mixed before interpretation",
    )
    require(
        "@State clarificationReadings: ClarificationReading[] = []" in source,
        "the page must retain structured clarification readings",
    )
    require(
        "app.string.clarification_focus" in source,
        "the clarification focus label must be resource-backed",
    )
    require(
        "app.string.clarification_meaning" in source,
        "the clarification meaning label must be resource-backed",
    )
    require(
        "app.string.clarification_impact" in source,
        "the clarification impact label must be resource-backed",
    )
    require(
        "app.string.clarification_action" in source,
        "the clarification action label must be resource-backed",
    )
    require(
        "this.clarificationReadings = record.result.clarificationReadings ?? []" in source,
        "saved records must restore structured clarification readings for review",
    )
    require(
        ".onClick((): void => this.openRecord(record))" in source,
        "structured reading records must open their full result",
    )
    scroll_container_count = len(re.findall(r"^\s*(?:Scroll|Grid|List)\(", source, re.MULTILINE))
    require(
        source.count(".scrollBar(BarState.Off)") >= scroll_container_count,
        "every scroll container must hide its visual scroll bar",
    )
    for index, builder in enumerate(page_builders):
        start = f"  {builder}() {{"
        start_index = source.index(start)
        if index + 1 < len(page_builders):
            end_index = source.index(f"  {page_builders[index + 1]}() {{", start_index)
        else:
            end_index = source.index("  SettingRow(", start_index)
        page_source = source[start_index:end_index]
        require(
            ".layoutWeight(1)" in page_source,
            f"{builder} must be constrained between the top and bottom safe areas",
        )
    print("System safe-area layout regression check passed.")


if __name__ == "__main__":
    main()
