/// scrypt hash + salt, encrypted at rest by Windows DPAPI / macOS Keychain.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';
import '../core/scrypt.dart';

const String authDataKey = 'authData';

/// KDF signature, injectable so tests can run a fast implementation.
typedef ScryptRunner =
    Future<Uint8List> Function(
      String password,
      List<int> salt,
      int n,
      int r,
      int p,
      int keyLength,
    );

/// Default runner: scrypt in a background isolate.
Future<Uint8List> _isolateRunner(
  String password,
  List<int> salt,
  int n,
  int r,
  int p,
  int keyLength,
) => scryptAsync(
  password: password,
  salt: salt,
  n: n,
  r: r,
  p: p,
  keyLength: keyLength,
);

/// Abstraction over the platform credential store, so auth logic is testable.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Production store backed by `flutter_secure_storage` (DPAPI / Keychain).
class PlatformSecureStore implements SecureStore {
  const PlatformSecureStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

class AuthRepository {
  AuthRepository(this._store, {ScryptRunner runner = _isolateRunner})
    : _runner = runner;

  final SecureStore _store;
  final ScryptRunner _runner;

  Future<bool> hasPassword() async => await _store.read(authDataKey) != null;

  Future<void> setPassword(String password) async {
    final salt = _randomBytes(saltLength);
    final hash = await _runner(
      password,
      salt,
      scryptN,
      scryptR,
      scryptP,
      scryptKeyLength,
    );
    await _store.write(
      authDataKey,
      jsonEncode({
        'hash': base64Encode(hash),
        'salt': base64Encode(salt),
        'n': scryptN,
        'r': scryptR,
        'p': scryptP,
        'dkLen': scryptKeyLength,
      }),
    );
  }

  /// Returns false, rather than throwing, when no password exists or the
  /// stored record is malformed.
  Future<bool> verify(String password) async {
    final raw = await _store.read(authDataKey);
    if (raw == null) return false;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final salt = base64Decode(json['salt'] as String);
      final expected = base64Decode(json['hash'] as String);
      final actual = await _runner(
        password,
        salt,
        (json['n'] as num?)?.toInt() ?? scryptN,
        (json['r'] as num?)?.toInt() ?? scryptR,
        (json['p'] as num?)?.toInt() ?? scryptP,
        (json['dkLen'] as num?)?.toInt() ?? scryptKeyLength,
      );
      return _constantTimeEquals(expected, actual);
    } catch (_) {
      return false;
    }
  }

  /// Removes the stored password ("Reset All Data").
  Future<void> clear() => _store.delete(authDataKey);

  static Uint8List _randomBytes(int count) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(count, (_) => random.nextInt(256)),
    );
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
