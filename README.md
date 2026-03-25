# GoldBar - 实时金价状态栏应用

GoldBar 是一款专为 macOS 设计的轻量级状态栏应用，旨在帮助用户实时追踪国际金价。它直接在菜单栏中显示当前金价，并提供快速刷新的功能。

## 🌟 主要功能

- **实时金价显示**: 在 macOS 菜单栏直接显示 XAU (黄金) 的实时价格。
- **自动刷新**: 默认每 30 秒自动从 API 获取最新价格。
- **涨跌提示**: 通过颜色（绿色/红色）和图标（▲/▼）直观展示价格变动。
- **简洁界面**: 点击菜单栏图标可展开详细视图，包含最后更新时间和刷新按钮。
- **系统集成**: 作为一个 `MenuBarExtra` 应用，它不会占用 Dock 栏，始终在后台运行。

## 🛠️ 环境要求

- **操作系统**: macOS 13.0 或更高版本。
- **开发环境**: Xcode 14.0+ 或 Swift 5.7+。

## 🚀 如何运行

### 1. 使用 Swift 命令行工具 (推荐)

在终端中执行以下命令：

```bash
# 编译项目
swift build

# 运行应用
swift run
```

### 2. 使用 Xcode

1. 双击打开 `Package.swift` 文件（Xcode 会自动将其识别为 Swift Package 项目）。
2. 在 Xcode 顶部的 Target 选择器中确保选择了 `GoldBar`。
3. 点击 **Run** 按钮 (或按下 `Cmd + R`)。

## 📂 项目结构

- **[Sources/GoldBar/GoldBarApp.swift](file:///Users/ponponon/Desktop/code/me/GoldBar/Sources/GoldBar/GoldBarApp.swift)**: 应用入口，定义了菜单栏的 UI 和交互。
- **[Sources/GoldBar/GoldPriceManager.swift](file:///Users/ponponon/Desktop/code/me/GoldBar/Sources/GoldBar/GoldPriceManager.swift)**: 核心逻辑层，负责 API 调用、数据解析和定时刷新。
- **[Package.swift](file:///Users/ponponon/Desktop/code/me/GoldBar/Package.swift)**: Swift Package 管理文件，定义了依赖和目标平台。

## 🔧 开发与调试

- **API 说明**: 本应用目前使用 `https://api.gold-api.com/price/XAU` 获取数据。
- **刷新频率**: 在 `GoldPriceManager.swift` 的 `startTimer()` 方法中可以修改 `30` 秒的刷新间隔。
- **UI 修改**: 可以在 `GoldBarApp.swift` 的 `MenuBarExtra` 部分调整菜单栏显示样式。

## 📄 许可证

本项目采用 MIT 许可证。
