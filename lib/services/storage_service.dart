import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final int id;
  final String date;
  final String text;
  final String type;

  HistoryItem({
    required this.id,
    required this.date,
    required this.text,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'text': text,
    'type': type,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    id: json['id'],
    date: json['date'],
    text: json['text'],
    type: json['type'],
  );
}

class StorageService {
  static late SharedPreferences _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- HISTORY ---
  static const String _historyKey = 'history_data';

  static List<HistoryItem> getHistory() {
    final String? data = _prefs.getString(_historyKey);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => HistoryItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addHistoryItem(HistoryItem item) async {
    if (!getSettingBool('save_history', true)) return; // Check privacy setting
    
    final List<HistoryItem> current = getHistory();
    current.insert(0, item); // Add to the top
    
    final String encoded = jsonEncode(current.map((e) => e.toJson()).toList());
    await _prefs.setString(_historyKey, encoded);
  }

  static Future<void> deleteHistoryItem(int id) async {
    final List<HistoryItem> current = getHistory();
    current.removeWhere((item) => item.id == id);
    
    final String encoded = jsonEncode(current.map((e) => e.toJson()).toList());
    await _prefs.setString(_historyKey, encoded);
  }

  static Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  // --- SETTINGS ---
  static bool getSettingBool(String key, bool defaultValue) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> setSettingBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static String getSettingString(String key, String defaultValue) {
    return _prefs.getString(key) ?? defaultValue;
  }

  static Future<void> setSettingString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static double getFontSizeMultiplier() {
    String scale = getSettingString('font_size_scale', 'Mediano');
    if (scale == 'Pequeño') return 0.85;
    if (scale == 'Grande') return 1.35;
    return 1.0;
  }
}
