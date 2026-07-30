# 塔罗素材与知识来源

## 使用边界

- 牌义来源：A. E. Waite 1910 公共领域原典与 `claude-tarot-main` 的 MIT 现代繁体重写。
- 牌面来源：压缩包声明的 Pamela Colman Smith 1909 公共领域图像。
- 本项目将牌义规范化为简体中文并扩展本地行动与反思字段。
- 当前传统 RWS 牌面是可运行基线；用户提供的星夜图鉴不能直接切成 78 张生产牌面，后续独立牌素材可按稳定 ID 替换。

## 原创应用资源

| 资源 | 尺寸 | 生成方式 | 用途 |
|---|---:|---|---|
| `card_back.png` | 1024×1536 | Codex 内置 ImageGen，深蓝星夜、金色月牙与星轨原创牌背 | 洗牌、抽牌、首页主视觉 |
| `card_placeholder.png` | 1024×1536 | Codex 内置 ImageGen，同视觉体系的三张牌占位图 | 图片缺失与空状态 |

牌背最终提示词要点：2:3 竖版、正视无透视、深蓝纸张质感、居中金色月牙与八芒星、同心星轨、对称金线边框、无文字/人物/水印。

占位图最终提示词要点：2:3 竖版、正视无透视、深蓝纸张质感、居中三张扇形牌背、八芒星与月牙、金线边框、无文字/人物/水印。

## 文件映射

