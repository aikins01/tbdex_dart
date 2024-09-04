import 'package:typeid/typeid.dart';
import 'message.dart';

class OrderData implements MessageData {
  // orderData is empty according to the tbdex specification

  @override
  MessageKind kind() => MessageKind.order;
}

typedef Order = Message<OrderData>;

extension OrderExtension on Order {
  static Order create({
    required String from,
    required String to,
    required String exchangeId,
    String protocol = "1.0",
  }) {
    final metadata = MessageMetadata(
      id: TypeId.generate('order'),
      kind: MessageKind.order,
      from: from,
      to: to,
      exchangeId: exchangeId,
      createdAt: DateTime.now(),
      protocol: protocol,
    );

    return Order(metadata: metadata, data: OrderData());
  }
}
