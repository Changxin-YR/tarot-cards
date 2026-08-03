# HarmonyOS 应用图标替换设计

## 目标

使用用户提供的 1254×1254 PNG 作为唯一视觉来源，生成可由 HarmonyOS 工程直接打包的应用图标。处理不得重绘牌面、月亮、星星或“塔罗灵感牌”文字。

## 资源方案

- 同步输出到 `AppScope/resources/base/media/app_icon.png` 与 `entry/src/main/resources/base/media/app_icon.png`，避免同名 AppScope 资源在打包时覆盖新图标。
- 输出为 1024×1024、RGB PNG，不使用透明通道，避免桌面主题或启动窗口背景透出造成不可控边缘。
- 从原图四周各裁去 30px 白色留白，使主体充分利用图标画布。
- 仅替换与画布边缘连通的近白色背景为项目深紫色；图标内部的月光、星光和文字高光不参与替换。
- 使用高质量 Lanczos 重采样至 1024×1024，不再次绘制圆角；最终外形交由 HarmonyOS 桌面遮罩处理。

## 引用范围

- `AppScope/app.json5` 的应用图标继续引用 `$media:app_icon`。
- `entry/src/main/module.json5` 的 Ability 图标和启动窗口图标继续引用 `$media:app_icon`。
- 不修改包名、版本号、权限、应用名称或签名配置。

## 验证

- 新增自动校验：两份资源必须相同、为 PNG、尺寸 1024×1024、颜色模式为 RGB/RGBA、四角不得为近白色、透明通道不得包含透明像素。
- 校验两个配置文件均继续引用真实存在的 `$media:app_icon`。
- 执行项目标准门禁、debug HAP 和 `entry@ohosTest` HAP 构建。
- 在 API 22 设备重新安装后，实际观察桌面图标和启动窗口；只有观察到的结果才写入 `design-qa.md`。
