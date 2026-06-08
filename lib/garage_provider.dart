import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'models.dart';

/// Провайдер гаража.
///
/// Управляет списком машин и записями о заправках.
/// Использует SQLite через [DatabaseService].
class GarageProvider extends ChangeNotifier {
  List<CarModel> _cars = [];
  List<FuelRecordModel> _fuelRecords = [];
  List<MaintenanceRecord> _maintenanceRecords = [];
  int _currentCarIndex = 0;
  bool _isLoading = false;
  int? _userId;

  List<CarModel> get cars => List.unmodifiable(_cars);
  List<FuelRecordModel> get fuelRecords => List.unmodifiable(_fuelRecords);
  List<MaintenanceRecord> get maintenanceRecords => List.unmodifiable(_maintenanceRecords);
  int get currentCarIndex => _currentCarIndex;
  bool get isLoading => _isLoading;
  bool get hasCars => _cars.isNotEmpty;
  int? get userId => _userId;

  CarModel? get currentCar => _cars.isNotEmpty
      ? _cars[_currentCarIndex.clamp(0, _cars.length - 1)]
      : null;

  /// Записи текущего автомобиля.
  List<FuelRecordModel> get currentCarRecords {
    final car = currentCar;
    if (car == null || car.number.isEmpty) return _fuelRecords;
    return _fuelRecords.where((r) => r.carNumber == car.number).toList();
  }

  /// Сумма расходов за текущий месяц.
  double get monthlyExpenses {
    final now = DateTime.now();
    double total = 0;
    for (final r in _fuelRecords) {
      final d = DateTime.fromMillisecondsSinceEpoch(r.timestamp);
      if (d.year == now.year && d.month == now.month) {
        total += double.tryParse(r.total) ?? 0;
      }
    }
    return total;
  }

  /// Дата последней заправки.
  String get lastRefuelDate {
    if (_fuelRecords.isEmpty) return '-';
    return _fuelRecords.first.date;
  }

  // ================= Загрузка =================

  Future<void> loadData(int userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();
    try {
      _cars = await DatabaseService.getCars(userId);
      _fuelRecords = await DatabaseService.getFuelRecords(userId);
      _maintenanceRecords = await DatabaseService.getMaintenanceRecords(userId);
      if (_currentCarIndex >= _cars.length) _currentCarIndex = 0;
    } catch (e) {
      debugPrint('Load data error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ================= Машины =================

  void selectCar(int index) {
    _currentCarIndex = index.clamp(0, _cars.isEmpty ? 0 : _cars.length - 1);
    notifyListeners();
  }

  Future<void> addCar(CarModel car) async {
    try {
      final saved = await DatabaseService.insertCar(car);
      _cars.add(saved);
      _currentCarIndex = _cars.length - 1;
      notifyListeners();
    } catch (e) {
      debugPrint('Add car error: $e');
    }
  }

  Future<void> updateCar(CarModel car) async {
    try {
      await DatabaseService.updateCar(car);
      final index = _cars.indexWhere((c) => c.id == car.id);
      if (index != -1) {
        _cars[index] = car;
        _currentCarIndex = index;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update car error: $e');
    }
  }

  Future<void> deleteCar(int carId) async {
    try {
      await DatabaseService.deleteCar(carId, _userId!);
      _cars.removeWhere((c) => c.id == carId);
      if (_currentCarIndex >= _cars.length) {
        _currentCarIndex = _cars.isEmpty ? 0 : _cars.length - 1;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Delete car error: $e');
    }
  }

  // ================= Заправки =================

  Future<void> addFuelRecord(FuelRecordModel record) async {
    try {
      final saved = await DatabaseService.insertFuelRecord(record);
      _fuelRecords.insert(0, saved);
      notifyListeners();
    } catch (e) {
      debugPrint('Add fuel record error: $e');
    }
  }

  Future<void> deleteFuelRecord(int recordId) async {
    try {
      await DatabaseService.deleteFuelRecord(recordId, _userId!);
      _fuelRecords.removeWhere((r) => r.id == recordId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete fuel record error: $e');
    }
  }

  /// Восстановление удалённой записи (undo).
  Future<void> undoDeleteFuelRecord(FuelRecordModel record) async {
    try {
      final saved = await DatabaseService.insertFuelRecord(record);
      _fuelRecords.insert(0, saved);
      _fuelRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      debugPrint('Undo delete error: $e');
    }
  }

  /// Сброс всех данных пользователя.
  Future<void> resetData() async {
    if (_userId == null) return;
    try {
      await DatabaseService.resetUserData(_userId!);
      _cars.clear();
      _fuelRecords.clear();
      _maintenanceRecords.clear();
      _currentCarIndex = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Reset data error: $e');
    }
  }

  /// Очистка при выходе.
  void clear() {
    _cars.clear();
    _fuelRecords.clear();
    _maintenanceRecords.clear();
    _currentCarIndex = 0;
    _userId = null;
    notifyListeners();
  }

  // ================= Журнал ТО =================

  Future<void> addMaintenanceRecord(MaintenanceRecord record) async {
    try {
      final saved = await DatabaseService.insertMaintenanceRecord(record);
      _maintenanceRecords.insert(0, saved);
      notifyListeners();
    } catch (e) {
      debugPrint('Add maintenance error: $e');
    }
  }

  Future<void> deleteMaintenanceRecord(int recordId) async {
    try {
      await DatabaseService.deleteMaintenanceRecord(recordId, _userId!);
      _maintenanceRecords.removeWhere((r) => r.id == recordId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete maintenance error: $e');
    }
  }

  Future<void> updateMaintenanceRecord(MaintenanceRecord record) async {
    try {
      await DatabaseService.updateMaintenanceRecord(record);
      final index = _maintenanceRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _maintenanceRecords[index] = record;
        _maintenanceRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update maintenance error: $e');
    }
  }
}
