import 'package:typeid/typeid.dart';
import 'message.dart';

class OrderInstructionsData implements MessageData {
  final PaymentInstruction payin;
  final PaymentInstruction payout;

  OrderInstructionsData({
    required this.payin,
    required this.payout,
  });

  @override
  MessageKind kind() => MessageKind.orderInstructions;

  @override
  Map<String, dynamic> toJson() => {
        'payin': payin.toJson(),
        'payout': payout.toJson(),
      };
}

class PaymentInstruction {
  final String? link;
  final String? instruction;

  PaymentInstruction({this.link, this.instruction});

  Map<String, dynamic> toJson() => {
        if (link != null) 'link': link,
        if (instruction != null) 'instruction': instruction,
      };
}

typedef OrderInstructions = Message<OrderInstructionsData>;

extension OrderInstructionsExtension on OrderInstructions {
  static OrderInstructions create({
    required String from,
    required String to,
    required String exchangeId,
    required PaymentInstruction payin,
    required PaymentInstruction payout,
    String protocol = "1.0",
  }) {
    final id = TypeId.generate('orderinstructions');
    final metadata = MessageMetadata(
      id: id,
      kind: MessageKind.orderInstructions,
      from: from,
      to: to,
      exchangeId: exchangeId,
      createdAt: DateTime.now(),
      protocol: protocol,
    );

    final data = OrderInstructionsData(payin: payin, payout: payout);

    return OrderInstructions(metadata: metadata, data: data);
  }
}
