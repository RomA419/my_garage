import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/models.dart';

void main() {
  group('UserModel', () {
    test('toMap and fromMap roundtrip', () {
      final user = UserModel(
        id: 1,
        login: 'testuser',
        email: 'test@example.com',
        passwordHash: 'abc123hash',
        photoPath: '/path/photo.jpg',
        registeredAt: '2024-01-01T00:00:00.000',
        settings: {'currency': '₸', 'distanceUnit': 'km'},
      );

      final map = user.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, user.id);
      expect(restored.login, user.login);
      expect(restored.email, user.email);
      expect(restored.passwordHash, user.passwordHash);
      expect(restored.photoPath, user.photoPath);
      expect(restored.registeredAt, user.registeredAt);
      expect(restored.settings['currency'], '₸');
      expect(restored.settings['distanceUnit'], 'km');
    });

    test('copyWith updates only specified fields', () {
      final user = UserModel(
        id: 1,
        login: 'user1',
        email: 'old@mail.com',
        passwordHash: 'hash',
      );

      final updated = user.copyWith(email: 'new@mail.com');

      expect(updated.email, 'new@mail.com');
      expect(updated.login, 'user1');
      expect(updated.id, 1);
    });

    test('equality and hashCode', () {
      final a = UserModel(id: 1, login: 'user', email: '', passwordHash: '');
      final b = UserModel(id: 1, login: 'user', email: 'x@y.com', passwordHash: 'diff');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('fromMap handles missing optional fields', () {
      final user = UserModel.fromMap({
        'login': 'minimal',
        'password_hash': 'hash',
      });

      expect(user.login, 'minimal');
      expect(user.email, '');
      expect(user.photoPath, isNull);
      expect(user.settings, isEmpty);
    });
  });

  group('CarModel', () {
    test('toMap and fromMap roundtrip', () {
      final car = CarModel(
        id: 5,
        userId: 1,
        type: 'Седан',
        brand: 'Toyota',
        number: '123ABC',
        color: 0xFF4CAF50,
        typeIndex: 2,
      );

      final map = car.toMap();
      final restored = CarModel.fromMap(map);

      expect(restored.id, 5);
      expect(restored.userId, 1);
      expect(restored.type, 'Седан');
      expect(restored.brand, 'Toyota');
      expect(restored.number, '123ABC');
      expect(restored.color, 0xFF4CAF50);
      expect(restored.typeIndex, 2);
    });

    test('title getter with brand', () {
      final car = CarModel(
        userId: 1, type: 'Camry', brand: 'Toyota',
        number: '', color: 0, typeIndex: 0,
      );
      expect(car.title, 'Toyota Camry');
    });

    test('title getter without brand', () {
      final car = CarModel(
        userId: 1, type: 'Седан', brand: '',
        number: '', color: 0, typeIndex: 0,
      );
      expect(car.title, 'Седан');
    });

    test('toJson and fromJson for AddCarPage compat', () {
      final car = CarModel(
        userId: 1, type: 'SUV', brand: 'BMW',
        number: 'X5', color: 0xFF0000, typeIndex: 3,
      );

      final json = car.toJson();
      final restored = CarModel.fromJson(json, userId: 1, id: 10);

      expect(restored.type, 'SUV');
      expect(restored.brand, 'BMW');
      expect(restored.id, 10);
      expect(restored.userId, 1);
    });

    test('copyWith preserves original values', () {
      final car = CarModel(
        id: 1, userId: 1, type: 'A', brand: 'B',
        number: 'C', color: 100, typeIndex: 0,
      );

      final updated = car.copyWith(brand: 'New');
      expect(updated.brand, 'New');
      expect(updated.type, 'A');
      expect(updated.id, 1);
    });
  });

  group('FuelRecordModel', () {
    test('toMap and fromMap roundtrip', () {
      final record = FuelRecordModel(
        id: 10,
        userId: 1,
        carId: 5,
        date: '15.06.2024',
        timestamp: 1718400000000,
        station: 'Shell',
        carNumber: '123ABC',
        carTitle: 'Toyota Camry',
        odometer: '50000',
        category: 'Топливо',
        subType: 'АИ-95',
        quantity: '40.5',
        unit: 'л',
        total: '12352',
      );

      final map = record.toMap();
      final restored = FuelRecordModel.fromMap(map);

      expect(restored.id, 10);
      expect(restored.station, 'Shell');
      expect(restored.subType, 'АИ-95');
      expect(restored.quantity, '40.5');
      expect(restored.total, '12352');
      expect(restored.carTitle, 'Toyota Camry');
      expect(restored.odometer, '50000');
    });

    test('fromMap handles null optional fields', () {
      final record = FuelRecordModel.fromMap({
        'user_id': 1,
        'date': '01.01.2024',
        'timestamp': 1000,
        'station': 'Test',
        'category': 'Топливо',
        'sub_type': 'АИ-92',
        'quantity': '10',
        'unit': 'л',
        'total': '2350',
      });

      expect(record.carId, isNull);
      expect(record.odometer, isNull);
      expect(record.carNumber, '');
    });

    test('copyWith creates a new instance', () {
      final record = FuelRecordModel(
        userId: 1,
        date: '01.01.2024',
        timestamp: 1000,
        station: 'Old',
        category: 'Топливо',
        subType: 'АИ-92',
        quantity: '10',
        unit: 'л',
        total: '2000',
      );

      final updated = record.copyWith(station: 'New', total: '3000');
      expect(updated.station, 'New');
      expect(updated.total, '3000');
      expect(updated.date, '01.01.2024');
    });
  });
}
