# 设计 QA

状态只使用 `passed`、`blocked` 或明确失败说明。

## 2026-07-30 phone 模拟器验收

- `passed`：API 24 phone 模拟器安装、启动与前台稳定运行。
- `passed`：首页、洗牌、结果、牌库和历史记录视觉截图已保存到 `docs/qa/screenshots/`。
- `passed`：每日抽牌显示真实牌面、正逆位和简体中文个性化解读。
- `passed`：历史保存后强停应用并重启，记录仍存在。
- `passed`：缺少 Agent Framework 系统 HSP 的设备不加载小艺组件，离线核心不崩溃并显示明确状态。
- `blocked`：tablet 运行截图；当前未提供可用平板设备或模拟器证据。
- `blocked`：字体放大、横屏与完整无障碍审查；尚未在对应系统配置下执行。
- `blocked`：小艺正式拉起；等待正式智能体 ID、平台侧可调试状态和包含 `agentKitHsp` 的受支持设备。
