import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class Jwk {
  final String kty;
  final String crv;
  final String x;
  final String? y;
  final String? d;

  Jwk({
    required this.kty,
    required this.crv,
    required this.x,
    this.y,
    this.d,
  });

  factory Jwk.fromPublicKey(Uint8List publicKey, String algorithm) {
    switch (algorithm) {
      case 'Ed25519':
        return Jwk(
          kty: 'OKP',
          crv: 'Ed25519',
          x: base64Url.encode(publicKey),
        );
      case 'secp256k1':
        final point = ECCurve_secp256k1().curve.decodePoint(publicKey)!;
        return Jwk(
          kty: 'EC',
          crv: 'secp256k1',
          x: base64Url.encode(_bigIntToBytes(point.x!.toBigInteger()!, 32)),
          y: base64Url.encode(_bigIntToBytes(point.y!.toBigInteger()!, 32)),
        );
      default:
        throw UnsupportedError('Unsupported algorithm: $algorithm');
    }
  }

  static Uint8List _bigIntToBytes(BigInt bigInt, int length) {
    var bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[length - i - 1] = (bigInt & BigInt.from(0xff)).toInt();
      bigInt = bigInt >> 8;
    }
    return bytes;
  }

  Map<String, dynamic> toJson() {
    final map = {
      'kty': kty,
      'crv': crv,
      'x': x,
    };
    if (y != null) map['y'] = y!;
    if (d != null) map['d'] = d!;
    return map;
  }

  Future<String> thumbprint() async {
    final json = toJson();
    final requiredFields = ['crv', 'kty', 'x', 'y'];
    final sortedParams = Map.fromEntries(
      requiredFields
          .where((field) => json.containsKey(field))
          .map((field) => MapEntry(field, json[field])),
    );
    final jsonString = jsonEncode(sortedParams);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
