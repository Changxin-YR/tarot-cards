# 塔罗灵感牌

HarmonyOS 6.1.1 原生单机塔罗灵感与自我反思应用。核心抽牌、牌库、个性化解读、历史、收藏、牌义笔记和设置均离线运行；正式小艺联调仍依赖外部智能体配置与受支持设备。

## 技术栈

- HarmonyOS Stage 模型
- ArkTS / ArkUI
- API 24
- Preferences
- Agent Framework Kit（可选增强）

## 目录

- `entry/src/main/ets/pages/`：路由页面与页面编排
- `entry/src/main/ets/components/`：复用 UI
- `entry/src/main/ets/services/`：抽牌、解读、系统能力
- `entry/src/main/ets/repositories/`：Preferences 与 RDB 持久化访问层
- `entry/src/main/ets/models/`：领域模型
- `entry/src/main/ets/common/`：设计令牌、常量和纯工具
- `entry/src/main/resources/`：字符串、颜色、尺寸、牌面和知识数据
- `docs/qa/`：构建、运行和交互证据

## 构建

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-standard.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-harmony.ps1 -BuildMode debug
```

构建产物位于 `entry/build/`。没有真实设备证据时，不将编译结果描述为真机验证。

## 当前状态

工程处于 V1.0 实施阶段，真实进度见 `tasks.md`，验证记录见 `changes.md` 与 `design-qa.md`。
