"""Static regression gate for the shared reading-flow exit action."""

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INDEX_PATH = PROJECT_ROOT / "entry/src/main/ets/pages/Index.ets"
STRINGS_PATH = PROJECT_ROOT / "entry/src/main/resources/base/element/string.json"


def section(source: str, start: str, end: str) -> str:
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[start_index:end_index]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    source = INDEX_PATH.read_text(encoding="utf-8")
    strings = STRINGS_PATH.read_text(encoding="utf-8")
    page_names = [
        "DrawModePage",
        "QuestionPage",
        "ShufflePage",
        "SelectCardsPage",
        "RevealPage",
        "ResultPage",
    ]

    require('"name": "exit_reading"' in strings, "exit label must be a string resource")
    require("  ReadingExitButton() {" in source, "reading flow must use one shared exit builder")
    require("  private exitReadingFlow(): void {" in source, "reading flow must use one exit method")

    exit_builder = section(source, "  ReadingExitButton() {", "  @Builder\n  HomePage")
    require("$r('app.string.exit_reading')" in exit_builder, "exit builder must use the resource label")
    require(".height(48)" in exit_builder, "exit builder must retain a 48vp click target")
    require(".backgroundColor(Color.Transparent)" in exit_builder, "exit builder must use text styling")
    require("this.exitReadingFlow()" in exit_builder, "exit builder must invoke the shared behavior")

    exit_method = section(source, "  private exitReadingFlow(): void {", "  private goBack(): void {")
    required_resets = [
        "this.question = '';",
        "this.drawn = [];",
        "this.clarifications = [];",
        "this.clarificationReadings = [];",
        "this.pendingDraw = [];",
        "this.selectedDrawIds = [];",
        "this.summary = '';",
        "this.connection = '';",
        "this.actionText = '';",
        "this.reflection = '';",
        "this.safetyNotice = '';",
        "this.currentSaved = false;",
        "this.savedRecordId = '';",
        "this.drawFlowService = new DrawFlowService(1);",
        "this.selectRoot('home');",
    ]
    for reset in required_resets:
        require(reset in exit_method, f"exit method must include: {reset}")

    page_markers = {
        "DrawModePage": "  @Builder\n  SpreadCard",
        "QuestionPage": "  @Builder\n  SceneChip",
        "ShufflePage": "  @Builder\n  SelectCardsPage",
        "SelectCardsPage": "  @Builder\n  RevealPage",
        "RevealPage": "  @Builder\n  ResultPage",
        "ResultPage": "  @Builder\n  ResultSection",
    }
    for page_name in page_names:
        page = section(source, f"  {page_name}() {{", page_markers[page_name])
        require(
            "this.ReadingExitButton()" in page,
            f"{page_name} must render the shared reading exit button",
        )

    result_page = section(source, "  ResultPage() {", "  @Builder\n  ResultSection")
    require(
        result_page.index("$r('app.string.draw_again')") < result_page.index("this.ReadingExitButton()"),
        "result exit action must follow draw again",
    )
    print("Reading-flow exit regression check passed.")


if __name__ == "__main__":
    main()
