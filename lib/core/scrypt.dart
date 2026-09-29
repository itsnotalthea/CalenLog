/// Pure-Dart scrypt (RFC 7914); hand-rolled because no pub.dev package ships
/// one, and checked against the RFC §11 test vectors in `test/scrypt_test.dart`.
library;

import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const int _m = 0xFFFFFFFF;

/// Production parameters: N=16384, r=8, p=1, 64-byte derived key.
Future<Uint8List> scryptAsync({
  required String password,
  required List<int> salt,
  int n = 16384,
  int r = 8,
  int p = 1,
  int keyLength = 64,
}) => Isolate.run(
  () => scryptSync(
    password: password,
    salt: salt,
    n: n,
    r: r,
    p: p,
    keyLength: keyLength,
  ),
);

Uint8List scryptSync({
  required String password,
  required List<int> salt,
  int n = 16384,
  int r = 8,
  int p = 1,
  int keyLength = 64,
}) {
  _validate(n: n, r: r, p: p, keyLength: keyLength);

  final passwordBytes = utf8.encode(password);

  // 1. B = PBKDF2-HMAC-SHA256(P, S, 1, 128 * r * p)
  final b = _pbkdf2(passwordBytes, salt, 128 * r * p);

  // 2. ROMix each of the p independent 128*r-byte blocks in place.
  final blockWords = 32 * r;
  for (var i = 0; i < p; i++) {
    final words = Uint32List.view(b.buffer, i * 128 * r, blockWords);
    _romix(words, n, r);
  }

  // 3. DK = PBKDF2-HMAC-SHA256(P, B, 1, dkLen)
  return _pbkdf2(passwordBytes, b, keyLength);
}

void _validate({
  required int n,
  required int r,
  required int p,
  required int keyLength,
}) {
  if (n < 2 || (n & (n - 1)) != 0) {
    throw ArgumentError.value(n, 'n', 'must be a power of two greater than 1');
  }
  if (r < 1) {
    throw ArgumentError.value(r, 'r', 'must be >= 1');
  }
  if (p < 1) {
    throw ArgumentError.value(p, 'p', 'must be >= 1');
  }
  if (keyLength < 1) {
    throw ArgumentError.value(keyLength, 'keyLength', 'must be >= 1');
  }
}

Uint8List _pbkdf2(List<int> password, List<int> salt, int dkLen) {
  final mac = Hmac(sha256, password);
  final blocks = (dkLen + 31) ~/ 32;
  final out = Uint8List(blocks * 32);
  final counter = Uint8List(4);

  for (var i = 1; i <= blocks; i++) {
    counter[0] = (i >>> 24) & 0xFF;
    counter[1] = (i >>> 16) & 0xFF;
    counter[2] = (i >>> 8) & 0xFF;
    counter[3] = i & 0xFF;

    final input = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt)
      ..setRange(salt.length, salt.length + 4, counter);

    out.setRange((i - 1) * 32, i * 32, mac.convert(input).bytes);
  }
  return out.length == dkLen ? out : out.sublist(0, dkLen);
}

void _romix(Uint32List x, int n, int r) {
  final words = 32 * r;
  final v = Uint32List(n * words);
  final y = Uint32List(words);

  for (var i = 0; i < n; i++) {
    v.setRange(i * words, (i + 1) * words, x);
    _blockMix(x, y, r);
    x.setAll(0, y);
  }

  for (var i = 0; i < n; i++) {
    // Integerify: low 32 bits of the last block; n is a power of two, so the
    // mask is the modulus.
    final j = x[words - 16] & (n - 1);
    final offset = j * words;
    for (var k = 0; k < words; k++) {
      x[k] ^= v[offset + k];
    }
    _blockMix(x, y, r);
    x.setAll(0, y);
  }
}

void _blockMix(Uint32List src, Uint32List dst, int r) {
  final x = Uint32List(16);
  final lastBlock = (2 * r - 1) * 16;
  x.setRange(0, 16, src.sublist(lastBlock, lastBlock + 16));

  for (var i = 0; i < 2 * r; i++) {
    final inOffset = i * 16;
    for (var j = 0; j < 16; j++) {
      x[j] ^= src[inOffset + j];
    }
    _salsa20_8(x);

    final outOffset = (i.isEven ? i ~/ 2 : r + (i - 1) ~/ 2) * 16;
    dst.setRange(outOffset, outOffset + 16, x);
  }
}

int _rotl(int a, int b) => ((a << b) | (a >>> (32 - b))) & _m;

void _salsa20_8(Uint32List block) {
  final x = Uint32List.fromList(block);

  for (var round = 0; round < 4; round++) {
    x[4] ^= _rotl((x[0] + x[12]) & _m, 7);
    x[8] ^= _rotl((x[4] + x[0]) & _m, 9);
    x[12] ^= _rotl((x[8] + x[4]) & _m, 13);
    x[0] ^= _rotl((x[12] + x[8]) & _m, 18);

    x[9] ^= _rotl((x[5] + x[1]) & _m, 7);
    x[13] ^= _rotl((x[9] + x[5]) & _m, 9);
    x[1] ^= _rotl((x[13] + x[9]) & _m, 13);
    x[5] ^= _rotl((x[1] + x[13]) & _m, 18);

    x[14] ^= _rotl((x[10] + x[6]) & _m, 7);
    x[2] ^= _rotl((x[14] + x[10]) & _m, 9);
    x[6] ^= _rotl((x[2] + x[14]) & _m, 13);
    x[10] ^= _rotl((x[6] + x[2]) & _m, 18);

    x[3] ^= _rotl((x[15] + x[11]) & _m, 7);
    x[7] ^= _rotl((x[3] + x[15]) & _m, 9);
    x[11] ^= _rotl((x[7] + x[3]) & _m, 13);
    x[15] ^= _rotl((x[11] + x[7]) & _m, 18);

    x[1] ^= _rotl((x[0] + x[3]) & _m, 7);
    x[2] ^= _rotl((x[1] + x[0]) & _m, 9);
    x[3] ^= _rotl((x[2] + x[1]) & _m, 13);
    x[0] ^= _rotl((x[3] + x[2]) & _m, 18);

    x[6] ^= _rotl((x[5] + x[4]) & _m, 7);
    x[7] ^= _rotl((x[6] + x[5]) & _m, 9);
    x[4] ^= _rotl((x[7] + x[6]) & _m, 13);
    x[5] ^= _rotl((x[4] + x[7]) & _m, 18);

    x[11] ^= _rotl((x[10] + x[9]) & _m, 7);
    x[8] ^= _rotl((x[11] + x[10]) & _m, 9);
    x[9] ^= _rotl((x[8] + x[11]) & _m, 13);
    x[10] ^= _rotl((x[9] + x[8]) & _m, 18);

    x[12] ^= _rotl((x[15] + x[14]) & _m, 7);
    x[13] ^= _rotl((x[12] + x[15]) & _m, 9);
    x[14] ^= _rotl((x[13] + x[12]) & _m, 13);
    x[15] ^= _rotl((x[14] + x[13]) & _m, 18);
  }

  for (var i = 0; i < 16; i++) {
    block[i] = (block[i] + x[i]) & _m;
  }
}
