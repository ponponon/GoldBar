#!/bin/bash

# 设置变量
APP_NAME="GoldBar"
BUILD_PATH=".build/release"
BUNDLE_PATH="dist/${APP_NAME}.app"
CONTENTS_PATH="${BUNDLE_PATH}/Contents"
MACOS_PATH="${CONTENTS_PATH}/MacOS"
RESOURCES_PATH="${CONTENTS_PATH}/Resources"

echo "🚀 开始构建 ${APP_NAME}..."

# 1. 编译 Release 版本
swift build -c release --disable-sandbox

# 2. 清理并创建目录结构 (必须先做，否则会被后面的 rm -rf 删掉图标)
echo "📁 创建 App Bundle 结构..."
rm -rf dist
mkdir -p "${MACOS_PATH}"
mkdir -p "${RESOURCES_PATH}"

# 3. 生成图标并移动到 Resources
echo "🎨 生成图标..."
swift generate_icon.swift

# 创建临时 iconset 目录
ICONSET_PATH="AppIcon.iconset"
mkdir -p "${ICONSET_PATH}"

# 生成各种尺寸的图标（用于 .icns）
sips -z 16 16     AppIcon.png --out "${ICONSET_PATH}/icon_16x16.png" > /dev/null
sips -z 32 32     AppIcon.png --out "${ICONSET_PATH}/icon_16x16@2x.png" > /dev/null
sips -z 32 32     AppIcon.png --out "${ICONSET_PATH}/icon_32x32.png" > /dev/null
sips -z 64 64     AppIcon.png --out "${ICONSET_PATH}/icon_32x32@2x.png" > /dev/null
sips -z 128 128   AppIcon.png --out "${ICONSET_PATH}/icon_128x128.png" > /dev/null
sips -z 256 256   AppIcon.png --out "${ICONSET_PATH}/icon_128x128@2x.png" > /dev/null
sips -z 256 256   AppIcon.png --out "${ICONSET_PATH}/icon_256x256.png" > /dev/null
sips -z 512 512   AppIcon.png --out "${ICONSET_PATH}/icon_256x256@2x.png" > /dev/null
sips -z 512 512   AppIcon.png --out "${ICONSET_PATH}/icon_512x512.png" > /dev/null
sips -z 1024 1024 AppIcon.png --out "${ICONSET_PATH}/icon_512x512@2x.png" > /dev/null

# 转换为 .icns 并移动到 Resources
iconutil -c icns "${ICONSET_PATH}" -o "${RESOURCES_PATH}/AppIcon.icns"

# 清理临时文件
rm -rf "${ICONSET_PATH}"
rm AppIcon.png

# 4. 复制可执行文件
echo "📦 复制二进制文件..."
cp "${BUILD_PATH}/${APP_NAME}" "${MACOS_PATH}/"

# 5. 创建 Info.plist
echo "📝 生成 Info.plist..."
cat > "${CONTENTS_PATH}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>me.ponponon.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# 强制触发布局刷新 (针对 macOS 缓存)
touch "${BUNDLE_PATH}"

echo "✅ 打包完成！你可以在 dist 目录下找到 ${APP_NAME}.app"
echo "👉 运行: open dist/${APP_NAME}.app"
