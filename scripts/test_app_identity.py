"""Keep the user-facing application identity on the approved original assets."""

import json
import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
APP_SCOPE_STRINGS = PROJECT_ROOT / "AppScope/resources/base/element/string.json"
ENTRY_STRINGS = PROJECT_ROOT / "entry/src/main/resources/base/element/string.json"
ICON_PATHS = (
    Path("AppScope/resources/base/media/app_icon.png"),
    Path("entry/src/main/resources/base/media/app_icon.png"),
)


def values(path: Path) -> dict[str, str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return {item["name"]: item["value"] for item in data["string"]}


def baseline_bytes(path: Path) -> bytes:
    return subprocess.check_output(["git", "show", f"HEAD:{path.as_posix()}"], cwd=PROJECT_ROOT)


def main() -> None:
    app_scope = values(APP_SCOPE_STRINGS)
    entry = values(ENTRY_STRINGS)
    expected = "塔罗灵感牌"

    assert app_scope["app_name"] == expected
    assert entry["entry_ability_desc"] == f"{expected}主界面"
    assert entry["entry_ability_label"] == expected
    assert entry["welcome_title"] == expected
    assert entry["app_title"] == expected
    assert entry["about_desc"].startswith(f"{expected} V1.0")
    assert entry["exit_message"] == f"是否退出{expected}？"
    for icon_path in ICON_PATHS:
        assert (PROJECT_ROOT / icon_path).read_bytes() == baseline_bytes(icon_path)
    print("HarmonyOS application identity validation passed.")


if __name__ == "__main__":
    main()