| 牌组 | 原文件 | 应用资源 | 授权 |
|---|---|---|---|
| major | major-00-fool.jpg | tarot_major_00_fool.jpg | Public Domain / MIT metadata |
| major | major-01-magician.jpg | tarot_major_01_magician.jpg | Public Domain / MIT metadata |
| major | major-02-high_priestess.jpg | tarot_major_02_high_priestess.jpg | Public Domain / MIT metadata |
| major | major-03-empress.jpg | tarot_major_03_empress.jpg | Public Domain / MIT metadata |
| major | major-04-emperor.jpg | tarot_major_04_emperor.jpg | Public Domain / MIT metadata |
| major | major-05-hierophant.jpg | tarot_major_05_hierophant.jpg | Public Domain / MIT metadata |
| major | major-06-lovers.jpg | tarot_major_06_lovers.jpg | Public Domain / MIT metadata |
| major | major-07-chariot.jpg | tarot_major_07_chariot.jpg | Public Domain / MIT metadata |
| major | major-08-strength.jpg | tarot_major_08_strength.jpg | Public Domain / MIT metadata |
| major | major-09-hermit.jpg | tarot_major_09_hermit.jpg | Public Domain / MIT metadata |
| major | major-10-wheel_of_fortune.jpg | tarot_major_10_wheel_of_fortune.jpg | Public Domain / MIT metadata |
| major | major-11-justice.jpg | tarot_major_11_justice.jpg | Public Domain / MIT metadata |
| major | major-12-hanged_man.jpg | tarot_major_12_hanged_man.jpg | Public Domain / MIT metadata |
| major | major-13-death.jpg | tarot_major_13_death.jpg | Public Domain / MIT metadata |
| major | major-14-temperance.jpg | tarot_major_14_temperance.jpg | Public Domain / MIT metadata |
| major | major-15-devil.jpg | tarot_major_15_devil.jpg | Public Domain / MIT metadata |
| major | major-16-tower.jpg | tarot_major_16_tower.jpg | Public Domain / MIT metadata |
| major | major-17-star.jpg | tarot_major_17_star.jpg | Public Domain / MIT metadata |
| major | major-18-moon.jpg | tarot_major_18_moon.jpg | Public Domain / MIT metadata |
| major | major-19-sun.jpg | tarot_major_19_sun.jpg | Public Domain / MIT metadata |
| major | major-20-judgement.jpg | tarot_major_20_judgement.jpg | Public Domain / MIT metadata |
| major | major-21-world.jpg | tarot_major_21_world.jpg | Public Domain / MIT metadata |
| wands | wands-01.jpg | tarot_wands_01.jpg | Public Domain / MIT metadata |
| wands | wands-02.jpg | tarot_wands_02.jpg | Public Domain / MIT metadata |
| wands | wands-03.jpg | tarot_wands_03.jpg | Public Domain / MIT metadata |
| wands | wands-04.jpg | tarot_wands_04.jpg | Public Domain / MIT metadata |
| wands | wands-05.jpg | tarot_wands_05.jpg | Public Domain / MIT metadata |
| wands | wands-06.jpg | tarot_wands_06.jpg | Public Domain / MIT metadata |
| wands | wands-07.jpg | tarot_wands_07.jpg | Public Domain / MIT metadata |
| wands | wands-08.jpg | tarot_wands_08.jpg | Public Domain / MIT metadata |
| wands | wands-09.jpg | tarot_wands_09.jpg | Public Domain / MIT metadata |
| wands | wands-10.jpg | tarot_wands_10.jpg | Public Domain / MIT metadata |
| wands | wands-11.jpg | tarot_wands_11.jpg | Public Domain / MIT metadata |
| wands | wands-12.jpg | tarot_wands_12.jpg | Public Domain / MIT metadata |
| wands | wands-13.jpg | tarot_wands_13.jpg | Public Domain / MIT metadata |
| wands | wands-14.jpg | tarot_wands_14.jpg | Public Domain / MIT metadata |
| cups | cups-01.jpg | tarot_cups_01.jpg | Public Domain / MIT metadata |
| cups | cups-02.jpg | tarot_cups_02.jpg | Public Domain / MIT metadata |
| cups | cups-03.jpg | tarot_cups_03.jpg | Public Domain / MIT metadata |
| cups | cups-04.jpg | tarot_cups_04.jpg | Public Domain / MIT metadata |
| cups | cups-05.jpg | tarot_cups_05.jpg | Public Domain / MIT metadata |
| cups | cups-06.jpg | tarot_cups_06.jpg | Public Domain / MIT metadata |
| cups | cups-07.jpg | tarot_cups_07.jpg | Public Domain / MIT metadata |
| cups | cups-08.jpg | tarot_cups_08.jpg | Public Domain / MIT metadata |
| cups | cups-09.jpg | tarot_cups_09.jpg | Public Domain / MIT metadata |
| cups | cups-10.jpg | tarot_cups_10.jpg | Public Domain / MIT metadata |
| cups | cups-11.jpg | tarot_cups_11.jpg | Public Domain / MIT metadata |
| cups | cups-12.jpg | tarot_cups_12.jpg | Public Domain / MIT metadata |
| cups | cups-13.jpg | tarot_cups_13.jpg | Public Domain / MIT metadata |
| cups | cups-14.jpg | tarot_cups_14.jpg | Public Domain / MIT metadata |
| swords | swords-01.jpg | tarot_swords_01.jpg | Public Domain / MIT metadata |
| swords | swords-02.jpg | tarot_swords_02.jpg | Public Domain / MIT metadata |
| swords | swords-03.jpg | tarot_swords_03.jpg | Public Domain / MIT metadata |
| swords | swords-04.jpg | tarot_swords_04.jpg | Public Domain / MIT metadata |
| swords | swords-05.jpg | tarot_swords_05.jpg | Public Domain / MIT metadata |
| swords | swords-06.jpg | tarot_swords_06.jpg | Public Domain / MIT metadata |
| swords | swords-07.jpg | tarot_swords_07.jpg | Public Domain / MIT metadata |
| swords | swords-08.jpg | tarot_swords_08.jpg | Public Domain / MIT metadata |
| swords | swords-09.jpg | tarot_swords_09.jpg | Public Domain / MIT metadata |
| swords | swords-10.jpg | tarot_swords_10.jpg | Public Domain / MIT metadata |
| swords | swords-11.jpg | tarot_swords_11.jpg | Public Domain / MIT metadata |
| swords | swords-12.jpg | tarot_swords_12.jpg | Public Domain / MIT metadata |
| swords | swords-13.jpg | tarot_swords_13.jpg | Public Domain / MIT metadata |
| swords | swords-14.jpg | tarot_swords_14.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-01.jpg | tarot_pentacles_01.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-02.jpg | tarot_pentacles_02.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-03.jpg | tarot_pentacles_03.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-04.jpg | tarot_pentacles_04.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-05.jpg | tarot_pentacles_05.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-06.jpg | tarot_pentacles_06.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-07.jpg | tarot_pentacles_07.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-08.jpg | tarot_pentacles_08.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-09.jpg | tarot_pentacles_09.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-10.jpg | tarot_pentacles_10.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-11.jpg | tarot_pentacles_11.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-12.jpg | tarot_pentacles_12.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-13.jpg | tarot_pentacles_13.jpg | Public Domain / MIT metadata |
| pentacles | pentacles-14.jpg | tarot_pentacles_14.jpg | Public Domain / MIT metadata |
