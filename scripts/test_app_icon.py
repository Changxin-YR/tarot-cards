"""Validate the packaged HarmonyOS application icon resource."""

import json
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ICON_PATH = PROJECT_ROOT / "entry/src/main/resources/base/media/app_icon.png"
APP_SCOPE_ICON_PATH = PROJECT_ROOT / "AppScope/resources/base/media/app_icon.png"
APP_CONFIG = PROJECT_ROOT / "AppScope/app.json5"
MODULE_CONFIG = PROJECT_ROOT / "entry/src/main/module.json5"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def is_near_white(pixel: tuple[int, ...]) -> bool:
    red, green, blue = pixel[:3]
    return min(red, green, blue) >= 220 and max(red, green, blue) - min(red, green, blue) <= 25


def main() -> None:
    require(ICON_PATH.is_file(), "app_icon.png must exist")
    require(APP_SCOPE_ICON_PATH.is_file(), "AppScope app_icon.png must exist")
    for icon_path in (ICON_PATH, APP_SCOPE_ICON_PATH):
        with Image.open(icon_path) as icon:
            require(icon.format == "PNG", f"{icon_path} must use PNG format")
            require(icon.size == (1024, 1024), f"{icon_path} must be 1024x1024")
            require(icon.mode in ("RGB", "RGBA"), f"{icon_path} must use RGB or RGBA color")
            if icon.mode == "RGBA":
                require(icon.getchannel("A").getextrema() == (255, 255), f"{icon_path} must be fully opaque")
            pixels = icon.convert("RGB")
            corners = [pixels.getpixel(point) for point in ((0, 0), (1023, 0), (0, 1023), (1023, 1023))]
            require(not any(is_near_white(pixel) for pixel in corners), f"{icon_path} must not retain white corners")
    require(ICON_PATH.read_bytes() == APP_SCOPE_ICON_PATH.read_bytes(), "AppScope and entry icons must be identical")

    app = json.loads(APP_CONFIG.read_text(encoding="utf-8"))
    module = json.loads(MODULE_CONFIG.read_text(encoding="utf-8"))
    require(app["app"]["icon"] == "$media:app_icon", "application config must reference app_icon")
    ability = module["module"]["abilities"][0]
    require(ability["icon"] == "$media:app_icon", "Ability must reference app_icon")
    require(ability["startWindowIcon"] == "$media:app_icon", "start window must reference app_icon")
    print("HarmonyOS application icon validation passed.")


if __name__ == "__main__":
    main()
