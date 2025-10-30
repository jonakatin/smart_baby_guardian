import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reading.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _boxName = 'readings_box';

  late Box<Reading> _box;

  ValueListenable<Box<Reading>> get listenable => _box.listenable();

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(ReadingAdapter().typeId)) {
      Hive.registerAdapter(ReadingAdapter());
    }
    _box = await Hive.openBox<Reading>(_boxName);
  }

  Future<void> addReading(Reading reading) async {
    await _box.add(reading);
  }

  List<Reading> getReadings() {
    final items = _box.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
