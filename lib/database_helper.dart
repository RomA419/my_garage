import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static const String _lastUserKey = 'last_user';

  // Сохранение
  static Future<void> saveUser(String login, Map<String, dynamic> userData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = login.trim().toLowerCase(); // Приводим к одному регистру
    await prefs.setString(key, jsonEncode(userData));
  }

  // Загрузка
  static Future<Map<String, dynamic>?> getUser(String login) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = login.trim().toLowerCase();
    String? data = prefs.getString(key);

    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Последний вошедший пользователь (для автологина)
  static Future<void> setLastLogin(String login) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserKey, login.trim().toLowerCase());
  }

  static Future<String?> getLastLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUserKey);
  }

  static Future<void> clearLastLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserKey);
  }

  static Future<Map<String, dynamic>?> getLastUser() async {
    final login = await getLastLogin();
    if (login == null || login.isEmpty) return null;
    return getUser(login);
  }
}
