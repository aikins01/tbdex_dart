import 'package:typeid/typeid.dart';
import 'message.dart';

class CloseData implements MessageData {
  final String? reason;
  final bool? success;

  CloseData({this.reason, this.success});

  @override
  MessageKind kind() => MessageKind.close;

  @override
  Map<String, dynamic> toJson() => {
        if (reason != null) 'reason': reason,
        if (success != null) 'success': success,
      };
}

typedef Close = Message<CloseData>;

extension CloseExtension on Close {
  static Close create({
    required String from,
    required String to,
    required String exchangeId,
    String? reason,
    bool? success,
    String protocol = "1.0",
  }) {
    final id = TypeId.generate('close');
    final metadata = MessageMetadata(
      id: id,
      kind: MessageKind.close,
      from: from,
      to: to,
      exchangeId: exchangeId,
      createdAt: DateTime.now(),
      protocol: protocol,
    );

    final data = CloseData(reason: reason, success: success);

    return Close(metadata: metadata, data: data);
  }
}
