import 'dart:convert';
import 'dart:typed_data';
import '../crypto/crypto.dart';

class JWS {
  static String sign(Uint8List payload, Uint8List privateKey, String algorithm,
      {Map<String, dynamic>? additionalHeaders}) {
    final header = {
      'alg': _getJWSAlgorithm(algorithm),
      'typ': 'JWS',
      ...?additionalHeaders,
    };

    final encodedHeader =
        base64Url.encode(utf8.encode(json.encode(header))).replaceAll('=', '');
    final encodedPayload = base64Url.encode(payload).replaceAll('=', '');

    final signatureInput = '$encodedHeader.$encodedPayload';
    final signature =
        Crypto.sign(utf8.encode(signatureInput), privateKey, algorithm);
    final encodedSignature = base64Url.encode(signature).replaceAll('=', '');

    return '$encodedHeader.$encodedPayload.$encodedSignature';
  }

  static bool verify(String token, Uint8List publicKey, String algorithm,
      {Uint8List? detachedPayload}) {
    final parts = token.split('.');
    if (parts.length != 3 && !(parts.length == 2 && detachedPayload != null)) {
      return false;
    }

    final encodedHeader = parts[0];
    final encodedPayload = parts.length == 3
        ? parts[1]
        : base64Url.encode(detachedPayload!).replaceAll('=', '');
    final encodedSignature = parts.length == 3 ? parts[2] : parts[1];

    final signatureInput = '$encodedHeader.$encodedPayload';
    final signature = base64Url.decode(base64Url.normalize(encodedSignature));

    return Crypto.verify(
        utf8.encode(signatureInput), signature, publicKey, algorithm);
  }

  static Map<String, dynamic> getHeader(String token) {
    final parts = token.split('.');
    if (parts.isEmpty) {
      throw const FormatException('Invalid token');
    }

    final headerJson =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
    return json.decode(headerJson);
  }

  static Uint8List getPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      throw const FormatException('Invalid token');
    }

    return base64Url.decode(base64Url.normalize(parts[1]));
  }

  static String _getJWSAlgorithm(String algorithm) {
    switch (algorithm) {
      case 'Ed25519':
        return 'EdDSA';
      case 'secp256k1':
        return 'ES256K';
      default:
        throw UnsupportedError('Unsupported algorithm: $algorithm');
    }
  }
}
