import 'dart:convert';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

enum MessageKind {
  rfq,
  cancel,
  close,
  quote,
  order,
  orderInstructions,
  orderStatus,
}

abstract class MessageData {
  MessageKind kind();
  Map<String, dynamic> toJson();
}

class MessageMetadata {
  final String id;
  final MessageKind kind;
  final String from;
  final String to;
  final String exchangeId;
  final DateTime createdAt;
  final String? externalId;
  final String protocol;

  MessageMetadata({
    required this.id,
    required this.kind,
    required this.from,
    required this.to,
    required this.exchangeId,
    required this.createdAt,
    this.externalId,
    required this.protocol,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.toString().split('.').last,
        'from': from,
        'to': to,
        'exchangeId': exchangeId,
        'createdAt': createdAt.toIso8601String(),
        if (externalId != null) 'externalId': externalId,
        'protocol': protocol,
      };
}

class Message<D extends MessageData> {
  final MessageMetadata metadata;
  final D data;
  String? signature;

  Message({
    required this.metadata,
    required this.data,
    this.signature,
  });

  void sign(ed.PrivateKey privateKey) {
    final payload = _getPayloadForSigning();
    final signatureBytes = ed.sign(privateKey, utf8.encode(payload));
    this.signature = base64Url.encode(signatureBytes);
  }

  bool verify(ed.PublicKey publicKey) {
    if (signature == null) return false;
    final payload = _getPayloadForSigning();
    final signatureBytes = base64Url.decode(signature!);
    return ed.verify(publicKey, utf8.encode(payload), signatureBytes);
  }

  String _getPayloadForSigning() {
    final Map<String, dynamic> payload = {
      'metadata': metadata.toJson(),
      'data': data.toJson(),
    };
    return json.encode(payload);
  }
}
