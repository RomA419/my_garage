import 'dart:convert';

/// Модель пользователя
class UserModel {
  final int? id;
  final String login;
  final String email;
  final String passwordHash;
  final String? photoPath;
  final String? registeredAt;
  final Map<String, dynamic> settings;

  const UserModel({
    this.id,
    required this.login,
    required this.email,
    required this.passwordHash,
    this.photoPath,
    this.registeredAt,
    this.settings = const {},
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'login': login,
        'email': email,
        'password_hash': passwordHash,
        'photo_path': photoPath,
        'registered_at': registeredAt,
        'settings_json': jsonEncode(settings),
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] as int?,
        login: m['login'] as String? ?? '',
        email: m['email'] as String? ?? '',
        passwordHash: m['password_hash'] as String? ?? '',
        photoPath: m['photo_path'] as String?,
        registeredAt: m['registered_at'] as String?,
        settings: m['settings_json'] != null
            ? (jsonDecode(m['settings_json'] as String)
                    as Map<String, dynamic>?) ??
                {}
            : {},
      );

  UserModel copyWith({
    int? id,
    String? login,
    String? email,
    String? passwordHash,
    String? photoPath,
    String? registeredAt,
    Map<String, dynamic>? settings,
  }) =>
      UserModel(
        id: id ?? this.id,
        login: login ?? this.login,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        photoPath: photoPath ?? this.photoPath,
        registeredAt: registeredAt ?? this.registeredAt,
        settings: settings ?? this.settings,
      );

  @override
  String toString() => 'UserModel(id: $id, login: $login, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserModel && other.id == id && other.login == login);

  @override
  int get hashCode => Object.hash(id, login);
}

/// Модель автомобиля
class CarModel {
  final int? id;
  final int userId;
  final String type;
  final String brand;
  final String number;
  final int color;
  final int typeIndex;

  const CarModel({
    this.id,
    required this.userId,
    required this.type,
    required this.brand,
    required this.number,
    required this.color,
    required this.typeIndex,
  });

  String get title => brand.isNotEmpty ? '$brand $type' : type;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'brand': brand,
        'number': number,
        'color': color,
        'type_index': typeIndex,
      };

  factory CarModel.fromMap(Map<String, dynamic> m) => CarModel(
        id: m['id'] as int?,
        userId: m['user_id'] as int? ?? 0,
        type: m['type'] as String? ?? '',
        brand: m['brand'] as String? ?? '',
        number: m['number'] as String? ?? '',
        color: m['color'] as int? ?? 0xFF4CAF50,
        typeIndex: m['type_index'] as int? ?? 0,
      );

  CarModel copyWith({
    int? id,
    int? userId,
    String? type,
    String? brand,
    String? number,
    int? color,
    int? typeIndex,
  }) =>
      CarModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        brand: brand ?? this.brand,
        number: number ?? this.number,
        color: color ?? this.color,
        typeIndex: typeIndex ?? this.typeIndex,
      );

  /// Для совместимости с AddCarPage (Map формат)
  Map<String, dynamic> toJson() => {
        'type': type,
        'brand': brand,
        'number': number,
        'color': color,
        'typeIndex': typeIndex,
      };

  factory CarModel.fromJson(Map<String, dynamic> m, {required int userId, int? id}) =>
      CarModel(
        id: id,
        userId: userId,
        type: m['type'] as String? ?? '',
        brand: m['brand'] as String? ?? '',
        number: m['number'] as String? ?? '',
        color: m['color'] as int? ?? 0xFF4CAF50,
        typeIndex: m['typeIndex'] as int? ?? 0,
      );

  @override
  String toString() => 'CarModel(id: $id, $title, $number)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CarModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Модель записи о заправке / услуге
class FuelRecordModel {
  final int? id;
  final int userId;
  final int? carId;
  final String date;
  final int timestamp;
  final String station;
  final String carNumber;
  final String carTitle;
  final String? odometer;
  final String category;
  final String subType;
  final String quantity;
  final String unit;
  final String total;

