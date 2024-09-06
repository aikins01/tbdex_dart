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

class JWTClaims {
  final String? issuer;
  final String? subject;
  final String? audience;
  final int? expiration;
  final int? notBefore;
  final int? issuedAt;
  final String? jwtID;
  final Map<String, dynamic>? miscellaneous;

  JWTClaims({
    this.issuer,
    this.subject,
    this.audience,
    this.expiration,
    this.notBefore,
    this.issuedAt,
    this.jwtID,
    this.miscellaneous,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> claims = {
      if (issuer != null) 'iss': issuer,
      if (subject != null) 'sub': subject,
      if (audience != null) 'aud': audience,
      if (expiration != null) 'exp': expiration,
      if (notBefore != null) 'nbf': notBefore,
      if (issuedAt != null) 'iat': issuedAt,
      if (jwtID != null) 'jti': jwtID,
    };

    if (miscellaneous != null) {
      claims.addAll(miscellaneous!);
    }

    return claims;
  }

  factory JWTClaims.fromJson(Map<String, dynamic> json) {
    final standardClaims = {'iss', 'sub', 'aud', 'exp', 'nbf', 'iat', 'jti'};
    final miscellaneous = Map<String, dynamic>.from(json)
      ..removeWhere((key, _) => standardClaims.contains(key));

    return JWTClaims(
      issuer: json['iss'],
      subject: json['sub'],
      audience: json['aud'],
      expiration: json['exp'],
      notBefore: json['nbf'],
      issuedAt: json['iat'],
      jwtID: json['jti'],
      miscellaneous: miscellaneous.isNotEmpty ? miscellaneous : null,
    );
  }
}
