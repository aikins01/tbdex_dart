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

  Future<bool> verify() async {
    // TODO: Implement verification logic
    throw UnimplementedError();
  }

  Future<void> sign() async {
    // TODO: Implement signing logic
    throw UnimplementedError();
  }
}
