#!/bin/bash
RES_DIR="android/app/src/release/res"
ASSETS_DIR="assets/bee_dynamic_launcher/icons"

if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
	echo "Env okey(Ubuntu)."
fi

# Проверка bc
if ! command -v bc &>/dev/null; then
	echo "Install bc (basic calculator)"
	apt-get update && apt-get install -y bc
fi

echo "PWD before: $(pwd)"
pwd
ls

# Создаем папки
mkdir -p "$RES_DIR/values/"
mkdir -p "$RES_DIR/mipmap-anydpi-v26/"
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
	mkdir -p android/app/src/release/res/mipmap-$d
done

clear
flutter pub get
dart run bee_dynamic_launcher

# Размеры иконок
declare -A SIZES
SIZES=(["mipmap-mdpi"]=48 ["mipmap-hdpi"]=72 ["mipmap-xhdpi"]=96 ["mipmap-xxhdpi"]=144 ["mipmap-xxxhdpi"]=192)

# ✅ УНИВЕРСАЛЬНАЯ ФУНКЦИЯ
resize_icon() {
	local src=$1
	local dest_name=$2

	for folder in "${!SIZES[@]}"; do
		local size=${SIZES[$folder]}
		local percent=0.9
		local inner_size=$(echo "$size * $percent" | bc | cut -d'.' -f1)

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

# ✅ АВТОМАТИЧЕСКИ НАХОДИМ ВСЕ ИКОНКИ
echo "📋 Searching for icons in $ASSETS_DIR..."

# Массив для хранения имен иконок
declare -a ICON_NAMES

# Находим все PNG файлы в папке иконок
for file in "$ASSETS_DIR"/*.png; do
	if [ -f "$file" ]; then
		# Получаем имя файла без расширения
		filename=$(basename "$file" .png)
		# Убираем префикс "ic_" если есть
		icon_name=${filename#ic_}
		# Добавляем в массив
		ICON_NAMES+=("$icon_name")
		echo "  Found: $icon_name"
	fi
done

echo "✅ Found ${#ICON_NAMES[@]} icons"

# ✅ ГЕНЕРИРУЕМ ИКОНКИ ДЛЯ КАЖДОГО НАЙДЕННОГО ВАРИАНТА
for icon_name in "${ICON_NAMES[@]}"; do
	src_file="$ASSETS_DIR/ic_${icon_name}.png"

	# Проверяем существует ли файл
	if [ -f "$src_file" ]; then
		echo "🔄 Processing: $icon_name"

		# Для default используем имя без суффикса
		if [ "$icon_name" = "default" ]; then
			resize_icon "$src_file" "ic_launcher.png"
			resize_icon "$src_file" "ic_launcher_${icon_name}.png"
		else
			resize_icon "$src_file" "ic_launcher_${icon_name}.png"
		fi
	else
		echo "⚠️ Warning: $src_file not found"
	fi
done

# 🎯 ОСОБЫЙ СЛУЧАЙ: если есть default, делаем основную иконку
if [ -f "$ASSETS_DIR/ic_default.png" ]; then
	echo "🔄 Creating main launcher icon from default"
	resize_icon "$ASSETS_DIR/ic_default.png" "ic_launcher.png"
fi

echo "Removing adaptive icons (mipmap-anydpi-v26)..."
rm -rf "$RES_DIR/mipmap-anydpi-v26/"
echo " Removed adaptive icons"

echo "✅ All done! Processed ${#ICON_NAMES[@]} icon variants"
echo "📁 Output directory: $RES_DIR"
ls -la "$RES_DIR" | grep mipmap
