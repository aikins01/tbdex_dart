import 'package:typeid/typeid.dart';
import 'message.dart';

class CancelData implements MessageData {
  final String? reason;

  CancelData({this.reason});

  @override
  MessageKind kind() => MessageKind.cancel;

  @override
  Map<String, dynamic> toJson() => {
        if (reason != null) 'reason': reason,
      };
}

typedef Cancel = Message<CancelData>;

extension CancelExtension on Cancel {
  static Cancel create({
    required String from,
    required String to,
    required String exchangeId,
    String? reason,
    String protocol = "1.0",
  }) {
    final id = TypeId.generate('cancel');
    final metadata = MessageMetadata(
      id: id,
      kind: MessageKind.cancel,
      from: from,
      to: to,
      exchangeId: exchangeId,
      createdAt: DateTime.now(),
      protocol: protocol,
    );

    final data = CancelData(reason: reason);

    return Cancel(metadata: metadata, data: data);
  }
}
