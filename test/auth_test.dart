import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/auth_provider.dart';

void main() {
  group('AuthProvider - hashPassword', () {
    test('returns SHA-256 hash', () {
      final hash = AuthProvider.hashPassword('password123');
      final expected = sha256.convert(utf8.encode('password123')).toString();
      expect(hash, expected);
    });

    test('different passwords produce different hashes', () {
      final h1 = AuthProvider.hashPassword('abc');
      final h2 = AuthProvider.hashPassword('def');
      expect(h1, isNot(equals(h2)));
    });

    test('same password always produces same hash', () {
      final h1 = AuthProvider.hashPassword('test');
      final h2 = AuthProvider.hashPassword('test');
      expect(h1, equals(h2));
    });

    test('hash is 64 hex chars (SHA-256)', () {
      final hash = AuthProvider.hashPassword('anything');
      expect(hash.length, 64);
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(hash), isTrue);
    });

    test('empty password still produces valid hash', () {
      final hash = AuthProvider.hashPassword('');
      expect(hash.length, 64);
    });
  });
}
