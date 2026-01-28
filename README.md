# 健康识别（Flutter 前端 Mock）

面向 Android 的健康识别 UI Demo，采用底部导航三栏：主页 / 历史 / 设置。

## 如何运行

1. 安装 Flutter（建议 3.x）并确认 `flutter doctor` 正常。
2. 在项目根目录执行：
   - `flutter pub get`
   - `flutter run -d android`

## API 验证脚本

在项目根目录执行：
`API_BASE=https://api.tapgiga.com IMG=~/Downloads/1.jpg ./tools/verify_api.sh`

## 底部导航与主要路由

- **主页**：`/home`（拍照/相册 → Preview/Result）
- **历史**：`/history`（进入详情 `/history/:id`）
- **设置**：`/settings`（进入隐私 `/privacy`）

## 如何清空记录

进入“历史记录”或“设置”页面，点击“清空全部记录”并二次确认即可删除。

## Settings 使用说明

- **入口**：底部导航“设置”Tab。
- **导出记录**：设置页选择“导出我的记录（JSON）”，会复制到剪贴板并提示数量。
- **清空记录**：设置页选择“清空全部记录”，二次确认后清空。

## 引擎可替换说明

目前使用 `MockAnalysisEngine`。未来接入 OpenAI 时，只需新增
`OpenAIAnalysisEngine` 并在 `lib/core/di/engine_provider.dart` 替换注入即可，
UI 无需改动。

## 常见错误处理

- **Android 设备找不到**：确认已连接设备或启动模拟器，执行 `flutter devices` 检查。
- **依赖拉取失败**：检查网络或镜像源，重新执行 `flutter pub get`。
- **Gradle 构建失败**：尝试 `flutter clean` 后重新运行。
