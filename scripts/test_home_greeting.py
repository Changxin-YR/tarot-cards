from pathlib import Path
import unittest


PROJECT_ROOT = Path(__file__).resolve().parents[1]


class HomeGreetingTest(unittest.TestCase):
    def test_natural_greetings_replace_the_local_storage_notice(self) -> None:
        service = (PROJECT_ROOT / "entry/src/main/ets/services/GreetingService.ets").read_text(
            encoding="utf-8"
        )
        index = (PROJECT_ROOT / "entry/src/main/ets/pages/Index.ets").read_text(
            encoding="utf-8"
        )
        strings = (
            PROJECT_ROOT / "entry/src/main/resources/base/element/string.json"
        ).read_text(encoding="utf-8")

        greetings = (
            ("早上好", "新的一天，愿你心怀轻盈与期待"),
            ("上午好", "愿今天的每一步都从容而清晰"),
            ("中午好", "忙碌半日，记得让自己稍作休息"),
            ("下午好", "愿午后的时光温柔而充实"),
            ("晚上好", "辛苦一天，愿此刻轻松而宁静"),
            ("夜深了", "愿你卸下疲惫，安心度过今夜"),
        )
        for title, subtitle in greetings:
            self.assertIn(f"title: '{title}', subtitle: '{subtitle}'", service)

        self.assertNotIn("privacy_local_only", index)
        self.assertNotIn("privacy_local_only", strings)


if __name__ == "__main__":
    unittest.main()
