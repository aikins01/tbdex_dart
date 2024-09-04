import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import '../utils/crypto_utils.dart';

enum ResourceKind {
  offering,
  balance,
}

abstract class ResourceData {
  ResourceKind kind();
  Map<String, dynamic> toJson();
}

class ResourceMetadata {
  final String id;
  final ResourceKind kind;
  final String from;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String protocol;

  ResourceMetadata({
    required this.id,
    required this.kind,
    required this.from,
    required this.createdAt,
    this.updatedAt,
    required this.protocol,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.toString().split('.').last,
        'from': from,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'protocol': protocol,
      };
}

class Resource<D extends ResourceData> {
  final ResourceMetadata metadata;
  final D data;
  String? signature;

  Resource({
    required this.metadata,
    required this.data,
    this.signature,
  });

  void sign(ed.PrivateKey privateKey) {
    final payload = CryptoUtils.getPayloadForSigning(metadata, data);
    final signatureBytes = ed.sign(privateKey, payload);
    this.signature = CryptoUtils.encodeSignature(signatureBytes);
  }

  bool verify(ed.PublicKey publicKey) {
    if (signature == null) return false;
    final payload = CryptoUtils.getPayloadForSigning(metadata, data);
    final signatureBytes = CryptoUtils.decodeSignature(signature!);
    return ed.verify(publicKey, payload, signatureBytes);
  }
}
