import 'dart:convert';

import 'package:calenlog/core/scrypt.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expected digests are transcribed from RFC 7914 §11 (vectors 1–3) and from
/// Python 3.14's `hashlib.scrypt` (vector 4, production parameters).
void main() {
  /// Convenience: hex string of the derived key.
  String hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  test('RFC 7914 vector 1: N=16, r=1, p=1', () {
    final derived = scryptSync(
      password: '',
      salt: const [],
      n: 16,
      r: 1,
      p: 1,
      keyLength: 64,
    );
    expect(
      hex(derived),
      '77d6576238657b203b19ca42c18a0497f16b4844e3074ae8dfdffa3fede21442'
      'fcd0069ded0948f8326a753a0fc81f17e8d3e0fb2e0d3628cf35e20c38d18906',
    );
  });

  test('RFC 7914 vector 2: N=1024, r=8, p=16', () {
    final derived = scryptSync(
      password: 'password',
      salt: ascii.encode('NaCl'),
      n: 1024,
      r: 8,
      p: 16,
      keyLength: 64,
    );
    expect(
      hex(derived),
      'fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b373162'
      '2eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640',
    );
  });

  test('RFC 7914 vector 3: N=16384, r=8, p=1 (production parameters)', () {
    final derived = scryptSync(
      password: 'pleaseletmein',
      salt: ascii.encode('SodiumChloride'),
      n: 16384,
      r: 8,
      p: 1,
      keyLength: 64,
    );
    expect(
      hex(derived),
      '7023bdcb3afd7348461c06cd81fd38ebfda8fbba904f8e3ea9b543f6545da1f2'
      'd5432955613f0fcf62d49705242a9af9e61e85dc0d651e40dfcf017b45575887',
    );
  });

  test('production parameters with a real password and salt', () {
    final derived = scryptSync(
      password: 'hunter2',
      salt: ascii.encode('0123456789abcdef'),
      n: 16384,
      r: 8,
      p: 1,
      keyLength: 64,
    );
    expect(
      hex(derived),
      'a84c7deddb70b3d9f7b8233a571e6e722a03466fd864c2fa2ff39ec82654646f'
      '370f6ef9c3de1aa945bdafcccecaab9f2e9d5f3ff99ab3748d70f0991fdabdf0',
    );
  });

  test('isolate version matches the synchronous one', () async {
    final salt = ascii.encode('salty-salt-16byt');
    final sync = scryptSync(
      password: 'correct horse',
      salt: salt,
      n: 16,
      r: 1,
      p: 1,
      keyLength: 64,
    );
    final async = await scryptAsync(
      password: 'correct horse',
      salt: salt,
      n: 16,
      r: 1,
      p: 1,
      keyLength: 64,
    );
    expect(hex(async), hex(sync));
  });

  test('rejects an N that is not a power of two', () {
    expect(
      () => scryptSync(
        password: 'x',
        salt: const [],
        n: 15,
        r: 1,
        p: 1,
        keyLength: 32,
      ),
      throwsArgumentError,
    );
  });

  test('derived key honours the requested length', () {
    final derived = scryptSync(
      password: 'x',
      salt: ascii.encode('salt'),
      n: 16,
      r: 1,
      p: 1,
      keyLength: 17,
    );
    expect(derived, hasLength(17));
  });
}
