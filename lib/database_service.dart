import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Сервис хранения данных через SharedPreferences (JSON).
/// Работает на всех платформах включая Web.
class DatabaseService {
  static Future<void> init() async {
    // SharedPreferences не требует явной инициализации
  }

  // ==================== USERS ====================

  static String _userKey(String login) =>
      'user_${login.trim().toLowerCase()}';

  static Future<UserModel?> getUserByLogin(String login) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_userKey(login));
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      return UserModel.fromMap(map);
    } catch (e) {
      debugPrint('getUserByLogin error: $e');
      return null;
    }
  }

  static Future<UserModel> insertUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final id = DateTime.now().millisecondsSinceEpoch;
    final userWithId = user.copyWith(id: id);
    await prefs.setString(
        _userKey(user.login), jsonEncode(userWithId.toMap()));
    return userWithId;
  }

  static Future<void> updateUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(user.login), jsonEncode(user.toMap()));
  }

  static Future<void> deleteUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith('user_')) continue;
      final json = prefs.getString(key);
      if (json == null) continue;
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        if (map['id'] == userId) {
          await prefs.remove(key);
          break;
        }
      } catch (_) {}
    }
    await prefs.remove('cars_$userId');
    await prefs.remove('fuel_records_$userId');
    await prefs.remove('maintenance_$userId');
  }

  static Future<List<CarModel>> getCars(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('cars_$userId');
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((m) => CarModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getCars error: $e');
      return [];
    }
  }

  static Future<CarModel> insertCar(CarModel car) async {
    final cars = await getCars(car.userId);
    int id = DateTime.now().millisecondsSinceEpoch;
    while (cars.any((c) => c.id == id)) {
      id++;
    }
    final carWithId = car.copyWith(id: id);
    cars.add(carWithId);
    await _saveCars(car.userId, cars);
    return carWithId;
  }

  static Future<void> updateCar(CarModel car) async {
    final cars = await getCars(car.userId);
    final index = cars.indexWhere((c) => c.id == car.id);
    if (index != -1) {
      cars[index] = car;
      await _saveCars(car.userId, cars);
    }
  }

  static Future<void> deleteCar(int carId, int userId) async {
    final cars = await getCars(userId);
    cars.removeWhere((c) => c.id == carId);
    await _saveCars(userId, cars);
  }

  static Future<void> _saveCars(int userId, List<CarModel> cars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cars_$userId',
      jsonEncode(cars.map((c) => c.toMap()).toList()),
    );
  }

  // ==================== FUEL RECORDS ====================

  static Future<List<FuelRecordModel>> getFuelRecords(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('fuel_records_$userId');
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((m) => FuelRecordModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getFuelRecords error: $e');
      return [];
    }
  }

  static Future<FuelRecordModel> insertFuelRecord(
      FuelRecordModel record) async {
    final records = await getFuelRecords(record.userId);
    int id = DateTime.now().millisecondsSinceEpoch;
    while (records.any((r) => r.id == id)) {
      id++;
    }
    final recordWithId = record.copyWith(id: id);
    records.insert(0, recordWithId);
    await _saveFuelRecords(record.userId, records);
    return recordWithId;
  }

  static Future<void> deleteFuelRecord(int recordId, int userId) async {
    final records = await getFuelRecords(userId);
    records.removeWhere((r) => r.id == recordId);
    await _saveFuelRecords(userId, records);
  }

  static Future<void> _saveFuelRecords(
      int userId, List<FuelRecordModel> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'fuel_records_$userId',
      jsonEncode(records.map((r) => r.toMap()).toList()),
    );
  }

  /// Удаляет все данные пользователя (машины + заправки + ТО).
  static Future<void> resetUserData(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cars_$userId');
    await prefs.remove('fuel_records_$userId');
    await prefs.remove('maintenance_$userId');
  }

  // ==================== MAINTENANCE ====================

  static Future<List<MaintenanceRecord>> getMaintenanceRecords(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('maintenance_$userId');
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((m) => MaintenanceRecord.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getMaintenanceRecords error: $e');
      return [];
    }
  }

  static Future<MaintenanceRecord> insertMaintenanceRecord(
      MaintenanceRecord record) async {
    final records = await getMaintenanceRecords(record.userId);
    int id = DateTime.now().millisecondsSinceEpoch;
    while (records.any((r) => r.id == id)) {
      id++;
    }
    final recordWithId = record.copyWith(id: id);
    records.insert(0, recordWithId);
    await _saveMaintenanceRecords(record.userId, records);
    return recordWithId;
  }

  static Future<void> deleteMaintenanceRecord(
      int recordId, int userId) async {
    final records = await getMaintenanceRecords(userId);
    records.removeWhere((r) => r.id == recordId);
    await _saveMaintenanceRecords(userId, records);
  }

  static Future<void> updateMaintenanceRecord(MaintenanceRecord record) async {
    final records = await getMaintenanceRecords(record.userId);
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await _saveMaintenanceRecords(record.userId, records);
    }
  }

  static Future<void> _saveMaintenanceRecords(
      int userId, List<MaintenanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'maintenance_$userId',
      jsonEncode(records.map((r) => r.toMap()).toList()),
    );
  }
}
