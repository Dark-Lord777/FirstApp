#!/bin/bash
RES_DIR="android/app/src/main/res"
ASSETS_DIR="assets/bee_dynamic_launcher/icons"

if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
	echo "start a script into docker"
	echo "Use 'make build' if you don't have docker and"
	echo "Use 'make run'"
	exit 1
fi

echo "Env okey(Ubuntu). Check ImageMagick"
if ! command -v convert &>/dev/null; then
	echo "Install ImageMagick"
	apt-get update && apt-get install -y imagemagick

	if ! command -v convert &>/dev/null; then
		echo "Critical error. Exitting"
		exit 1
	fi
fi

# Проверка и установка bc
if ! command -v bc &>/dev/null; then
	echo "Install bc (basic calculator)"
	apt-get update && apt-get install -y bc

	if ! command -v bc &>/dev/null; then
		echo "Critical error. bc not installed"
		exit 1
	fi
fi

cd /workspace
clear
flutter pub get
dart run bee_dynamic_launcher

declare -A SIZES
SIZES=(["mipmap-mdpi"]=48 ["mipmap-hdpi"]=72 ["mipmap-xhdpi"]=96 ["mipmap-xxhdpi"]=144 ["mipmap-xxxhdpi"]=192)

resize_icon() {
	local src=$1
	local dest_name=$2

	for folder in "${!SIZES[@]}"; do
		local size=${SIZES[$folder]}

		# МЕНЯЙ ЗДЕСЬ ПРОЦЕНТ (сейчас 0.5 = 50%)
		local percent=0.5
		local inner_size=$(echo "$size * $percent" | bc | cut -d'.' -f1)

		# Защита от нуля
		if [ "$inner_size" -lt 1 ]; then
			inner_size=1
		fi

		convert "$src" \
			-resize "${inner_size}x${inner_size}" \
			-gravity center \
			-background "#2d2d2d" \
			-extent "${size}x${size}" \
			"$RES_DIR/$folder/$dest_name"

		echo "Created $dest_name for $folder (${size}x${size}, inner: ${inner_size}px)"
	done
}

resize_icon "$ASSETS_DIR/ic_777.png" "ic_launcher_777.png"
resize_icon "$ASSETS_DIR/ic_pink.png" "ic_launcher_pink.png"
resize_icon "$ASSETS_DIR/ic_default.png" "ic_launcher_default.png"
resize_icon "$ASSETS_DIR/ic_default.png" "ic_launcher.png"

echo "All done"
