part of '../property_builder_page.dart';

class SessionParamStore {
  static const _webPrefsKey = 'session_params_v1';

  static Map<String, dynamic> _deepMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), _deepValue(entry.value)),
        ),
      );
    }
    return <String, dynamic>{};
  }

  static dynamic _deepValue(dynamic value) {
    if (value is Map) return _deepMap(value);
    if (value is List) return value.map(_deepValue).toList();
    return value;
  }

  static Future<Map<String, dynamic>> _readStore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webPrefsKey);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return _deepMap(decoded);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  static Future<void> _writeStore(Map<String, dynamic> store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webPrefsKey, jsonEncode(store));
  }

  static List<Map<String, dynamic>> _rowsFromScope(
    Map<String, dynamic> store,
    String scopeId,
  ) {
    final raw = store[scopeId];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(
              row.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();
  }

  static Future<void> upsert(String scopeId, Map<String, dynamic> param) async {
    final store = await _readStore();
    final rows = _rowsFromScope(store, scopeId);
    final id = param['id']?.toString() ?? '';
    rows.removeWhere((row) => row['id']?.toString() == id);
    rows.add({
      'id': id,
      'scope_id': scopeId,
      'label': param['label']?.toString() ?? '',
      'type': param['type']?.toString() ?? '',
      'track_previous_capture':
          param['keep_previous_capture'] == true ? 1 : 0,
      'left_label': param['left_label']?.toString(),
      'right_label': param['right_label']?.toString(),
    });
    store[scopeId] = rows;
    await _writeStore(store);
  }

  static Future<void> upsertMany(
    String scopeId,
    List<Map<String, dynamic>> params,
  ) async {
    final store = await _readStore();
    final rows = _rowsFromScope(store, scopeId);
    final existingById = {
      for (final row in rows) row['id']?.toString() ?? '': row,
    };
    for (final param in params) {
      final id = param['id']?.toString() ?? '';
      existingById[id] = {
        'id': id,
        'scope_id': scopeId,
        'label': param['label']?.toString() ?? '',
        'type': param['type']?.toString() ?? '',
        'track_previous_capture':
            param['keep_previous_capture'] == true ? 1 : 0,
        'left_label': param['left_label']?.toString(),
        'right_label': param['right_label']?.toString(),
      };
    }
    store[scopeId] = existingById.values.toList();
    await _writeStore(store);
  }

  static Future<List<Map<String, dynamic>>> getAll(
      String scopeId, String excludeId) async {
    final store = await _readStore();
    return _rowsFromScope(store, scopeId)
        .where((row) => row['id']?.toString() != excludeId)
        .toList();
  }

  static Future<void> clearScope(String scopeId) async {
    final store = await _readStore();
    store.remove(scopeId);
    await _writeStore(store);
  }

  static Future<void> removeParam(String scopeId, String paramId) async {
    final store = await _readStore();
    final rows = _rowsFromScope(store, scopeId)
      ..removeWhere((row) => row['id']?.toString() == paramId);
    store[scopeId] = rows;
    await _writeStore(store);
  }
}
