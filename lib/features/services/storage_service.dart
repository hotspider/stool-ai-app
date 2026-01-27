import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/record.dart';
import 'analyzer/engine_config.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();
  static const String boxName = 'records';
  static const String prefsBoxName = 'prefs';
  static const String analyzerModeKey = 'analyzer_mode';

  late Box<String> _box;
  late Box _prefsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    instance._box = await Hive.openBox<String>(boxName);
    instance._prefsBox = await Hive.openBox(prefsBoxName);
    await instance._migrateLegacyRecords();
  }

  ValueListenable<Box<String>> listenable() => _box.listenable();
  ValueListenable<Box> prefsListenable() => _prefsBox.listenable();

  AnalyzerMode getAnalyzerMode() {
    final raw = _prefsBox.get(analyzerModeKey) as String?;
    return EngineConfig.fromString(raw);
  }

  Future<void> setAnalyzerMode(AnalyzerMode mode) async {
    await _prefsBox.put(analyzerModeKey, EngineConfig.toStringValue(mode));
  }

  List<StoolRecord> getAllRecords() {
    final records = <StoolRecord>[];
    for (final value in _box.values) {
      try {
        records.add(
          StoolRecord.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } catch (_) {
        // Skip corrupted entries.
      }
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  StoolRecord? getRecord(String id) {
    final value = _box.get(id);
    if (value == null) {
      return null;
    }
    try {
      return StoolRecord.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRecord(StoolRecord record) async {
    await _box.put(record.id, jsonEncode(record.toJson()));
  }

  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> _migrateLegacyRecords() async {
    final keys = _box.keys.toList();
    for (final key in keys) {
      final raw = _box.get(key);
      if (raw == null) {
        continue;
      }
      try {
        final json = jsonDecode(raw);
        if (json is! Map<String, dynamic>) {
          continue;
        }
        if (json['schemaVersion'] == 1) {
          continue;
        }
        final record = StoolRecord.fromJson(json);
        await _box.put(record.id, jsonEncode(record.toJson()));
      } catch (_) {
        // Ignore corrupted legacy data to avoid crashing on startup.
      }
    }
  }
}
