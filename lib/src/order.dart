import 'package:typeid/typeid.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'message.dart';

class OrderData implements MessageData {
  // orderData is empty according to the tbdex specification
  OrderData();

  @override
  MessageKind kind() => MessageKind.order;

  @override
  Map<String, dynamic> toJson() => {};
}

typedef Order = Message<OrderData>;

extension OrderExtension on Order {
  static Order create({
    required String from,
    required String to,
    required String exchangeId,
    required ed.PrivateKey privateKey,
    String protocol = "1.0",
  }) {
    final id = TypeId.generate('order');
    final metadata = MessageMetadata(
      id: id,
      kind: MessageKind.order,
      from: from,
      to: to,
      exchangeId: exchangeId,
      createdAt: DateTime.now(),
      protocol: protocol,
    );

    final order = Order(metadata: metadata, data: OrderData());
    order.sign(privateKey);
    return order;
  }
}
