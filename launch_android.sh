#!/usr/bin/env bash
set -e

echo "🦀 Dark Lord Flutter Launcher 🚀"
echo "------------------------------------"

# 1. Пересобираем Rust (на случай если ты менял код)
echo "📦 [1/4] Building Rust for ARM64..."
cd rust
steam-run cargo build --target aarch64-linux-android --release
cd ..

# 2. Копируем свежий .so в папку Android
echo "📁 [2/4] Copying .so to jniLibs..."
mkdir -p android/app/src/main/jniLibs/arm64-v8a
cp rust/target/aarch64-linux-android/release/librust_lib_redmi_app.so \
	android/app/src/main/jniLibs/arm64-v8a/

# 4. Запускаем Flutter
echo "📱 [4/4] Launching on Redmi Note 12..."
steam-run flutter run -d 27ff7b9

echo "👑 Done. Welcome, Dark Lord."
