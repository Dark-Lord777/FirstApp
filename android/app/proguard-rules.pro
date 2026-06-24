# Оставляем в покое нативные методы Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Защита для работы с SQLite (твоя локальная база)
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

