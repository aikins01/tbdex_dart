import 'dart:convert';
import 'dart:typed_data';
import '../crypto/crypto.dart';

class JWT {
  static String sign(
      Map<String, dynamic> payload, Uint8List privateKey, String algorithm) {
    final header = {'alg': _getJWTAlgorithm(algorithm), 'typ': 'JWT'};

    final encodedHeader =
        base64Url.encode(utf8.encode(json.encode(header))).replaceAll('=', '');
    final encodedPayload =
        base64Url.encode(utf8.encode(json.encode(payload))).replaceAll('=', '');

    final signatureInput = '$encodedHeader.$encodedPayload';
    final signature =
        Crypto.sign(utf8.encode(signatureInput), privateKey, algorithm);
    final encodedSignature = base64Url.encode(signature).replaceAll('=', '');

    return '$encodedHeader.$encodedPayload.$encodedSignature';
  }

  static bool verify(String token, Uint8List publicKey, String algorithm) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return false;
    }

    final signatureInput = '${parts[0]}.${parts[1]}';
    final signature = base64Url.decode(base64Url.normalize(parts[2]));

    return Crypto.verify(
        utf8.encode(signatureInput), signature, publicKey, algorithm);
  }

  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid token');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final payloadString = utf8.decode(base64Url.decode(normalized));
    return json.decode(payloadString);
  }

  static String _getJWTAlgorithm(String algorithm) {
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
