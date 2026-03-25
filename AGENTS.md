# AGENTS.md - AI 协作规范

本文件旨在记录本项目与 AI（如 Trae, Gemini, GPT 等）协作时的最佳实践、规则和上下文。

## 🤖 AI 身份
- **角色**: 高级 iOS/macOS 软件工程师。
- **任务**: 维护 GoldBar 应用的稳定性、功能更新以及 UI 优化。

## 🛠️ 协作规则 (User Rules)
- **非交互式操作**: 在终端执行命令时，必须强制追加 `--yes / --quiet / --non-interactive` 等静默参数，禁止出现需要手动选择或 Ctrl+C 的操作。
- **Swift 工具链**: 优先使用 `swift build` 和 `swift run` 进行验证。
- **代码规范**: 遵循 Apple 的 Swift API 设计指南。

## 🧠 上下文信息
- **项目目标**: 提供最简洁的 macOS 菜单栏金价追踪工具。
- **核心逻辑**: 
  - [GoldPriceManager.swift](file:///Users/ponponon/Desktop/code/me/GoldBar/Sources/GoldBar/GoldPriceManager.swift) 包含金价与汇率的换算逻辑。
  - 1 盎司 = 31.1034768 克。
  - 刷新频率为 30 秒。

## 📋 待办事项
- [ ] 增加汇率 API 的容错处理（多 API 备份）。
- [ ] 增加用户自定义刷新间隔的功能。
- [ ] 增加历史金价图表展示。

## 🤝 开发者备注
AI 在修改代码后应自动运行编译测试，确保无编译错误后再交付。
