#!/usr/bin/env bash
set -euo pipefail

echo "== Flutter clean =="
flutter clean

echo "== Flutter pub get =="
flutter pub get

echo "== Build release APK =="
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [[ -f "$APK_PATH" ]]; then
  echo "APK 已生成：$APK_PATH"
else
  echo "未找到 APK：$APK_PATH"
  exit 1
fi
