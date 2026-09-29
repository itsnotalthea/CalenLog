import 'dart:convert';
import 'dart:typed_data';

import 'package:calenlog/core/constants.dart';
import 'package:calenlog/storage/auth_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fast stand-in for the KDF so these tests exercise the *storage and
/// verification* logic rather than the (deliberately slow) scrypt cost.
/// Produces a deterministic digest of the requested length.
Future<Uint8List> fastRunner(
  String password,
  List<int> salt,
  int n,
  int r,
  int p,
  int keyLength,
) async {
  final seed = '$password:${base64Encode(salt)}';
  final out = <int>[];
  var counter = 0;
  while (out.length < keyLength) {
    out.addAll(sha256.convert(utf8.encode('$seed:$counter')).bytes);
    counter++;
  }
  return Uint8List.fromList(out.sublist(0, keyLength));
}

void main() {
  late InMemorySecureStore store;
  late AuthRepository auth;

  setUp(() {
    store = InMemorySecureStore();
    auth = AuthRepository(store, runner: fastRunner);
  });

  group('first launch', () {
    test('reports that no password exists yet', () async {
      expect(await auth.hasPassword(), isFalse);
    });

    test(
      'setPassword stores a scrypt record with the expected shape',
      () async {
        await auth.setPassword('hunter2');

        final raw = await store.read(authDataKey);
        expect(raw, isNotNull);

        final json = jsonDecode(raw!) as Map<String, dynamic>;
        expect(json['n'], scryptN);
        expect(json['r'], scryptR);
        expect(json['p'], scryptP);
        expect(json['dkLen'], scryptKeyLength);
        expect(base64Decode(json['salt'] as String), hasLength(saltLength));
        expect(
          base64Decode(json['hash'] as String),
          hasLength(scryptKeyLength),
        );
        expect(await auth.hasPassword(), isTrue);
      },
    );

    test('two setPassword calls produce different salts', () async {
      await auth.setPassword('hunter2');
      final first =
          jsonDecode((await store.read(authDataKey))!) as Map<String, dynamic>;
      await auth.setPassword('hunter2');
      final second =
          jsonDecode((await store.read(authDataKey))!) as Map<String, dynamic>;

      expect(first['salt'], isNot(second['salt']));
      expect(first['hash'], isNot(second['hash']));
    });
  });

  group('verification', () {
    test('accepts the correct password', () async {
      await auth.setPassword('correct horse');
      expect(await auth.verify('correct horse'), isTrue);
    });

    test('rejects a wrong password', () async {
      await auth.setPassword('correct horse');
      expect(await auth.verify('correct horse '), isFalse);
      expect(await auth.verify(''), isFalse);
      expect(await auth.verify('Correct horse'), isFalse);
    });

    test('returns false when no password is stored', () async {
      expect(await auth.verify('anything'), isFalse);
    });

    test('returns false when the stored record is malformed', () async {
      await store.write(authDataKey, 'not json at all');
      expect(await auth.verify('anything'), isFalse);
    });

    test('returns false when a field is missing', () async {
      await store.write(authDataKey, '{"n":16384}');
      expect(await auth.verify('anything'), isFalse);
    });

    test('a changed password invalidates the old one', () async {
      await auth.setPassword('first-one');
      expect(await auth.verify('first-one'), isTrue);

      await auth.setPassword('second-one');
      expect(await auth.verify('first-one'), isFalse);
      expect(await auth.verify('second-one'), isTrue);
    });
  });

  group('reset', () {
    test('clear removes the stored password', () async {
      await auth.setPassword('hunter2');
      await auth.clear();
      expect(await auth.hasPassword(), isFalse);
      expect(await auth.verify('hunter2'), isFalse);
    });
  });
}
