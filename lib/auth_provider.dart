import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'models.dart';

/// Провайдер аутентификации.
///
/// Хранит текущего пользователя, обрабатывает логин/регистрацию/выход,
/// хеширует пароли с помощью SHA-256.
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get userId => _user?.id;

  /// SHA-256 хеширование пароля.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Попытка автологина по сохранённому логину.
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLogin = prefs.getString('last_user');
      if (lastLogin != null && lastLogin.isNotEmpty) {
        _user = await DatabaseService.getUserByLogin(lastLogin.trim().toLowerCase());
      }
    } catch (e) {
      debugPrint('Auto-login error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Вход по логину и паролю. Возвращает true при успехе.
  Future<bool> login(String login, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final normalizedLogin = login.trim().toLowerCase();
      final user = await DatabaseService.getUserByLogin(normalizedLogin);
      if (user == null) {
        _error = 'accountNotFound';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (user.passwordHash != hashPassword(password)) {
        _error = 'wrongPassword';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _user = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_user', normalizedLogin);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Регистрация нового пользователя.
  Future<bool> register(String login, String email, String password) async {
    _error = null;
    try {
      final existing = await DatabaseService.getUserByLogin(login.trim());
      if (existing != null) {
        _error = 'userExists';
        notifyListeners();
        return false;
      }
      final user = UserModel(
        login: login.trim().toLowerCase(),
        email: email.trim(),
        passwordHash: hashPassword(password),
        registeredAt: DateTime.now().toIso8601String(),
      );
      await DatabaseService.insertUser(user);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Обновление профиля (login, email, фото).
  Future<void> updateProfile({String? login, String? email, String? photoPath}) async {
    if (_user == null) return;
    try {
      _user = _user!.copyWith(
        login: login ?? _user!.login,
        email: email ?? _user!.email,
        photoPath: photoPath ?? _user!.photoPath,
      );
      await DatabaseService.updateUser(_user!);
      notifyListeners();
    } catch (e) {
      debugPrint('Update profile error: $e');
    }
  }

  /// Обновление настроек пользователя.
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (_user == null) return;
    try {
      _user = _user!.copyWith(settings: settings);
      await DatabaseService.updateUser(_user!);
      notifyListeners();
    } catch (e) {
      debugPrint('Update settings error: $e');
    }
  }

  /// Выход из аккаунта.
  Future<void> logout() async {
    _user = null;
    _error = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_user');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    notifyListeners();
  }

  /// Удаление аккаунта.
  Future<void> deleteAccount() async {
    if (_user == null) return;
    try {
      await DatabaseService.deleteUser(_user!.id!);
      await logout();
    } catch (e) {
      debugPrint('Delete account error: $e');
    }
  }
}