  const FuelRecordModel({
    this.id,
    required this.userId,
    this.carId,
    required this.date,
    required this.timestamp,
    required this.station,
    this.carNumber = '',
    this.carTitle = '',
    this.odometer,
    required this.category,
    required this.subType,
    required this.quantity,
    required this.unit,
    required this.total,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'car_id': carId,
        'date': date,
        'timestamp': timestamp,
        'station': station,
        'car_number': carNumber,
        'car_title': carTitle,
        'odometer': odometer,
        'category': category,
        'sub_type': subType,
        'quantity': quantity,
        'unit': unit,
        'total': total,
      };

  factory FuelRecordModel.fromMap(Map<String, dynamic> m) => FuelRecordModel(
        id: m['id'] as int?,
        userId: m['user_id'] as int? ?? 0,
        carId: m['car_id'] as int?,
        date: m['date'] as String? ?? '',
        timestamp: m['timestamp'] as int? ?? 0,
        station: m['station'] as String? ?? '',
        carNumber: m['car_number'] as String? ?? '',
        carTitle: m['car_title'] as String? ?? '',
        odometer: m['odometer'] as String?,
        category: m['category'] as String? ?? '',
        subType: m['sub_type'] as String? ?? '',
        quantity: m['quantity'] as String? ?? '0',
        unit: m['unit'] as String? ?? '',
        total: m['total'] as String? ?? '0',
      );

  FuelRecordModel copyWith({
    int? id,
    int? userId,
    int? carId,
    String? date,
    int? timestamp,
    String? station,
    String? carNumber,
    String? carTitle,
    String? odometer,
    String? category,
    String? subType,
    String? quantity,
    String? unit,
    String? total,
  }) =>
      FuelRecordModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        carId: carId ?? this.carId,
        date: date ?? this.date,
        timestamp: timestamp ?? this.timestamp,
        station: station ?? this.station,
        carNumber: carNumber ?? this.carNumber,
        carTitle: carTitle ?? this.carTitle,
        odometer: odometer ?? this.odometer,
        category: category ?? this.category,
        subType: subType ?? this.subType,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        total: total ?? this.total,
      );

  @override
  String toString() =>
      'FuelRecordModel(id: $id, $station, $subType, $total ₸)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelRecordModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Модель записи журнала ТО
class MaintenanceRecord {
  final int? id;
  final int userId;
  final int? carId;
  final String carTitle;
  final String carNumber;
  final String type;
  final String date;
  final int timestamp;
  final String cost;
  final String odometer;
  final String notes;

  const MaintenanceRecord({
    this.id,
    required this.userId,
    this.carId,
    this.carTitle = '',
    this.carNumber = '',
    required this.type,
    required this.date,
    required this.timestamp,
    this.cost = '0',
    this.odometer = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'car_id': carId,
        'car_title': carTitle,
        'car_number': carNumber,
        'type': type,
        'date': date,
        'timestamp': timestamp,
        'cost': cost,
        'odometer': odometer,
        'notes': notes,
      };

  factory MaintenanceRecord.fromMap(Map<String, dynamic> m) => MaintenanceRecord(
        id: m['id'] as int?,
        userId: m['user_id'] as int? ?? 0,
        carId: m['car_id'] as int?,
        carTitle: m['car_title'] as String? ?? '',
        carNumber: m['car_number'] as String? ?? '',
        type: m['type'] as String? ?? '',
        date: m['date'] as String? ?? '',
        timestamp: m['timestamp'] as int? ?? 0,
        cost: m['cost'] as String? ?? '0',
        odometer: m['odometer'] as String? ?? '',
        notes: m['notes'] as String? ?? '',
      );

  MaintenanceRecord copyWith({
    int? id,
    int? userId,
    int? carId,
    String? carTitle,
    String? carNumber,
    String? type,
    String? date,
    int? timestamp,
    String? cost,
    String? odometer,
    String? notes,
  }) =>
      MaintenanceRecord(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        carId: carId ?? this.carId,
        carTitle: carTitle ?? this.carTitle,
        carNumber: carNumber ?? this.carNumber,
        type: type ?? this.type,
        date: date ?? this.date,
        timestamp: timestamp ?? this.timestamp,
        cost: cost ?? this.cost,
        odometer: odometer ?? this.odometer,
        notes: notes ?? this.notes,
      );

  @override
  String toString() => 'MaintenanceRecord(id: $id, $type, $date)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MaintenanceRecord && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
