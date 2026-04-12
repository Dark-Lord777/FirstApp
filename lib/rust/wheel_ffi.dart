import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Загрузка библиотеки
final DynamicLibrary rust = Platform.isAndroid
    ? DynamicLibrary.open("librust_lib_redmi_app.so")
    : DynamicLibrary.process();

// --- Базовые функции (уже были) ---
final void Function() wheelReset =
    rust.lookupFunction<Void Function(), void Function()>("wheel_reset");

final void Function() wheelSpin =
    rust.lookupFunction<Void Function(), void Function()>("wheel_spin");

final void Function() wheelUpdate =
    rust.lookupFunction<Void Function(), void Function()>("wheel_update");

final double Function() wheelGetRotation =
    rust.lookupFunction<Float Function(), double Function()>("wheel_get_rotation");

// --- НОВЫЕ функции для секторов ---
final int Function() wheelGetSectorCount =
    rust.lookupFunction<Int32 Function(), int Function()>("wheel_get_sector_count");

final Pointer<Utf8> Function(int) wheelGetSectorName =
    rust.lookupFunction<Pointer<Utf8> Function(Int32), Pointer<Utf8> Function(int)>("wheel_get_sector_name");

final void Function(Pointer<Utf8>) wheelAddSector =
    rust.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>("wheel_add_sector");

// --- Вспомогательные Dart-функции ---
String? getSectorName(int index) {
  final ptr = wheelGetSectorName(index);
  if (ptr == nullptr) return null;
  final name = ptr.toDartString();
  calloc.free(ptr); // ВАЖНО: освобождаем память
  return name;
}

List<String> getAllSectors() {
  final count = wheelGetSectorCount();
  return List.generate(count, (i) => getSectorName(i) ?? '');
}

void addSector(String name) {
  final ptr = name.toNativeUtf8();
  wheelAddSector(ptr);
  calloc.free(ptr);
}
