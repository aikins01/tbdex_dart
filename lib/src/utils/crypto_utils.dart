import 'dart:convert';
import 'dart:typed_data';

class CryptoUtils {
  static Uint8List getPayloadForSigning(dynamic metadata, dynamic data) {
    final Map<String, dynamic> payload = {
      'metadata': metadata.toJson(),
      'data': data.toJson(),
    };
    return Uint8List.fromList(utf8.encode(json.encode(payload)));
  }

  static String encodeSignature(Uint8List signatureBytes) {
    return base64Url.encode(signatureBytes);
  }

  static Uint8List decodeSignature(String signature) {
    return base64Url.decode(signature);
  }
}
